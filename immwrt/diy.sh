#!/bin/bash

# 修改默认IP
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# ttyd免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 设置root用户密码为password
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# 修改主机信息
echo -n "$(date +"%Y%m%d")" > package/base-files/files/etc/openwrt_version

# Git 稀疏克隆
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}


# 设置 argon 为默认主题
# sed -i 's|/luci-static/bootstrap|/luci-static/argon|g' feeds/luci/modules/luci-base/root/etc/config/luci
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci/Makefile
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci-light/Makefile

# openlist2
rm -rf feeds/luci/applications/luci-app-openlist
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

# clouddrive2
git clone https://github.com/xuanranran/openwrt-clouddrive2 package/clouddrive2

# lucky
rm -rf feeds/luci/applications/luci-app-lucky
rm -rf feeds/packages/net/lucky
git clone https://github.com/gdy666/luci-app-lucky package/lucky

# easytier 组网
git clone https://github.com/EasyTier/luci-app-easytier package/luci-app-easytier


# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# podman
git clone https://github.com/Zerogiven-OpenWRT-Packages/luci-app-podman.git package/luci-app-podman


# 晶晨宝盒 
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
# 修改更新仓库
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/wstanfeng/N1-openwrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# 取消定时任务
sed -i '/cat >>.\/etc\/crontabs\/root/,/EOF/d' package/luci-app-amlogic/root/usr/sbin/openwrt-update-amlogic
sed -i '/cat >>.\/etc\/crontabs\/root/,/EOF/d' package/luci-app-amlogic/root/usr/sbin/openwrt-update-kvm
# 标签：immwrt 版本
sed -i "s|ARMv8|ARMv8_immwrt|g" package/luci-app-amlogic/root/etc/config/amlogic

# uhttpd HTTPS 默认配置注释掉，规避 ustream-ssl 与 openssl 3.0+ 兼容性问题
# sed -i 's/^\s*list listen_https\s*/# &/g' ./package/network/services/uhttpd/files/uhttpd.config

echo "========= diy-immwrt.sh 执行完成 ========="
