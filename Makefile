IMAGE ?= gentoo-builder

INSTALL_PACKAGES = dev-vcs/git net-misc/curl app-portage/layman
NUM_JOBS := $(shell sh -c 'grep processor /proc/cpuinfo | wc -l')
EMERGE = emerge -j$(NUM_JOBS) --getbinpkg --usepkg

.PHONY: image
image:
	docker build -f Dockerfile -t $(IMAGE) .

emerge:
	$(EMERGE) -q --info
	$(EMERGE) --pretend -uDU --with-bdeps=y @world
	$(EMERGE) -q        -uDU --with-bdeps=y @world
	$(EMERGE) -q --depclean
	$(EMERGE) --pretend $(INSTALL_PACKAGES)
	$(EMERGE) -q $(INSTALL_PACKAGES)
