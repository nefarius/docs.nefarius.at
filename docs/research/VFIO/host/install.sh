#!/bin/sh
# Install the VM CPU governor oneshot. Run as root from this directory.
set -eu

cd "$(dirname "$0")"

install -d -m 0755 /usr/local/sbin
if [ ! -e /etc/default/vm-cpu-governor ]; then
	install -m 0644 vm-cpu-governor /etc/default/vm-cpu-governor
fi
install -m 0644 cpufrequtils /etc/default/cpufrequtils
install -m 0755 set-vm-cpu-governor /usr/local/sbin/set-vm-cpu-governor
install -m 0644 vm-cpu-governor.service /etc/systemd/system/vm-cpu-governor.service

systemctl daemon-reload

if [ "$#" -eq 0 ]; then
	echo "Installed sample VM_CPUS=8-15 in /etc/default/vm-cpu-governor."
	echo "Set VM_CPUS to this host's guest pin list, then:"
	echo "  systemctl enable --now vm-cpu-governor.service"
	echo "Or rerun: $0 <VM_CPUS>   (e.g. $0 8-15)"
	exit 0
fi

if ! printf '%s' "$1" | grep -Eq '^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$'; then
	echo "install.sh: invalid VM_CPUS '$1' (use e.g. 8-15 or 8,9,10-15)" >&2
	exit 1
fi

tmp=$(mktemp)
sed "s/^VM_CPUS=.*/VM_CPUS=$1/" /etc/default/vm-cpu-governor > "$tmp"
install -m 0644 "$tmp" /etc/default/vm-cpu-governor
rm -f "$tmp"

systemctl enable --now vm-cpu-governor.service

echo "Governors:"
for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
	cpu=$(echo "$gov" | sed -n 's|.*/\(cpu[0-9]*\)/.*|\1|p')
	printf '%s %s\n' "$cpu" "$(cat "$gov")"
done
