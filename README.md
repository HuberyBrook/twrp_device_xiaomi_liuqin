# TWRP 16 device tree — 小米平板 6 Pro（liuqin）

YARP（`twrp-16.0`）布局的 TWRP 设备树，用于小米平板 6 Pro。

```
机型      Xiaomi Pad 6 Pro
代号      liuqin
平台      taro / SM8475（骁龙 8+ Gen 1）
分区      A/B + 动态分区，独立 recovery 分区
界面      TWRP 3.7.1，gui2 / LVGL
```

---

## ⚠ 先读这一段：验证状态

本树**派生自同平台的 yudi（小米平板 6 Max 14）设备树**。yudi 那棵已在真机跑通
（启动、解密、触摸、MTP、备份均正常），但 **liuqin 这台没有真机可测**，
所以下面两类内容要严格区分：

| 类别 | 来源 | 可信度 |
|---|---|---|
| YARP 结构、构建流程、CI、gui2 配置、加密参数、已知坑的修复 | yudi 真机验证 | 高，同平台通用 |
| 分区大小、背光、触摸固件、fstab 挂载选项 | liuqin 原树 `xccxxcys/device_xiaomi_liuqin-TWRP-OF` | 中，静态来源未实测 |
| 屏幕方向、刷新率、CPU 温度 zone、安全补丁级别 | 沿用 yudi 的值 | **低，必须上机核对** |

代码里所有不确定的项都带 `⚠ 待验证` 注释，方便定位。

---

## 与 yudi 的差异（这是本树存在的意义）

| 项 | yudi（Pad 6 Max 14） | liuqin（Pad 6 Pro） |
|---|---|---|
| `PRODUCT_DEVICE` | yudi | **liuqin** |
| `PRODUCT_MODEL` | 2307BRPDCC | **Xiaomi Pad 6 Pro** |
| super 分区 | 11811160064（11 GiB） | **9126805504（8.5 GiB）** |
| 动态分区组上限 | 10737418240 | **9122611200** |
| 最大背光 | 4095 | **2047** |
| 触摸固件 | `novatek_nt36532_m80_*` | **`novatek_nt36532_m81_*`（csot + tm）** |
| 面板 | 14" 2880×1800 120Hz | 11" 2880×1800 144Hz |
| `TW_XIAOMI_TOUCH_PERMISSION_FIX` | 未启用 | **启用** |

两者镜像**不可互刷**。

---

## 上机后必做的核对清单

按顺序执行，任何一项不符就改对应配置再重建。

```bash
# 1) 设备身份
adb shell getprop ro.product.device     # 期望 liuqin
adb shell getprop ro.product.model      # 期望 Xiaomi Pad 6 Pro

# 2) 解密相关版本（决定 KeyMint 会不会 -62）—— 最关键
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.security_patch
adb shell getprop ro.vendor.build.security_patch
#   与 BoardConfig.mk 的 PLATFORM_VERSION / PLATFORM_SECURITY_PATCH /
#   VENDOR_SECURITY_PATCH 对比。recovery 报的补丁级别低于 ROM 会返回
#   -62 KEY_REQUIRES_UPGRADE，而升级必然失败（-8），表现为输对密码也解不开。

# 3) 分区实际容量
adb shell su -c 'blockdev --getsize64 /dev/block/by-name/super'
#   与 BOARD_SUPER_PARTITION_SIZE 对比

# 4) 背光
adb shell su -c 'cat /sys/class/backlight/panel0-backlight/max_brightness'
#   与 TW_MAX_BRIGHTNESS 对比

# 5) 面板刷新率（进 recovery 后看）
adb shell "dmesg | grep dsi_display_set_mode"    # 找 fps=
#   若确实是 144，可把 TW_FRAMERATE 从 120 改成 144

# 6) CPU 温度传感器
adb shell su -c 'for d in /sys/class/thermal/thermal_zone*; do echo "$d=$(cat $d/type)"; done' | grep -i cpu
#   与 TW_CUSTOM_CPU_TEMP_PATH 的 zone 编号对比

# 7) 触摸固件是否加载
adb shell "cat /proc/modules | grep -E 'nt36|xiaomi_touch'"
adb shell "grep -A3 -i novatek /proc/bus/input/devices"
```

---

## 构建

### GitHub Actions（推荐）

仓库已带 `.github/workflows/build.yml`，推送到 `twrp-16.0` 后在 Actions 页手动
Run workflow 即可，默认参数已指向本仓库。产物发到 Release。

工作流里有两段对本平台必须的 patch，**不要删**：

1. `Patch CTS platform releases` —— 向 CTS 版本清单补一行 `17`。
   `PLATFORM_VERSION_LAST_STABLE=17` 会让 `cts.mk` 因清单里没有 17 而中止构建。
2. `Patch gui2 performance` —— 把 LVGL 刷新周期钉成 8ms、去掉未录屏时的整帧
   多余拷贝。这两项是 2880×1800 软件渲染下的实际性能优化。

### 本地构建

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp -b twrp-16.0 --depth=1
repo sync -j$(nproc)

echo 17 >> cts/tests/tests/os/assets/platform_releases.txt   # 必须

git clone https://github.com/HuberyBrook/twrp_device_xiaomi_liuqin -b twrp-16.0 \
    device/xiaomi/liuqin

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_liuqin-eng
mka recoveryimage
```

---

## 刷入

分区是 `recovery_a` / `recovery_b`，**没有 `recovery` 这个通用别名**。

```bash
# 先备份现有 recovery
adb shell su -c 'dd if=/dev/block/by-name/recovery_a of=/sdcard/recovery_backup.img'

# 刷入
adb push TWRP-*.img /data/local/tmp/twrp.img
adb shell su -c 'dd if=/data/local/tmp/twrp.img of=/dev/block/by-name/recovery_a'
adb reboot recovery
```

回滚同理，把备份写回 `recovery_a`。

---

## 已知问题与设计取舍

1. **`prebuilt/kernel` 是 0 字节占位**，不要往里放内核。
   原厂 recovery 头部 `kernel_size = 0`，引导时复用 boot 分区的内核；
   放真内核反而改变镜像结构。对应 `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE`。

2. **不用 `TW_LOAD_VENDOR_MODULES`**，改用 `recovery/root/system/bin/load_touch.sh`
   在 init 阶段 `insmod`。原因：前者要求构建期调用宿主 `depmod`，而 YARP 的
   `twrp-16.0` 分支没有编出这个工具，构建会在
   `obj/PACKAGING/recovery_intermediates/ramdisk_files-timestamp` 处失败。
   运行时 `insmod` 还多一个好处：直接加载当前 ROM 的 `/vendor/lib/modules`，
   内核升级后不会出现 vermagic 不匹配。

3. **fstab 故意不带 `checkpoint=fs`**。vendor fstab 里有它时，vold 会把 `/data`
   挂成 `checkpoint=disable`，recovery 里的写入重启后会回滚。

4. **`TW_SKIP_ADDITIONAL_FSTAB := true`**，只用本树的 `recovery.fstab`，
   避免 vendor fstab 的 `checkpoint` 干扰。

5. **震动默认关闭**。OF 树用源码编译的 AIDL vibrator HAL，而 YARP 的 manifest
   不含 `vendor/qcom/opensource/vibrator`，直接开会中断构建。
   不过 TWRP 自己能找到 FF 输入设备（`qcom-hv-haptics`），实际仍会有震动反馈。

6. **inotify 配额**。`init.recovery.qcom.rc` 把 `max_user_watches` 提到 65536。
   否则 MTP 扫描大容量存储目录时配额耗尽，日志被
   `inotify_add_watch failed: No space left on device` 刷屏（该报错与磁盘空间无关）。

---

## 解密排错

如果进 recovery 后 `/data` 解不开：

```bash
adb shell "logcat -d | grep -iE 'keymaster|keymint|KEY_REQUIRES'"
adb shell "tail -40 /tmp/recovery.log | grep -iE 'key|vold|decrypt'"
```

| 症状 | 含义 | 处理 |
|---|---|---|
| `-62 KEY_REQUIRES_UPGRADE` | recovery 报的补丁级别低于 ROM | 调高 `PLATFORM_SECURITY_PATCH` / `BOOT_SECURITY_PATCH` |
| `-8` 或 keymaster 版本类错误 | keymaster 版本选错 | 检查 `TW_FORCE_KEYMASTER_VER` 与 `keymaster_ver` 属性 |
| 密钥已取到但 `/data` 挂载失败 | f2fs 挂载选项内核不支持 | 精简 `recovery.fstab` 中 userdata 的 f2fs 选项 |

---

## 许可

Apache-2.0（见 `LICENSE`）。板级数值参考了 `xccxxcys/device_xiaomi_liuqin-TWRP-OF`。
