# Debian Btrfs 极简滚动镜像

基于 Debian 官方源制作，采用 `debootstrap --variant=minbase` 纯手工精简。这是一款专为阿里云等云平台设计的极简 qcow2 镜像，具备极致压缩、原生安全、全能引导等特性，并随官方源持续滚动更新。

---

## 🚀 核心特性

- **极致压缩 (ZSTD:9)**：强制开启 Btrfs **ZSTD:9** 高等级透明压缩。1G 磁盘空间通过高倍率压缩，实际能安装的软件包通常能达到 2G-3G 的等效容量。
- **官方滚动源**：始终基于 Debian 官方最新包构建，支持平滑跨版本滚动升级。
- **原生安全 (Zero-Trust)**：
  - **无预设密码、无预设用户、使用密钥**。
  - 彻底杜绝默认凭据泄露风险，强制通过 **Cloud-init** 在首次启动时初始化凭据。
- **自动扩容**：集成 **Cloud-init**，首次启动时会自动识别并扩展至阿里云 ECS 分配的磁盘容量。
- **全模式引导**：支持 **BIOS (Legacy)** 与 **UEFI** 双模式启动，完美适配阿里云全系列实例。
- **轻量紧凑**：仅保留系统核心组件，空闲/最小运行约 **100MB+**。

---

## 📊 技术规格 (基于实测数据)


| 维度 | 技术参数 |
| :--- | :--- |
| **系统版本** | Debian GNU/Linux x86_64 |
| **文件系统** | Btrfs (默认参数: `compress-force=zstd:9`) |
| **磁盘空间** | 1 GiB 总容量 (支持自动/手工扩容) |
| **内存占用** | 空闲/最小运行约 **100MB+** |
| **初始化引擎** | **Cloud-init (唯一配置入口)** |

---

## 📸 系统运行实测

![系统参数与磁盘布局汇总](https://i0.du0.org/i/11f0/169eb1f48667ac.webp)
---

## 📥 镜像下载

[**👉 点击前往 Releases 页面查看全部版本**](https://github.com/longsays/debian-btrfs/releases)

- [**📦 直接下载最新 BIOS 镜像**](https://github.com/longsays/debian-btrfs/releases/latest/download/debian-trixie-btrfs-bios-latest.qcow2)
- [**📦 直接下载最新 UEFI 镜像**](https://github.com/longsays/debian-btrfs/releases/latest/download/debian-trixie-btrfs-bios-uefi-latest.qcow2)

---

## ⚙️ 阿里云部署指引 (Cloud-init)

**⚠️ 重要：** 由于镜像未内置密码，在阿里云创建 ECS 实例时，请务必执行以下 **其中一种** 初始化方式：

### 方式一：使用阿里云原生凭据 (推荐)
在 **“管理设置”** 步骤中（如下图所示），直接选择：

 **密钥对**：选择您现有的 SSH 密钥对（推荐）。
>镜像已通过 `disable_root: false` 优化，支持 root 直接登录，无需跳转 debian 。

![阿里云登录凭证设置](https://i0.du0.org/i/11f0/169ecbae258083.webp)

### 方式二：使用自定义数据
若需更高级的配置，请展开页面下方的 **“高级选项”**，在 **“自定义数据”** 中填入：

```yaml
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...你的公钥内容...
```

---

## 🏁 快速上手 (必看)

默认用户 `root`。
> **💡 提示：** 首次通过 SSH 密钥登录后，建议执行 `passwd` 为 `root` 设置密码，以便后续通过阿里云 VNC 控制台管理。

由于是滚动版镜像，进入系统后的**第一步操作**必须是同步官方软件包索引：

```bash
apt update
```

---

## 🛠 进阶操作

### 1. 磁盘空间管理
由于开启了 ZSTD:9 压缩，`df -h` 无法反映物理空间真实情况，请通过以下命令查看真实余量：
```bash
# 查看物理磁盘真实余量
btrfs filesystem usage /

# 查看根目录下所有文件的压缩统计
compsize -x /
```

### 2. 手工扩容说明
虽然 Cloud-init 会自动处理初始扩容，但在阿里云控制台**在线扩容磁盘**后，需手工执行以下命令让文件系统识别：
```bash
# 在线扩展 Btrfs 文件系统到最大可用空间
btrfs filesystem resize max /
```

---

## 📜 兼容性验证
- [x] **阿里云 (Aliyun Cloud)**：自定义镜像导入测试通过，支持全系实例。
- [x] **引导模式**：UEFI/GPT & BIOS/MBR 双支持。
- [x] **性能损耗**：ZSTD:9 压缩在现代云服务器 CPU 下运行流畅，无感解压。

---

