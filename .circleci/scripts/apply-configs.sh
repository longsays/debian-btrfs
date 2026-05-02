#!/bin/bash

MOUNT_DIR="${1:?Error: MOUNT_DIR not provided}"
[[ $EUID -ne 0 ]] && echo "Error: must run as root" >&2 && exit 1
mkdir -p "$MOUNT_DIR/etc/cloud/cloud.cfg.d"

# 生成并写入 cloud-init 配置
tee "$MOUNT_DIR/etc/cloud/cloud.cfg.d/99-custom.cfg" > /dev/null <<'EOF'
#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
disable_root: false
ssh_pwauth: true
preserve_hostname: false
package_update: true
package_upgrade: false
timezone: Asia/Shanghai

packages:
  - btrfs-compsize
  - unattended-upgrades
  - net-tools
  - nano
  - htop
  - curl
  - dialog
  - perl
  - rsync
  - lsof
  - tree
  - vim
  - screen
  - btop

write_files:
  - path: /etc/ssh/sshd_config.d/99-custom.conf
    owner: root:root
    permissions: '0600'
    content: |
      PermitRootLogin yes
      PasswordAuthentication yes
      PubkeyAuthentication yes
  - path: /etc/resolv.conf
    owner: root:root
    permissions: '0444'
    content: |
      options timeout:1 attempts:1
      nameserver 8.8.8.8
      nameserver 1.1.1.1
      nameserver 119.29.29.29
      nameserver 223.5.5.5
      nameserver 2001:4860:4860::8888
  - path: /etc/systemd/timesyncd.conf.d/99-custom.conf
    owner: root:root
    permissions: '0644'
    content: |
      [Time]
      NTP=ntp.aliyun.com ntp.tencent.com time.cloudflare.com pool.ntp.org
      FallbackNTP=ntp.ubuntu.com time.nist.gov
  - path: /etc/apt/apt.conf.d/99unattended-upgrades
    owner: root:root
    permissions: '0644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";
      Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      Unattended-Upgrade::Post-Invoke-Purge "true";

runcmd:
  - [ systemctl, restart, ssh ]
  - [ chattr, +i, /etc/resolv.conf ]
  - [ systemctl, restart, systemd-timesyncd ]
  - [ systemctl, restart, unattended-upgrades ]

EOF

