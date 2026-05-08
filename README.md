# N1 OpenWrt Actions

面向 Amlogic N1 / `armvirt-64` 的 OpenWrt 自动构建仓库，包含两套源码方案：

- `ARMv8 lean`: 基于 `coolsnowwolf/lede`
- `ARMv8 immwrt`: 基于 `immortalwrt/immortalwrt`

## 目录说明

- `lede/feeds.conf.default`: lean 构建使用的 feeds 定义
- `lede/armv8.config`: lean 构建使用的 `.config`
- `lede/diy.sh`: lean 构建使用的自定义脚本
- `immwrt/feeds.conf.default`: immortalwrt 构建使用的 feeds 定义
- `immwrt/armv8.config`: immortalwrt 构建使用的 `.config`
- `immwrt/diy.sh`: immortalwrt 构建使用的自定义脚本

## 工作流关系

```
[ARMv8 lean]   ──┐
                 ├──→ ROOTFS_* Release ──→ [ARMv8 Package] ──→ ARMv8_* Release
[ARMv8 immwrt] ──┘                                              (N1 可刷写镜像)
```

### RootFS 构建

- `.github/workflows/ARMv8-lean.yml`
- `.github/workflows/ARMv8-immwrt.yml`

这两个工作流会：

1. 克隆上游源码
2. 用仓库内的 `feeds.conf.default` 覆盖上游 feeds 配置
3. 更新并安装 feeds
4. 执行 `diy.sh`
5. 编译 `armvirt-64` rootfs
6. 发布到对应的 `ROOTFS_lean` 或 `ROOTFS_immwrt` Release

发布时会额外生成一个标准命名的 `rootfs.tar.gz`，供后续打包流程稳定使用。

触发方式：
- `workflow_dispatch`: 手动运行（可勾选 `clean_cache` 强制清缓存）
- `schedule`: 每天 UTC 20:00（北京时间次日 04:00）

### 成品固件打包

- `.github/workflows/Package.yml`

该工作流会从 `ROOTFS_lean` 或 `ROOTFS_immwrt` Release 中下载标准 `rootfs.tar.gz`，再调用 `ophub/flippy-openwrt-actions` 封装成 N1 可直接刷写的镜像，并发布到：

- `ARMv8_lean`
- `ARMv8_immwrt`

触发方式：
- `workflow_dispatch`: 手动运行，可指定 `kernel_version`、`firmware_source`（lean / immwrt / all）
- `repository_dispatch` (`types: [package-armv8]`): 外部触发
- `workflow_run`: 上游 RootFS 工作流成功完成时自动跟跑

## 仓库 Release 一览

| Tag             | 内容                       | 由哪个工作流维护          |
|-----------------|---------------------------|---------------------------|
| `ROOTFS_lean`   | lean rootfs.tar.gz        | ARMv8 lean                |
| `ROOTFS_immwrt` | immwrt rootfs.tar.gz      | ARMv8 immwrt              |
| `ARMv8_lean`    | lean 成品镜像 (.img.gz)   | ARMv8 Package             |
| `ARMv8_immwrt` | immwrt 成品镜像 (.img.gz) | ARMv8 Package             |

所有发布步骤都用 `allowUpdates: true` 原地更新对应 tag 的 release，长期只维持这 4 个 release。

## 缓存策略

`HiGarfield/cachewrtbuild` 的 `mixkey` 包含 `armv8.config` / `diy.sh` / `feeds.conf.default` 三个文件的 hash —— 任何一处改动都会自动失效缓存，无需手动勾 `clean_cache`。需要彻底刷新（如外部第三方仓库本身有更新）时再勾上。

## 权限说明

三个工作流都在文件顶层显式声明：

```yaml
permissions:
  contents: write
```

> 不显式声明的话，仓库默认 `GITHUB_TOKEN` 是只读，`ncipollo/release-action` 创建 release 时会 403。
> 仓库 `Settings → Actions → General → Workflow permissions` 保持默认（只读）即可，工作流级声明会就地生效。

## 维护原则

- 构建流程以各目录下的 `feeds.conf.default` 为准
- `diy.sh` 只在目标文件或目录存在时修改 feed 内容，减少因上游目录变化导致的失败
- `armv8.config` 中开启的包必须确认在 feed 中存在或 `diy.sh` 已克隆 —— 否则 `make defconfig` 会**静默丢弃**，固件里不会带，也不报错
- RootFS Release 与成品固件 Release 分开维护，便于复用和自动打包
- `Cleanup` 任务只清理过期的 workflow runs，不再按时间裁剪 release（4 个固定 tag 不会膨胀）

