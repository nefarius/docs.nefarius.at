#!/bin/sh
# Restrict host userspace to HOST_CPUS. Leave machine.slice unrestricted.
# Run as root from this directory.
set -eu

cd "$(dirname "$0")"

HOST_CPUS=0-7
if [ -r /etc/default/vm-host-cpus ]; then
	# shellcheck disable=SC1091
	. /etc/default/vm-host-cpus
elif [ -r ./vm-host-cpus ]; then
	# shellcheck disable=SC1091
	. ./vm-host-cpus
fi

install -m 0644 vm-host-cpus /etc/default/vm-host-cpus

install -d -m 0755 /etc/systemd/system/user.slice.d
install -d -m 0755 /etc/systemd/system/system.slice.d

cat > /etc/systemd/system/user.slice.d/50-host-cpus.conf <<EOF
[Slice]
AllowedCPUs=${HOST_CPUS}
EOF

cat > /etc/systemd/system/system.slice.d/50-host-cpus.conf <<EOF
[Slice]
AllowedCPUs=${HOST_CPUS}
EOF

systemctl daemon-reload
# --runtime: apply now without a second persistent drop-in. Reboot uses 50-host-cpus.conf.
systemctl set-property --runtime user.slice AllowedCPUs="${HOST_CPUS}"
systemctl set-property --runtime system.slice AllowedCPUs="${HOST_CPUS}"

echo "effective CPUs:"
echo -n "  user.slice:    "; cat /sys/fs/cgroup/user.slice/cpuset.cpus.effective
echo -n "  system.slice:  "; cat /sys/fs/cgroup/system.slice/cpuset.cpus.effective
echo -n "  machine.slice: "; cat /sys/fs/cgroup/machine.slice/cpuset.cpus.effective
