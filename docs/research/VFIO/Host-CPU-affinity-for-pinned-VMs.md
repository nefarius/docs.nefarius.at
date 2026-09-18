# Host CPU affinity for pinned VMs

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
systemd | 255
libvirt | 10.0.0

Related:

- [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md)
- [CPU governor for pinned KVM vCPUs](./CPU-governor-for-pinned-vCPUs.md)

## Problem

`<cputune>` only pins QEMU's vCPU threads. Everything else on the host (desktop session, browsers, Docker, `libvirtd` itself) can still run on those same host CPUs.

`isolcpus=` removes those CPUs from the general scheduler. It works, but it is a kernel cmdline change, needs a reboot, and can hurt host latency if you guessed wrong. The 2024 notes left it as an experiment.

On a cgroup v2 host, systemd slices are a milder way to get the same split.

## Approach

libvirt places QEMU in `machine.slice` (`machine-qemu-*.scope`). Keep that slice on every CPU so `<vcpupin>` can still target the guest set.

Put host userspace in the other two top-level slices:

| Slice | Typical members | Allowed CPUs |
|---|---|---|
| `user.slice` | graphical session, terminals, browsers | host set (example: `0-7`) |
| `system.slice` | `libvirtd`, Docker, `irqbalance` | host set (example: `0-7`) |
| `machine.slice` | QEMU, `swtpm`, guest `virtiofsd` | all CPUs (do not restrict) |

Do **not** set `CPUAffinity=` on PID 1 in `system.conf`. That mask is inherited by everything systemd starts. A guest pinned to CPUs outside that mask may fail to run there.

This is not the performance governor. Governor and affinity solve different problems; use both.

Example split for a 16-thread host with guests pinned to `8-15`: host slices get `0-7`. Substitute the complement of your domain `cpuset`.

## Host files

The snippets below are also in [`host/`](./host/index.md) in this repository. From a checkout:

```bash
sudo sh docs/research/VFIO/host/install-host-affinity.sh
```

Reruns keep an existing `/etc/default/vm-host-cpus` so a custom `HOST_CPUS` is not replaced by the sample.

`systemctl set-property` applies the limit immediately. A reboot is not required, but it is the cleanest way to make sure every existing process picked it up.

### 1. CPU list

`/etc/default/vm-host-cpus`

```bash
# Host CPUs for user.slice and system.slice.
# Use the complement of the guest <vcpu cpuset="...">.
HOST_CPUS=0-7
```

### 2. user.slice

`/etc/systemd/system/user.slice.d/50-host-cpus.conf`

```ini
[Slice]
AllowedCPUs=0-7
```

### 3. system.slice

`/etc/systemd/system/system.slice.d/50-host-cpus.conf`

```ini
[Slice]
AllowedCPUs=0-7
```

Leave `machine.slice` without an `AllowedCPUs=` drop-in.

```bash
sudo systemctl daemon-reload
sudo systemctl set-property --runtime user.slice AllowedCPUs=0-7
sudo systemctl set-property --runtime system.slice AllowedCPUs=0-7
```

`--runtime` applies the limit now. The drop-ins above are what survive a reboot. Omit `--runtime` only if you want systemd to write a second persistent file.

## Verify

```bash
cat /sys/fs/cgroup/user.slice/cpuset.cpus.effective
cat /sys/fs/cgroup/system.slice/cpuset.cpus.effective
cat /sys/fs/cgroup/machine.slice/cpuset.cpus.effective
```

Expected on a 16-thread host with guests on `8-15`:

- `user.slice` / `system.slice`: `0-7`
- `machine.slice`: `0-15`

```bash
# desktop / host services should stay on the host set
taskset -cp "$(pgrep -n Xorg)"
taskset -cp "$(pgrep -n libvirtd)"

# guest vCPU threads should still match <vcpupin>
for tid in /proc/$(pgrep -n qemu-system-x86_64)/task/*; do
  comm=$(cat "$tid/comm")
  case "$comm" in
    CPU*) printf '%s %s\n' "$comm" "$(taskset -cp "$(basename "$tid")" | sed 's/.*: //')" ;;
  esac
done
```

If vCPU threads suddenly show `0-7`, `machine.slice` was restricted as well. Remove that drop-in and restart the guest.

## Notes

- `irqbalance` should still use `IRQBALANCE_BANNED_CPULIST` for the guest CPUs. Affinity does not replace that.
- Kernel threads and `init.scope` are not in `user.slice` / `system.slice`. A few IRQs or kworkers may still appear on the guest CPUs.
- `isolcpus=` remains optional. If you enable it later, keep the slice limits; they document the same split for userspace.
