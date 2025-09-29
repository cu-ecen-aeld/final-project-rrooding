################################################################################
# opensprinkler-pi
################################################################################

OPENSPRINKLER_PI_VERSION = 49b0e8a31b8ee7cf2ae4fa7dc6c6b4bcd54c8836
OPENSPRINKLER_PI_SITE = https://github.com/OpenSprinkler/OpenSprinkler-Firmware.git
OPENSPRINKLER_PI_SITE_METHOD = git
OPENSPRINKLER_PI_LICENSE = GPL-3.0+
OPENSPRINKLER_PI_LICENSE_FILES = LICENSE.txt
OPENSPRINKLER_PI_GIT_SUBMODULES = YES
OPENSPRINKLER_PI_DEPENDENCIES = mosquitto libgpiod i2c-tools

define OPENSPRINKLER_PI_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define OPENSPRINKLER_PI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/OpenSprinkler $(TARGET_DIR)/usr/bin/opensprinkler
	if [ -d $(@D)/html ]; then \
		$(INSTALL) -d $(TARGET_DIR)/usr/share/opensprinkler/html; \
		cp -a $(@D)/html/* $(TARGET_DIR)/usr/share/opensprinkler/html/; \
	fi
	# Install systemd service
	$(INSTALL) -D -m 0644 $(OPENSPRINKLER_PI_PKGDIR)/opensprinkler.service \
		$(TARGET_DIR)/usr/lib/systemd/system/opensprinkler.service
	# Install init script for non-systemd systems
	$(INSTALL) -D -m 0755 $(OPENSPRINKLER_PI_PKGDIR)/S50opensprinkler \
		$(TARGET_DIR)/etc/init.d/S50opensprinkler
	# Enable service at boot
	$(INSTALL) -d $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf /usr/lib/systemd/system/opensprinkler.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/opensprinkler.service
endef

$(eval $(generic-package))


