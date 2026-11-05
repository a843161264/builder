################################################################################
#
# ap6pcm03-device
#
################################################################################

AP6PCM03_DEVICE_VERSION = 1.0
AP6PCM03_DEVICE_SITE_METHOD = local
AP6PCM03_DEVICE_SITE = $(BR2_EXTERNAL_GENERAL_PATH)/package/ap6pcm03-device
AP6PCM03_DEVICE_LICENSE = MIT

define AP6PCM03_DEVICE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/files/customizer.sh $(TARGET_DIR)/usr/share/openipc/customizer.sh
	$(INSTALL) -D -m 0644 $(@D)/files/gpio.conf $(TARGET_DIR)/usr/share/openipc/gpio.conf
	$(INSTALL) -D -m 0644 $(@D)/files/atbm_txpwer_dcxo_cfg.txt $(TARGET_DIR)/usr/share/atbm60xx_conf/atbm_txpwer_dcxo_cfg.txt
	$(INSTALL) -D -m 0644 $(@D)/files/set_rate_power.txt $(TARGET_DIR)/usr/share/atbm60xx_conf/set_rate_power.txt
endef

$(eval $(generic-package))
