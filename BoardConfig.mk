#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 小米平板 6 Pro（liuqin）板级配置 —— YARP / TWRP 16 版
#
# 【重要】本树从同平台（taro / SM8475）的 yudi（小米平板 6 Max 14）树派生，
# 但板级数值改为 liuqin 自身来源。差异如下，务必注意验证状态：
#
#   数值来源：
#     liuqin 原树   xccxxcys/device_xiaomi_liuqin-TWRP-OF 的 BoardConfig / recovery.fstab
#                   / prebuilt（该树由 SebaUbuntu 生成器产出，作为 OrangeFox 使用过）
#     yudi 树       已在真机跑通的部分（YARP 结构、gui2 配置、加密参数、构建修复）
#
#   已按 liuqin 改动的项（未经真机核对，标注为「待验证」）：
#     - super 分区大小 9126805504（yudi 为 11811160064）
#     - 动态分区组上限 9122611200
#     - 最大背光 2047（yudi 为 4095）
#     - 触摸固件 novatek_nt36532_m81_*（liuqin 为 csot / tm 双供应商）
#
#   尚未核对的项（有真机后请逐项确认）：
#     - 屏幕刷新率（Pad 6 Pro 标称 144Hz，此处保守按 120，见 TW_FRAMERATE）
#     - TW_ROTATION（横竖屏朝向，与触摸坐标系绑定）
#     - PLATFORM_SECURITY_PATCH（必须等于 liuqin 当前 ROM 的值）
#     - CPU 温度传感器 zone 编号
#
# 所有「待验证」项都集中在下面带 ⚠ 标记的段落，方便定位修改。
#

DEVICE_PATH := device/xiaomi/liuqin

# 构建系统最小化（YARP 约定）
ALLOW_MISSING_DEPENDENCIES := true

# 设备断言：安装 zip 时校验 ro.product.device。
# 注意 liuqin 与 yudi 同为 taro 平台，绝不能混刷对方的镜像包。
TARGET_OTA_ASSERT_DEVICE := liuqin

# 额外系统属性
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Rules
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# 架构：骁龙 8+ Gen 1（SM8475），taro 平台
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader
# 真机 ro.board.platform=taro，ro.boot.hardware.platform 为空，ro.boot.hardware=qcom
PRODUCT_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := $(PRODUCT_PLATFORM)
TARGET_NO_BOOTLOADER := true
QCOM_BOARD_PLATFORMS += taro

# Platform
TARGET_BOARD_PLATFORM := taro
TARGET_BOARD_PLATFORM_GPU := qcom-adreno730

# 内核
# 原厂 recovery.img 头部 kernel_size = 0：恢复镜像本身不带内核，bootloader 复用 boot
# 分区的内核。因此 prebuilt/kernel 是 0 字节占位，只用于满足构建系统对
# TARGET_PREBUILT_KERNEL 文件存在的检查，实际不会打进镜像。
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_VERSION := 5.10
BOARD_KERNEL_PAGESIZE := 4096
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

# ramdisk 使用 LZ4（真机 boot/recovery 均为 lz4_legacy）
BOARD_RAMDISK_USE_LZ4 := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# 分区大小（真机 blockdev 实测，与 OF 树一致）
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_FLASH_BLOCK_SIZE := 262144

# 动态分区
# ⚠ 待验证：以下取值来自 liuqin 原树（OrangeFox），未在 liuqin 真机上用 blockdev 核对。
#   super 分区 9126805504 字节（8.5 GiB），分区组 = 该值 - 4 MiB 元数据。
#   与 yudi 的 11811160064（11 GiB）不同，两台机器 super 容量不一样，不可互抄。
# 仅用于构建期校验，不参与 recovery 产物。
# 注意：mi_ext 也属于该组，但构建系统不认识它，因此不列入；挂载交给 fstab。
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9122611200
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    odm \
    product \
    system \
    system_ext \
    vendor \
    vendor_dlkm

# 文件系统：逻辑分区 erofs、userdata f2fs、metadata ext4（真机 fstab 实测）
BOARD_USES_METADATA_PARTITION := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM := odm
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true

# 恢复模式的显示和输入
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# AVB：解锁状态下 recovery 不需要通过原厂校验，用 AOSP 测试密钥签名
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# 版本号与安全补丁级别（**必须与当前 ROM 一致**）
# 厂商的 libqtikeymint/libqtikeymaster4 会读 ro.build.version.release、
# ro.build.version.security_patch 与 ro.vendor.build.security_patch，据此判断 metadata
# key 是否需要升级。写小了会一直返回 -62 KEY_REQUIRES_UPGRADE，而升级必然失败（-8），
# 表现为解密彻底不可用。
#
# 当前值**暂沿用 yudi 的实测值**（同为 taro 平台、同代 HyperOS），
# ⚠ 未在 liuqin 真机上核对。方向是保守的：补丁级别写高不会触发
# KEY_REQUIRES_UPGRADE，写低才会 -62。若 liuqin 的 ROM 比这更新，必须跟着调高。
#
# 上机后第一时间核对并修正：
#   adb shell getprop ro.build.version.release
#   adb shell getprop ro.build.version.security_patch
#   adb shell getprop ro.vendor.build.security_patch
#
# boot 头部仍与原厂 boot 保持一致（12.0.0 / 2025-09），用 mkbootimg 参数显式覆盖。
PLATFORM_VERSION := 17
# LAST_STABLE 必须是 17：AOSP 里 ro.build.version.release 取的是它
# （build/make/core/sysprop.mk: ro.<part>.build.version.release=$(PLATFORM_VERSION_LAST_STABLE)），
# 只有 ro.build.version.release_or_codename 和指纹才用 PLATFORM_VERSION。
# KeyMint 判定 metadata key 是否需要升级时读 ro.build.version.release，
# 所以这里必须是 17，否则 recovery 会自称 16，与系统的 17 不一致 → -62。
#
# 副作用：cts/tests/tests/os/assets/platform_releases.txt（来自 android16.0.0_r1）
# 里只有 14/15/16/99.87.36，构建期 cts.mk 的 findstring 校验会因为找不到 17 而中止
# （Only when the cts/ directory exists）。CI 工作流已在 repo sync 后补了一行 "17"，
# 本地构建请照做：
#   echo 17 >> cts/tests/tests/os/assets/platform_releases.txt
PLATFORM_VERSION_LAST_STABLE := 17
PLATFORM_SECURITY_PATCH := 2026-10-01
VENDOR_SECURITY_PATCH := 2026-02-01
BOOT_SECURITY_PATCH := 2026-10-01
BOARD_MKBOOTIMG_ARGS += --os_version 12.0.0 --os_patch_level 2025-09

# 解密：FBE v2（inlinecrypt_optimized + wrappedkey_v0）加 metadata 加密
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
# 强制只用 keymaster_ver 属性，不从 vendor manifest 探测版本（本设备为 4.1）
TW_FORCE_KEYMASTER_VER := true
# 格式化 data 前先用 dmctl 解除 metadata 加密映射，否则 make_f2fs 报
# "In use by the system!"（物理 userdata 仍被 dm 占用）
TW_USE_DMCTL := true

# 界面
# 面板 2880x1800，但本机 DRM 的**首选模式是竖屏 1800x2880**（yudi 相反，首选
# 2880x1800）。TWRP 选模式时按 DRM_MODE_TYPE_PREFERRED 走，所以：
#   TW_ROTATION := 0   -> 帧缓冲 1800x2880，界面竖屏，触摸开箱即对 ← 当前采用
#   TW_ROTATION := 90/270 -> 帧缓冲 2880x1800，界面横屏，但触摸坐标会有偏差
#                            （只靠 ro.twrp.touch.rotation 校正不过来）
# 横屏方案暂缓：需要额外做触摸坐标标定（minui 里只有纯旋转+换轴，见
# twrpminui/twrp_input.cpp 的 vk_tp_to_screen）。先用竖屏交付可用版本。
TW_THEME := portrait_hdpi
TW_ROTATION := 0
# 帧率。⚠ 待验证：Pad 6 Pro 标称 144Hz，但这里保守取 120：
#   1) 不确定 liuqin 的 DRM 是否暴露 144Hz mode（yudi 的 DSI 只报 30/48/50/60/90/120）
#   2) 取低不会出问题，只是没吃满面板上限
# 上机确认后可用以下命令查真实值，再决定是否改成 144：
#   dmesg | grep -i "dsi_display_set_mode"        # 看 fps=
#   cat /tmp/recovery.log | grep "Display Mode"   # 看 @ .. FPS
# 提供背景：gui2 用 LVGL 的 LV_DEF_REFR_PERIOD = 1000 / TW_FRAMERATE 作渲染周期，
# 写 60 等于每 16ms 才允许刷一帧，会把高刷屏强行按 60Hz 用。
TW_FRAMERATE := 120
TW_NO_SCREEN_BLANK := true
TW_STATUS_ICONS_ALIGN := center

# 背光。⚠ 待验证：liuqin 原树写 2047，yudi 真机为 4095，两台机器不一样。
# 若上机后亮度条拖到底仍然很暗或一直最亮，先核对：
#   cat /sys/class/backlight/panel0-backlight/max_brightness
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
# 默认亮度按最大值的约 30% 取（yudi 是 1200/4095 ≈ 29%）
TW_DEFAULT_BRIGHTNESS := 600

# 小米触摸驱动权限修复：liuqin 原树启用了此项，yudi 树未用。
# 小米的 xiaomi_touch 驱动要求特定节点权限，缺了会导致触摸在 recovery 下无响应。
TW_XIAOMI_TOUCH_PERMISSION_FIX := true

# 语言
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true

# CPU 温度：taro 的 CPU 传感器是 cpuss-2。
# ⚠ 待验证：zone 编号沿用 yudi 的 27，liuqin 未核对。上机后确认：
#   for d in /sys/class/thermal/thermal_zone*; do echo "$d = $(cat $d/type)"; done | grep -i cpu
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone27/temp"

# 内核模块
# 显示、电池、USB、加密相关驱动在 vendor_boot 的 modules.load.recovery 里，第一阶段
# init 会自动加载。触控驱动（dtbo 中为 novatek,NVT-ts-spi，对应 nt36532_touch.ko，
# 另需 xiaomi_touch.ko）不在其中，由 recovery/root/system/bin/load_touch.sh 在
# init 阶段直接 insmod，优先取当前 ROM 的 /vendor/lib/modules，失败退回 ramdisk 副本。
#
# 不使用 TW_LOAD_VENDOR_MODULES：该路径会让构建系统在打包 ramdisk 时调用宿主
# depmod 生成 modules.dep，而 YARP 的 twrp-16.0 分支没有把它编出来，构建会中断：
#   FAILED: obj/PACKAGING/recovery_intermediates/ramdisk_files-timestamp
#   /bin/bash: line 1: out/host/linux-x86/bin/depmod: No such file or directory
# 运行时用 insmod 不需要 modules.dep，且能直接匹配当前内核。
#TW_LOAD_VENDOR_MODULES := "xiaomi_touch.ko nt36532_touch.ko"
#TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# 功能
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPTOOLS := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_7ZA := true
TW_INCLUDE_ZSTD := true
TW_INCLUDE_NTFS_3G := true
TW_USE_TOOLBOX := true
TW_EXCLUDE_APEX := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
# 高通平台的虚拟触摸设备会抢占触摸输入，屏蔽它
TW_INPUT_BLACKLIST := "hbtp_vm"
# 只用设备树里的 recovery.fstab。vendor fstab 的 /data 带 checkpoint=fs，vold 会把它
# 挂成 checkpoint=disable，recovery 中的写入重启后会回滚。
TW_SKIP_ADDITIONAL_FSTAB := true
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu

# 调试
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd

# 震动（可选，默认关闭）
# OF 树用源码编译的 AIDL vibrator HAL（vendor/qcom/opensource/vibrator）驱动
# qcom-hv-haptics。YARP 的 manifest 不包含该仓库，直接打开会导致 BOARD_RECOVERY_IMAGE_PREPARE
# 里的 cp 失败并中断构建。需要震动反馈时，在 local_manifest 里补上该仓库后取消注释。
#TW_SUPPORT_INPUT_AIDL_HAPTICS := true
#TARGET_RECOVERY_DEVICE_MODULES += vendor.qti.hardware.vibrator.service
#BOARD_RECOVERY_IMAGE_PREPARE += \
#    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64 \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/init \
#             $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/vintf/manifest && \
#    cp -f $(PRODUCT_OUT)/vendor/bin/hw/vendor.qti.hardware.vibrator.service $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw/ && \
#    cp -f $(PRODUCT_OUT)/vendor/lib64/*vibrator*.so $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/ && \
#    cp -f $(PRODUCT_OUT)/vendor/etc/vintf/manifest/vendor.qti.hardware.vibrator.service.xml $(TARGET_RECOVERY_ROOT_OUT)/vendor/etc/vintf/manifest/ && \
#    cd $(TARGET_RECOVERY_ROOT_OUT) && find . | sed 's|^\./||' > ramdisk-files.txt
