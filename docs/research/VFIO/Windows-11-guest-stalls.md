# Debugging Windows 11 guest stalls that look like slow disk I/O

The investigation in this article was conducted under the following conditions:

Property | Value
---|---
Date | November 2026
Host kernel | 6.8.0-139-generic
Host distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0
virtiofsd | 1.10.0
Guest OS | Windows 11 25H2 (build 26200, stripped custom image)

Related: [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md), [Looking Glass B7 with IVSHMEM](./Looking-Glass-B7.md), [Raw virtio-blk boot disk](./Raw-virtio-blk-boot-disk.md).

## Problem

A Windows 11 VFIO guest booted quickly and showed low CPU, RAM, and disk utilization, yet interactive workloads stalled severely:

- Launching PowerShell 7 took minutes while loading assemblies.
- File Explorer (`This PC`, `Run`) hung indefinitely.
- Downloads and network tools paused for ~24 seconds before transferring data.
- Small `.msi` installers took 20–30+ minutes or timed out.

The symptoms looked like failing virtual storage or KVM thread contention. Measuring completed host block I/O ruled out slow completed disk transfers first; the stalls turned out to be **four independent bottlenecks** stacked on top of each other across VirtIO-FS, leftover Defender drivers, LAN IPv6 DNS, and Windows 11 24H2/25H2 Smart App Control Evaluation Mode, plus a missing SPICE channel blocking `spice-vdagent`.

## 1. Rule out host storage and KVM

Before changing guest storage or CPU tuning, measure actual block-device latency from QEMU via QMP so you know whether completed I/O is stalling below or inside Windows.

List the domain's block devices first to find each disk's QMP `qdev` device ID (such as `virtio-disk0` and `virtio-disk1`):

```bash
virsh qemu-monitor-command <domain> '{"execute":"query-block"}'
```

Enable latency histograms on every disk under test:

```bash
for id in virtio-disk0 virtio-disk1; do
  virsh qemu-monitor-command <domain> \
    "{\"execute\":\"block-latency-histogram-set\",\"arguments\":{\"id\":\"$id\",\"boundaries\":[1000000,5000000,20000000,100000000]}}"
done
```

Trigger a stall in the guest, then query counters and histograms:

```bash
virsh qemu-monitor-command <domain> '{"execute":"query-blockstats"}'
```

On this guest, both `virtio-blk` disks averaged **~115 µs** per read and **~88 µs** per write, with **zero I/Os ≥ 20 ms** across ~172,000 operations, zero failed I/Os, and 0% disk busy during hangs. Inside Windows, a 500× 4 KiB write/read/delete loop finished in **150–290 ms** and copying + executing `whoami.exe` took **~25 ms**.

!!! note "Looking Glass and virtiofsd"
    `virtiofsd` 1.10 exits with `Illegal seek` if the domain also maps `/dev/kvmfr0` (see [Looking Glass B7 with IVSHMEM](./Looking-Glass-B7.md)). This guest already used `/dev/shm/looking-glass`, so Looking Glass was not crashing `virtiofsd`.

With completed host I/O fast, the remaining stalls appeared to lie in software layers above the disk. QEMU latency histograms record only completed or failed requests, so they do not by themselves exclude a request that remains outstanding in flight during a hang.

## 2. Wedged VirtIO-FS / WinFsp mount

### Symptom

- PowerShell 7 hung for minutes on startup and eventually printed:

  ```text
  Attempting to perform the InitializeDefaultDrives operation on the 'FileSystem' provider failed.
  ```

- Explorer `This PC` spun indefinitely on the VirtIO-FS drive letter (no volume label or capacity bar), and `Run` went `(Not Responding)`.
- `sc stop VirtioFsSvc` timed out with error `1053`, while `virtiofsd` on the host logged zero incoming requests.

### Cause

`WinFsp.Np` sat first in `HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order`. While `VirtioFsSvc` was deadlocked, any process enumerating drives or network providers blocked waiting on it.

### Fix

Disable the service, uninstall WinFsp, and reboot the guest:

```cmd
sc config VirtioFsSvc start= disabled
```

After rebooting without the wedged provider, PowerShell 7 and Explorer immediately became responsive. If you need host-to-guest file sharing again later, either reinstall a clean WinFsp build or share the host folder over SMB on the local bridge.

## 3. Leftover Defender minifilter on a stripped image

### Symptom and cause

Custom stripped Windows builds often remove `WinDefend` (`MsMpEng.exe`) while leaving `WdFilter` attached to every NTFS volume and `MpDefenderCoreService` running. Check with an elevated prompt:

```cmd
fltmc
sc query MpDefenderCoreService
```

### Fix

!!! warning "Stripped guest images only"
    Only disable leftover Defender drivers on guest images where Defender is already intentionally stripped and broken. Do not apply this on a normal desktop that relies on Microsoft Defender.

Unload/disable the remaining Defender components (`WdFilter.sys`, `WdBoot.sys`, `WdNisDrv.sys`, `WdDevFlt.sys`) and reboot, then confirm `WdFilter` no longer appears in `fltmc` and `MpDefenderCoreService` is stopped.

## 4. Stale IPv6 DNS server advertised on the LAN

### Symptom

Every uncached DNS lookup inside Windows stalled for **~24.3 seconds** before succeeding:

```powershell
# Stalled ~24,291 ms via default system resolver
Measure-Command { Resolve-DnsName example.com }

# Completed in ~4 ms when bypassing IPv6 DNS directly
Measure-Command { Resolve-DnsName example.com -Server <lan-dns-ipv4> }
```

`Invoke-WebRequest` showed the same ~24-second delay before starting any transfer.

### Cause

The OpenWrt router (`odhcpd`) advertised a stale IPv6 ULA DNS address via `dhcp.lan.dns`. The local DNS server's DHCPv6 static host entry had no pinned `hostid`, so after a renewal its ULA suffix drifted (for example, from `fd00:0:0:1::10` to `fd00:0:0:1::20`). Windows preferred the advertised IPv6 DNS address, retried until timeout (~24 seconds), and only then fell back to IPv4.

### Fix

1. Pin the DNS server's IPv6 interface identifier (`hostid`) on its DHCPv6 static lease in OpenWrt and reload `odhcpd`:

    ```sh
    uci set dhcp.@host[<index>].hostid='<hostid>'
    uci commit dhcp
    /etc/init.d/odhcpd reload
    ```

2. Renew the DNS server's DHCPv6 lease (if it does not already hold the pinned address), confirm that the server has acquired the pinned IPv6 address, and verify that its DNS service answers queries on that address before advertising it to LAN clients.

3. Inspect the current `dhcp.lan.dns` entries and record every resolver in its current order (whether shown as separate quoted list tokens or a single space-separated string):

    ```sh
    uci show dhcp.lan
    ```

4. Delete `dhcp.lan.dns` and rebuild it as separate `uci add_list` entries in the original order, replacing the stale ULA in place with the verified complete IPv6 address (so resolver priority is preserved and any scalar or space-separated value is normalized into valid list entries), then commit and reload `odhcpd`:

    ```sh
    uci delete dhcp.lan.dns
    # Re-add every resolver in its original order, substituting <pinned-ula-address>
    # at the position of the stale ULA address:
    uci add_list dhcp.lan.dns='<resolver-1-in-original-order>'
    uci add_list dhcp.lan.dns='<resolver-2-in-original-order>'
    uci commit dhcp
    /etc/init.d/odhcpd reload
    ```

    Write the complete IPv6 address for `<pinned-ula-address>`. Because `odhcpd` accepts `hostid` values longer than four hex digits, split any longer `hostid` into 16-bit colon-separated groups (for example, `hostid` `123456` with prefix `fd00:0:0:1::/64` becomes `fd00:0:0:1::12:3456`).

5. Re-enable or renew the guest interface and re-test:

    ```powershell
    Measure-Command { Resolve-DnsName example.com }
    ```

With IPv6 enabled, uncached lookups dropped from **~24,291 ms** to **~2.2 ms**.

## 5. Smart App Control Evaluation Mode + missing SmartScreen (2-minute MSI stalls)

### Symptom

Even after VirtIO-FS, Defender leftovers, and DNS were fixed, `.msi` installers (such as `.NET 10` runtime packages and small WiX-based setups) still stalled for **~2 minutes per step**, turning routine installs into 20–30+ minute waits.

- `msiexec /V` sat idle waiting on `msiexec -Embedding`.
- The Windows **System** event log repeatedly recorded DCOM Event ID `10001` (`ERROR_FILE_NOT_FOUND`) trying to activate the SmartScreen COM class `{A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D}`.

### Cause

This matches the Windows 11 24H2/25H2 Code Integrity / Smart App Control stall documented in [microsoft/Windows-Sandbox#68](https://github.com/microsoft/Windows-Sandbox/issues/68).

Check the current policy state:

```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" `
  -Name "VerifiedAndReputablePolicyState"
```

Value | State
---|---
`0` | Off
`1` | Enforced
`2` | Evaluation Mode

When `VerifiedAndReputablePolicyState` is `2` (Evaluation Mode) on an image where SmartScreen has been stripped, Windows still tries to invoke SmartScreen over DCOM during binary and MSI verification. Each attempt waits for the DCOM activation timeout (~2 minutes) before failing over.

### Fix

Set `VerifiedAndReputablePolicyState` to `0` and refresh Code Integrity policy in place from an elevated PowerShell prompt:

```powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" `
  -Name "VerifiedAndReputablePolicyState" -Value 0
CiTool.exe --refresh --json
```

The refresh takes effect immediately without a reboot and persists across restarts. An MSI installer that had been crawling for ~30 minutes finished immediately after running these two lines.

## 6. Missing SPICE channel and virtio input devices

### Symptom

Clipboard sharing between host and guest did not work, and the `spice-vdagent` installer hung waiting for the agent service to start because the domain XML lacked a SPICE virtio-serial channel.

### Fix

Add the `com.redhat.spice.0` channel and virtio input devices to the domain XML (see the full snippet in [Looking Glass B7 with IVSHMEM](./Looking-Glass-B7.md)):

```xml
<channel type="spicevmc">
  <target type="virtio" name="com.redhat.spice.0"/>
</channel>
<input type="mouse" bus="virtio"/>
<input type="keyboard" bus="virtio"/>
```

Attach them persistently (`virsh edit <domain>` or `virsh attach-device --config`) and perform a **full power cycle** (shut down and start, not an in-guest reboot) so QEMU exposes the new devices to Windows.

## Quick triage summary

Symptom | Check | Fix
---|---|---
Looks like slow disk I/O | `query-blockstats` + `block-latency-histogram-set` via QMP | Verify sub-millisecond host I/O before blaming storage
PowerShell `InitializeDefaultDrives` hang; Explorer `This PC` spins | `sc stop VirtioFsSvc` times out (`1053`); `WinFsp.Np` in `NetworkProvider\Order` | Disable `VirtioFsSvc`, uninstall WinFsp, reboot
Leftover Defender filter on stripped image | `fltmc` shows `WdFilter`; `MpDefenderCoreService` running | Remove leftover Defender drivers and reboot
~24 s stall on every uncached DNS lookup | `Resolve-DnsName` slow vs `-Server <lan-dns-ipv4>` fast | Pin DNS server IPv6 `hostid` and update `dhcp.lan.dns`
~2 min stall per MSI step; DCOM `10001` for `{A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D}` | `VerifiedAndReputablePolicyState` is `2` with SmartScreen missing | Set `VerifiedAndReputablePolicyState` to `0` and run `CiTool.exe --refresh --json`
No clipboard; `spice-vdagent` hangs on install | Domain XML missing `com.redhat.spice.0` | Add `spicevmc` channel + virtio input and cold-boot VM
