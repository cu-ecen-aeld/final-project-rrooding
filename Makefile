BR2_EXTERNAL := $(CURDIR)/packages
BUILDROOT := $(CURDIR)/buildroot
export BR2_EXTERNAL

.DEFAULT_GOAL := all

.PHONY: all menuconfig nconfig xconfig savedefconfig defconfig clean help

all:
	$(MAKE) -C $(BUILDROOT)

menuconfig:
	$(MAKE) -C $(BUILDROOT) menuconfig

nconfig:
	$(MAKE) -C $(BUILDROOT) nconfig

xconfig:
	$(MAKE) -C $(BUILDROOT) xconfig

savedefconfig:
	$(MAKE) -C $(BUILDROOT) savedefconfig

defconfig:
	$(MAKE) -C $(BUILDROOT) defconfig

clean:
	$(MAKE) -C $(BUILDROOT) clean

help:
	@echo "Using BR2_EXTERNAL=$${BR2_EXTERNAL}"
	$(MAKE) -C $(BUILDROOT) help | sed '1,2d'


