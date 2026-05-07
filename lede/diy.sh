#!/bin/bash

# 修改默认IP
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 修改主机信息
echo -n "$(date +"%Y%m%d")" > package/base-files/files/etc/openwrt_version

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 更改默认主题
# 1. 克隆 argon 主题
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 2. 修改 luci-base 将 argon 设置为默认主题 (最关键的一步)
sed -i 's|/luci-static/bootstrap|/luci-static/argon|g' feeds/luci/modules/luci-base/root/etc/config/luci

# 3. 修改 Makefile 替换默认的依赖，避免 bootstrap 被选中
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci-light/Makefile

#openlist
rm -rf feeds/luci/applications/luci-app-openlist2
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

#clouddrive2
rm -rf feeds/luci/applications/luci-app-clouddrive2
git clone https://github.com/xuanranran/openwrt-clouddrive2 package/clouddrive2

# mosdns
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# lucky
rm -rf feeds/luci/applications/luci-app-lucky
rm -rf feeds/packages/net/lucky
git clone https://github.com/gdy666/luci-app-lucky package/lucky

# easytier组网
git clone https://github.com/EasyTier/luci-app-easytier package/luci-app-easytier

# adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome


# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages

# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci

# luci-app-openclash
rm -rf feeds/luci/applications/luci-app-openclash
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# 晶晨宝盒
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
# 修改更新仓库
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/wstanfeng/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# coremark跑分定时清除
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*
# 取消定时任务
sed -i '/cat >>.\/etc\/crontabs\/root/,/EOF/d' package/luci-app-amlogic/root/usr/sbin/openwrt-update-amlogic
sed -i '/cat >>.\/etc\/crontabs\/root/,/EOF/d' package/luci-app-amlogic/root/usr/sbin/openwrt-update-kvm
# sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
sed -i "s|ARMv8|ARMv8_lean|g" package/luci-app-amlogic/root/etc/config/amlogic

# 修复 armv8 设备 xfsprogs 报错
#sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile


# 修改 Makefile
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

#adguard-core.sh
#mkdir -p files/usr/bin/AdGuardHome
#AGH_CORE=$(curl -sL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep /AdGuardHome_linux_amd64 | awk -F '"' '{print $4}')
#wget -qO- $AGH_CORE | tar xOvz > files/usr/bin/AdGuardHome/AdGuardHome
#chmod +x files/usr/bin/AdGuardHome/AdGuardHome


#   操作：在编译时直接注释掉uhttpd的HTTPS默认配置，uhttpd因ustream-ssl与openssl 3.0+的兼容性问题而导致的启动失败
sed -i 's/^\s*list listen_https\s*/# &/g' ./package/network/services/uhttpd/files/uhttpd.config
#echo "========= 在编译时直接注释掉uhttpd的HTTPS默认配置  ========="
