#!/usr/bin/env sh

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Disable wildcard character expansion
set -o noglob

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp/etc/runlevels/$2"
	ln -sf "/etc/init.d/$1" "$tmp/etc/runlevels/$2/$1"
}

tmp=$(mktemp -d)
trap cleanup EXIT

# Networking
mkdir -p "$tmp/etc/network"
makefile root:root 0644 "$tmp/etc/network/interfaces" << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Local
mkdir -p "$tmp"/etc/local.d
makefile root:root 0755 "$tmp"/etc/local.d/preseed.start << EOF
#!/usr/bin/env sh

EOF

# OpenRC
rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add local boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > recluster.apkovl.tar.gz
