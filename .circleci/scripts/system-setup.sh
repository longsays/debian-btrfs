#!/bin/bash
# 文件: .circleci/scripts/system-setup.sh
# chroot 环境内的系统安装与配置脚本

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none

apt-get update
apt-get -y -o DPkg::Options::='--force-confdef' -o DPkg::Options::='--force-confold' install \
  cloud-init openssh-server locales tzdata linux-image-cloud-amd64 initramfs-tools \
  btrfs-progs btrfs-compsize unattended-upgrades dbus \
  wget htop curl iproute2 net-tools ifupdown isc-dhcp-client python3-requests ca-certificates dialog perl-modules \
  ${GRUB_PKGS} ${EXTRA_PKGS}

# 配置 locale
sed -i '/en_US.UTF-8 UTF-8/s/^# //g' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# 配置自动更新
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'APT_EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT_EOF

sed -i 's/.*Unattended-Upgrade::Remove-Unused-Dependencies.*/Unattended-Upgrade::Remove-Unused-Dependencies "true";/' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/.*Unattended-Upgrade::Remove-Unused-Kernel-Packages.*/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/' /etc/apt/apt.conf.d/50unattended-upgrades
echo 'Unattended-Upgrade::Post-Invoke-Purge "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
passwd -d root

grep -q "^GRUB_TIMEOUT=" /etc/default/grub && sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub || echo 'GRUB_TIMEOUT=1' >> /etc/default/grub
grep -q "^GRUB_TIMEOUT_STYLE=" /etc/default/grub && sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub || echo 'GRUB_TIMEOUT_STYLE=menu' >> /etc/default/grub
sed -i '/GRUB_RECORDFAIL_TIMEOUT/d' /etc/default/grub; echo 'GRUB_RECORDFAIL_TIMEOUT=0' >> /etc/default/grub

grep -q "^#*prepend domain-name-servers" /etc/dhcp/dhclient.conf && sed -i 's/^#*prepend domain-name-servers.*/prepend domain-name-servers 8.8.8.8, 1.1.1.1, 119.29.29.29, 223.5.5.5, 2001:4860:4860::8888;/' /etc/dhcp/dhclient.conf || echo "prepend domain-name-servers 8.8.8.8, 1.1.1.1, 119.29.29.29, 223.5.5.5, 2001:4860:4860::8888;" >> /etc/dhcp/dhclient.conf

# 清理
rm -rf /usr/share/doc/* /var/cache/apt/* /var/lib/apt/lists/*
find /usr/share/locale/ -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} +
cat /etc/passwd && cat /etc/shadow
rm -f /etc/ssh/ssh_host_*
apt-get -y autoremove && apt-get -y clean

