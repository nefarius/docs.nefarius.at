# CPU governor for pinned KVM vCPUs

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0

Related: [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md).

## Problem

Pinned guest vCPUs only stay on the host CPUs you assign. They do **not** get a `performance` frequency governor by themselves.

A common first step is a udev rule that sets `scaling_governor=performance` on those CPUs at `ACTION=="add"` (device appear at boot). That works on a quiet boot. After a Debian / Ubuntu / Linux Mint upgrade, the `cpufrequtils` LSB service typically starts next and writes `ondemand` (or whatever `GOVERNOR` is) to **every** CPU. The udev change is gone before login.

Confirm with:

```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

If every line is `ondemand` even though the udev rule exists, this is the race.

This is not CPU isolation (`isolcpus`) and not systemd `CPUAffinity`. Those keep *other* tasks off the guest CPUs. The governor only controls how high those CPUs clock when they *do* run work.

## Approach

Keep the udev rule as a first attempt. Make the setting survive `cpufrequtils` with a oneshot unit that runs **after** it.

- Host CPUs used by the desktop stay on `ondemand` (via `cpufrequtils`).
- Host CPUs listed in the guest `<cputune>` / `cpuset` are forced to `performance`.

Example: a guest pinned to host CPUs `8-15` uses that same list here. Substitute the set from `virsh vcpuinfo <domain>` / the domain XML.

## Host files

The snippets below are also in [`host/`](./host/) in this repository. From a checkout:

```bash
sudo sh docs/research/VFIO/host/install.sh 8-15
```

Without the CPU-list argument the script only installs the sample `VM_CPUS=8-15` file and does not enable the unit. Pass this host’s guest pin list to write it and `systemctl enable --now`.

### 1. CPU list

`/etc/default/vm-cpu-governor`

```bash
# Host CPUs reserved for pinned KVM guests.
# Use the same set as <vcpu cpuset="..."> / <cputune><vcpupin>.
VM_CPUS=8-15
VM_GOVERNOR=performance
```

### 2. Keep cpufrequtils from becoming a silent default

`/etc/default/cpufrequtils` is optional but useful: the init script sources it if present. This keeps host-wide policy explicit after package upgrades.

```bash
ENABLE="true"
GOVERNOR="ondemand"
MAX_SPEED="0"
MIN_SPEED="0"
```

Leave `ENABLE="true"` so leftover host CPUs still get `ondemand`. Do not set `GOVERNOR="performance"` here unless you want the entire machine on that governor.

### 3. Helper script

`/usr/local/sbin/set-vm-cpu-governor`

```bash
#!/bin/sh
# Apply a cpufreq governor to the host CPUs reserved for pinned KVM guests.
set -eu

VM_CPUS=8-15
VM_GOVERNOR=performance

if [ -r /etc/default/vm-cpu-governor ]; then
	# shellcheck disable=SC1091
	. /etc/default/vm-cpu-governor
fi

expand_cpus() {
	echo "$1" | tr ',' '\n' | while IFS= read -r tok; do
		tok=$(printf '%s' "$tok" | tr -d '[:space:]')
		[ -z "$tok" ] && continue
		case "$tok" in
		*-*)
			start=${tok%-*}
			end=${tok#*-}
			seq "$start" "$end"
			;;
		*)
			printf '%s\n' "$tok"
			;;
		esac
	done
}

status=0
for cpu in $(expand_cpus "$VM_CPUS"); do
	gov="/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_governor"
	if [ ! -f "$gov" ]; then
		echo "set-vm-cpu-governor: missing $gov" >&2
		status=1
		continue
	fi
	printf '%s\n' "$VM_GOVERNOR" > "$gov"
done
exit "$status"
```

```bash
sudo chmod 755 /usr/local/sbin/set-vm-cpu-governor
```

### 4. systemd oneshot

`/etc/systemd/system/vm-cpu-governor.service`

```ini
[Unit]
Description=Set cpufreq governor on host CPUs reserved for KVM guests
After=cpufrequtils.service
After=loadcpufreq.service
Wants=loadcpufreq.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/set-vm-cpu-governor
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vm-cpu-governor.service
```

### 5. Optional udev rule

Harmless to keep. It is **not** sufficient on its own after `cpufrequtils` is installed.

`/etc/udev/rules.d/90-scaling-governor-performance.rules`

```udev
KERNEL=="cpu8|cpu9|cpu10|cpu11|cpu12|cpu13|cpu14|cpu15", SUBSYSTEM=="cpu", ACTION=="add", ATTR{cpufreq/scaling_governor}="performance"
```

Adjust the `KERNEL==` match if your guest CPU set is not `8-15`.

## Verify

```bash
systemctl status vm-cpu-governor.service --no-pager
for i in $(seq 0 15); do
  printf 'cpu%-2s %s\n' "$i" "$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor)"
done
```

Expected pattern on a 16-thread host with guests pinned to `8-15`:

- `cpu0`–`cpu7`: `ondemand`
- `cpu8`–`cpu15`: `performance`

Re-check after a reboot. If everything is `ondemand` again, `vm-cpu-governor.service` is not enabled or `After=cpufrequtils.service` is missing.

## Notes

- Changing the governor does not pin QEMU threads. Keep `<cputune>` in the domain XML.
- Keeping *other* host tasks off those CPUs is a separate step: [Host CPU affinity for pinned VMs](./Host-CPU-affinity-for-pinned-VMs.md).
- `isolcpus=` is a more aggressive option than slice `AllowedCPUs=`. It was left unused here.
- On AMD Zen, Linux CPU numbers `N` and `N+core_count` are usually SMT siblings of the same physical core. Pin and governor lists should still match whatever you already chose in libvirt; this unit does not change that layout.
