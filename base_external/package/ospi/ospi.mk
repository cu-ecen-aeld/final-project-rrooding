
OSPI_VERSION = 49b0e8a
OSPI_SITE = https://github.com/OpenSprinkler/OpenSprinkler-Firmware.git
OSPI_SITE_METHOD = git
OSPI_GIT_SUBMODULES = YES

OSPI_DEPENDENCIES = mosquitto libgpiod openssl i2c-tools usbmount

define OSPI_BUILD_CMDS
	git -C $(@D) submodule update --init --recursive
	$(TARGET_CXX) -o $(@D)/OpenSprinkler \
		-DOSPI -DLIBGPIOD -DSMTP_OPENSSL -std=gnu++14 \
		-Wall -include string.h -include cstdint \
		-I$(@D) \
		-I$(@D)/external/TinyWebsockets/tiny_websockets_lib/include \
		-I$(@D)/external/OpenThings-Framework-Firmware-Library \
		$(@D)/main.cpp \
		$(@D)/OpenSprinkler.cpp \
		$(@D)/notifier.cpp \
		$(@D)/program.cpp \
		$(@D)/opensprinkler_server.cpp \
		$(@D)/utils.cpp \
		$(@D)/weather.cpp \
		$(@D)/gpio.cpp \
		$(@D)/mqtt.cpp \
		$(@D)/smtp.c \
		$(@D)/RCSwitch.cpp \
		$(shell find $(@D)/external/TinyWebsockets/tiny_websockets_lib/src -name '*.cpp') \
		$(shell find $(@D)/external/OpenThings-Framework-Firmware-Library -name '*.cpp') \
		-lpthread -lmosquitto -lssl -lcrypto -li2c -lgpiod
endef

# Install the binary
define OSPI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/OpenSprinkler \
		$(TARGET_DIR)/usr/bin/OpenSprinkler
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/ospi/ospi.init \
		$(TARGET_DIR)/etc/init.d/S99ospi
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/ospi/ospi-usb-config.sh \
		$(TARGET_DIR)/usr/local/bin/ospi-usb-config.sh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/ospi/ospi-backup-service.sh \
		$(TARGET_DIR)/usr/local/bin/ospi-backup-service.sh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/ospi/ospi-config-monitor.sh \
		$(TARGET_DIR)/usr/local/bin/ospi-config-monitor.sh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/ospi/ospi-config-validator.sh \
		$(TARGET_DIR)/usr/local/bin/ospi-config-validator.sh
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL)/package/ospi/99-ospi-usb.rules \
		$(TARGET_DIR)/lib/udev/rules.d/99-ospi-usb.rules
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/local/OpenSprinkler/html
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/local/OpenSprinkler/backup
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/var/log
	cp -r $(@D)/html/* $(TARGET_DIR)/usr/local/OpenSprinkler/html/

endef

$(eval $(generic-package))

