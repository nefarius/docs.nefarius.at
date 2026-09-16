#!/bin/sh
# Install the VM CPU governor oneshot. Run as root from this directory.
set -eu

cd "$(dirname "$0")"

install -d -m 0755 /usr/local/sbin
install -m 0644 vm-cpu-governor /etc/default/vm-cpu-governor
install -m 0644 cpufrequtils /etc/default/cpufrequtils
install -m 0755 set-vm-cpu-governor /usr/local/sbin/set-vm-cpu-governor
install -m 0644 vm-cpu-governor.service /etc/systemd/system/vm-cpu-governor.service

systemctl daemon-reload
systemctl enable --now vm-cpu-governor.service

echo "Governors:"
for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
	cpu=$(echo "$gov" | sed -n 's|.*/\(cpu[0-9]*\)/.*|\1|p')
	printf '%s %s\n' "$cpu" "$(cat "$gov")"
done
