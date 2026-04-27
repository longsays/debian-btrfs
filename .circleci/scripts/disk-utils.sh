#!/bin/bash
# 文件: .circleci/scripts/disk-utils.sh
# 磁盘操作工具函数库

set -euo pipefail

# 全局配置
export BTRFS_MOUNT_OPTS="subvol=@,compress-force=zstd:9,discard=async,noatime"
export BTRFS_MKFS_OPTS="-f -M -n 4k"

# 环境初始化
init_env() {
  export RELEASE="${1:-trixie}"
  export BOOT_MODE="${2:-bios}"
  export IMG_FILE="debian-${RELEASE}-btrfs.img"
  export MOUNT_DIR="/mnt/debian-root"
}

# 循环设备管理
setup_loop_device() {
  local img_file="$1"
  
  LOOP_DEV=$(sudo losetup --show -fP "$img_file")
  sleep 1
  
  if [ -b "${LOOP_DEV}p1" ]; then
    PART1_DEV="${LOOP_DEV}p1"
    PART2_DEV="${LOOP_DEV}p2"
    PART3_DEV="${LOOP_DEV}p3"
  else
    local kout=$(sudo kpartx -av "$LOOP_DEV" 2>/dev/null || true)
    PART1_DEV=$(echo "$kout" | awk '/p1/ {print "/dev/mapper/" $3; exit}' || echo "")
    PART2_DEV=$(echo "$kout" | awk '/p2/ {print "/dev/mapper/" $3; exit}' || echo "")
    PART3_DEV=$(echo "$kout" | awk '/p3/ {print "/dev/mapper/" $3; exit}' || echo "")
  fi
}

resolve_boot_devices() {
  if [ "$BOOT_MODE" = "bios-uefi" ]; then
    ROOT_DEV="$PART3_DEV"
    EFI_DEV="$PART2_DEV"
  else
    ROOT_DEV="$PART1_DEV"
    EFI_DEV=""
  fi
  
  if [ -z "$ROOT_DEV" ] || [ ! -b "$ROOT_DEV" ]; then
    echo "错误: 根分区设备映射失败" >&2
    return 1
  fi
}

has_valid_efi_dev() {
  [ -n "${EFI_DEV:-}" ] && [ -b "$EFI_DEV" ]
}

cleanup_loop_device() {
  local loop_dev="$1"
  command -v kpartx >/dev/null 2>&1 && sudo kpartx -dv "$loop_dev" || true
  sudo losetup -d "$loop_dev" || true
}

# 文件系统挂载
mount_root_filesystem() {
  local mount_dir="$1"
  sudo mkdir -p "$mount_dir"
  sudo mount -o "$BTRFS_MOUNT_OPTS" "$ROOT_DEV" "$mount_dir"
}

umount_root_filesystem() {
  local mount_dir="$1"
  sudo umount "$mount_dir" 2>/dev/null || true
}

mount_efi_filesystem() {
  local mount_dir="$1"
  if has_valid_efi_dev; then
    sudo mkdir -p "$mount_dir/boot/efi"
    sudo mount "$EFI_DEV" "$mount_dir/boot/efi"
  fi
}

umount_efi_filesystem() {
  local mount_dir="$1"
  if has_valid_efi_dev; then
    sudo umount "$mount_dir/boot/efi" 2>/dev/null || true
  fi
}

mount_virtual_filesystems() {
  local mount_dir="$1"
  for fs in proc sys dev run; do
    sudo mount --bind "/$fs" "$mount_dir/$fs"
  done
}

umount_virtual_filesystems() {
  local mount_dir="$1"
  for fs in run dev sys proc; do
    sudo umount "$mount_dir/$fs" 2>/dev/null || true
  done
}

# 初始化和清理
init_and_setup_loop() {
  init_env "$@"
  setup_loop_device "$IMG_FILE"
  resolve_boot_devices || return 1
}

cleanup_all() {
  local loop_dev="$1"
  local mount_dir="${2:-}"
  
  if [ -n "$mount_dir" ]; then
    umount_virtual_filesystems "$mount_dir"
    umount_efi_filesystem "$mount_dir"
    umount_root_filesystem "$mount_dir"
  fi
  
  cleanup_loop_device "$loop_dev"
}

error_cleanup() {
  local loop_dev="$1"
  local mount_dir="${2:-}"
  cleanup_all "$loop_dev" "$mount_dir"
  exit 1
}
