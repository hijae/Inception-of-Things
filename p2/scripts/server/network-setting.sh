#!/bin/bash
set -euo pipefail

# The box runs systemd-resolved with DNSSEC=yes, which rejects answers from
# upstream servers without DNSSEC support. /etc/resolv.conf is a symlink that
# resolved rewrites, so writing it directly does not stick. Configure resolved
# itself through a drop-in instead.
mkdir -p /etc/systemd/resolved.conf.d
cat <<CONF > /etc/systemd/resolved.conf.d/dns.conf
[Resolve]
DNS=8.8.8.8 8.8.4.4
DNSSEC=no
CONF

systemctl restart systemd-resolved

# Fail early: otherwise the k3s install script fails silently on DNS errors.
for i in $(seq 1 10); do
    if getent hosts get.k3s.io > /dev/null; then
        break
    fi
    if [ "$i" -eq 10 ]; then
        echo "❌ Error: DNS resolution failed (get.k3s.io)"
        exit 1
    fi
    sleep 2
done
echo "✅ DNS resolution is working"

apt-get update
apt-get install -y curl
