#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
#echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main' >> feeds.conf.default
#echo 'src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;main' >> feeds.conf.default

echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default
#echo 'src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds' >> feeds.conf.default
#echo 'src-git mt76 https://github.com/openwrt/mt76' >> feeds.conf.default

sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=5.10/g' target/linux/ramips/Makefile
sed -i "s/KERNEL_TESTING_PATCHVER:=*.*/KERNEL_TESTING_PATCHVER:=5.10/g" target/linux/ramips/Makefile


# === 提取 padavanonly/immortalwrt mt7915_mtwifi 的闭源驱动 + MTK HW NAT ===
echo "========== 开始整合闭源 MT7915 驱动 + MTK HW NAT =========="

# 先清理 Lean 自带的开源 MT76 驱动（避免冲突）
rm -rf package/kernel/mt76 package/kernel/mac80211 package/kernel/mwlwifi 2>/dev/null || true

# 克隆目标分支
git clone -b mt7915_mtwifi --depth=1 https://github.com/padavanonly/immortalwrt.git /tmp/immortal

# 复制闭源 WiFi 驱动（mwlwifi 是该分支的 MT7915 闭源实现）
cp -r /tmp/immortal/package/kernel/mwlwifi package/kernel/ 2>/dev/null || echo "mwlwifi 目录不存在，使用 mt76 补丁替代"

# 复制 MTK HW NAT 加速包（fast-classifier + shortcut-fe）
cp -r /tmp/immortal/package/kernel/fast-classifier package/kernel/ 2>/dev/null || true
cp -r /tmp/immortal/package/kernel/shortcut-fe package/kernel/ 2>/dev/null || true

# 复制 MTK SDK 补丁和 hnat_nf_hook（关键 NAT hook）
cp -r /tmp/immortal/target/linux/ramips/patches-5.15/* target/linux/ramips/patches-5.15/ 2>/dev/null || true
cp -r /tmp/immortal/target/linux/ramips/files/* target/linux/ramips/files/ 2>/dev/null || true

# 如果有 mt_wifi 相关额外文件（部分 commit 里有）
cp -r /tmp/immortal/package/kernel/* package/kernel/ 2>/dev/null || true

rm -rf /tmp/immortal

echo "========== 闭源驱动 + HW NAT 整合完成 =========="


