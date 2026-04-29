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
ssh_pwauth: false
preserve_hostname: false
package_update: true
package_upgrade: false
timezone: Asia/Shanghai

packages:
  - btrfs-compsize
  - net-tools
  - nano
  - htop
  - curl
  - dialog
  - perl-modules

write_files:
  - path: /etc/ssh/sshd_config.d/99-custom.conf
    owner: root:root
    permissions: '0600'
    content: |
      PermitRootLogin prohibit-password
      PasswordAuthentication no
      PubkeyAuthentication yes
runcmd:
  - systemctl restart sshd

system_info:
  default_user: null
EOF

