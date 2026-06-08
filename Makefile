include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-qmodem-failover
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKGARCH:=all
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-qmodem-failover
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  # REVISI 1: Membersihkan teks Mandarin pada Judul Menu LuCI
  TITLE:=QMODEM Failover - Auto Switch Wired WAN to Mobile Network
  DEPENDS:=+luci-base +kmod-usb-net +kmod-usb-net-rndis \
           +kmod-usb-net-cdc-ether +uci +curl +ip-full +ubus
  PKGARCH:=all
  URL:=https://github.com/ansun1714/luci-app-qmodem-failover
endef

define Package/luci-app-qmodem-failover/description
  Auto-switches to QMODEM LTE when wired WAN fails.
  Auto-switches back on recovery. Switch time under 15 seconds.
  Universal architecture (x86_64/arm/aarch64/mipsel).
endef

define Package/luci-app-qmodem-failover/conffiles
/etc/config/qmodem_failover
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src     $(PKG_BUILD_DIR)/
	$(CP) ./luasrc  $(PKG_BUILD_DIR)/
	$(CP) ./htdocs  $(PKG_BUILD_DIR)/
	$(CP) ./po      $(PKG_BUILD_DIR)/
endef

define Build/Compile
	# REVISI 2: Memaksa compiler OpenWrt memproses berkas .po Bahasa Inggris Anda menjadi format biner .lmo LuCI
	mkdir -p $(PKG_BUILD_DIR)/po/bin
	$(foreach po,$(wildcard ./po/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/po/bin/$(patsubst %.po,%.lmo,$(notdir $(po))); \
	)
endef

define Package/luci-app-qmodem-failover/install
	$(INSTALL_DIR) $(1)/usr/lib/qmodem-failover
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/qmodem-failover.sh \
	               $(1)/usr/lib/qmodem-failover/qmodem-failover.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/wan-checker.sh \
	               $(1)/usr/lib/qmodem-failover/wan-checker.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/switcher.sh \
	               $(1)/usr/lib/qmodem-failover/switcher.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/notify.sh \
	               $(1)/usr/lib/qmodem-failover/notify.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/qmodem-failover.init \
	               $(1)/etc/init.d/qmodem-failover
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/src/qmodem-failover.config \
	                $(1)/etc/config/qmodem_failover
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/controller/qmodem_failover.lua \
	                $(1)/usr/lib/lua/luci/controller/qmodem_failover.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/model/cbi/qmodem_failover.lua \
	                $(1)/usr/lib/lua/luci/model/cbi/qmodem_failover.lua
	$(INSTALL_DIR) $(1)/htdocs/luci-static/qmodem_failover
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/htdocs/luci-static/qmodem_failover/status.js \
	                $(1)/htdocs/luci-static/qmodem_failover/status.js
	
	# REVISI 3: Menyalin hasil konversi bahasa biner (.lmo) ke direktori i18n OpenWrt agar terbaca di Web LuCI
	$(INSTALL_DIR) $(1)/usr/share/luci/i18n
	[ -d $(PKG_BUILD_DIR)/po/bin ] && $(CP) $(PKG_BUILD_DIR)/po/bin/*.lmo $(1)/usr/share/luci/i18n/ || true
endef

define Package/luci-app-qmodem-failover/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
/etc/init.d/qmodem-failover enable  2>/dev/null || true
/etc/init.d/qmodem-failover start   2>/dev/null || true
rm -f /tmp/luci-indexcache /tmp/luci-modulecache* 2>/dev/null || true
exit 0
endef

define Package/luci-app-qmodem-failover/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
/etc/init.d/qmodem-failover stop    2>/dev/null || true
/etc/init.d/qmodem-failover disable 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,luci-app-qmodem-failover))
