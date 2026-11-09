#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 小米平板 6 Pro（liuqin）产品定义
#
# 构建：lunch twrp_liuqin-eng && mka recoveryimage
#

DEVICE_PATH := device/xiaomi/liuqin

# 设备配置
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# 机型标识
# 这一段直接决定 recovery 里 build.prop 的值：
#   ro.product.device      <- PRODUCT_DEVICE
#   ro.product.name        <- PRODUCT_NAME
#   ro.product.model       <- PRODUCT_MODEL
#   ro.product.brand       <- PRODUCT_BRAND
#
# ⚠ 本树与 yudi（小米平板 6 Max 14）同为 taro 平台，但**设备代号必须严格区分**：
#   本树是 liuqin（小米平板 6 Pro），yudi 是另一台机器。
#   两者镜像不可互刷；PRODUCT_DEVICE 一旦写错，OTA 断言、脚本判断、备份目录命名
#   （/data/media/0/TWRP/BACKUPS/<serial>）、Magisk 模块作用域都会跟着错。
#   本树的 liuqin 标识来自 liuqin 原树（xccxxcys/device_xiaomi_liuqin-TWRP-OF），
#   未经真机 getprop 复核。上机后请确认：
#     adb shell getprop ro.product.device   # 应为 liuqin
#     adb shell getprop ro.product.model    # 应为 Xiaomi Pad 6 Pro
PRODUCT_DEVICE := liuqin
PRODUCT_NAME := twrp_liuqin
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Xiaomi Pad 6 Pro
PRODUCT_MANUFACTURER := Xiaomi
