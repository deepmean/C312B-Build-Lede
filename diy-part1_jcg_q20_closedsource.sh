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

echo "========== 开始整合 Heleguo 闭源 MT7915 驱动 =========="

# 删除 coolsnowwolf 内置的旧版 mt（避免冲突）
rm -rf package/lean/mt

# 克隆 Heleguo 的 mtk 包（只取 package/mtk 目录）
git clone https://github.com/Heleguo/lede.git tmp_heleguo --depth=1 --branch=master

# 复制 luci-app-mtwifi 和 mt7915（会生成 mt_wifi 包）
cp -r tmp_heleguo/package/mtk/* package/

# 清理临时文件
rm -rf tmp_heleguo

echo "Heleguo 闭源驱动整合完成！（package/mt7915 + luci-app-mtwifi 已替换）"