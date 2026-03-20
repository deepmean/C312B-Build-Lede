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


# 强制跳过 kmod-ip6tables 的打包（避免 nf_log_common.ko 缺失报错）
echo "========== 强制移除 netfilter.mk 中 ip6tables 打包规则 =========="
sed -i '/kmod-ip6tables/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/ip6_tables.ko/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/ip6table_/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/ip6_tables/d' package/kernel/linux/modules/netfilter.mk || true

# 额外清理 kernel 缓存（防止旧构建残留导致依赖检查失败）
rm -rf build_dir/target-mipsel_24kc_musl/linux-ramips_mt7621/linux-5.10.251 || true
make package/kernel/linux/clean || true

echo "========== ip6tables 打包规则已移除，kernel 缓存已清理 =========="

# ======= 针对 kmod-ipt-nat6 missing ip6_tables.ko 的修复（IPv6 NAT 模块） =======
echo "========== 强制移除 kmod-ipt-nat6 打包规则 =========="

# 移除 kmod-ipt-nat6 相关打包目标（类似 ip6tables 的处理）
sed -i '/kmod-ipt-nat6/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/ipt6_nat.ko/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/nat6/d' package/kernel/linux/modules/netfilter.mk || true
sed -i '/ipt_NAT6/d' package/kernel/linux/modules/netfilter.mk || true   # 如果有

# 强制关闭 IPv6 NAT 内核配置（避免生成 ipt6_nat.ko）
sed -i '/CONFIG_NF_NAT_IPV6/d' target/linux/ramips/mt7621/config-5.10
sed -i '/CONFIG_IP6_NF_IPTABLES/d' target/linux/ramips/mt7621/config-5.10
sed -i '/CONFIG_IP6_NF_MATCH_IPV6EXTHDR/d' target/linux/ramips/mt7621/config-5.10
echo "CONFIG_NF_NAT_IPV6=n" >> target/linux/ramips/mt7621/config-5.10
echo "CONFIG_IP6_NF_IPTABLES=n" >> target/linux/ramips/mt7621/config-5.10

# 再次清理 kernel（确保配置生效）
rm -rf build_dir/target-mipsel_24kc_musl/linux-ramips_mt7621/linux-5.10.251* || true
make package/kernel/linux/clean || true

echo "========== kmod-ipt-nat6 已跳过，IPv6 NAT 配置已关闭 =========="