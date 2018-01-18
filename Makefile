BASE_IMAGE ?= docker.io/gentoo/stage3-amd64-hardened-nomultilib:20180115
IMAGE ?= gentoo-builder
GENTOO_MIRRORS ?= http://mirror.leaseweb.com/gentoo/ http://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/
PORTAGE_BINHOST ?= https://storage.googleapis.com/gentoo.presslabs.net/packages/latest

INSTALL_PACKAGES = dev-vcs/git app-portage/mirrorselect net-misc/curl app-portage/layman

ifeq ($(shell uname -s),Darwin)  # Mac OS X
	NUM_JOBS := $(shell sysctl -n hw.ncpu)
else
	NUM_JOBS := $(shell sh -c 'grep processor /proc/cpuinfo | wc -l')
endif
EMERGE = emerge -j$(NUM_JOBS) --getbinpkg --usepkg

MAKE_EMERGE_CMD = make emerge && quickpkg --include-unmodified-config y "*/*"

ifndef CI
	MAKE_PACKAGES_CMD := docker run --rm -it --privileged -v $(PWD)/portage:/usr/portage:cached -v $(PWD)/packages:/usr/portage/packages:cached -v $(PWD)/Makefile:/Makefile -w / $(BASE_IMAGE) sh -c '$(MAKE_EMERGE_CMD)'
else
	MAKE_PACKAGES_CMD := $(MAKE_EMERGE_CMD)
endif

.PHONY: image
image: packages/Packages Dockerfile.build
	docker build --squash -f Dockerfile.build -t $(IMAGE) .

Dockerfile.build: Dockerfile
	cat Dockerfile | \
		sed "s|BASEIMAGE|$(BASE_IMAGE)|g" | \
		sed "s|PORTAGE_REF|PORTAGE_REF=$(shell cd portage && git rev-parse --verify HEAD)|g" \
	> Dockerfile.build

.PHONY: packages
packages: packages/Packages

packages/Packages: .git/modules/portage/HEAD
	$(MAKE_PACKAGES_CMD)

emerge:
	echo 'GENTOO_MIRRORS="$(GENTOO_MIRRORS)"' >> /etc/portage/make.conf
	echo 'PORTAGE_BINHOST="$(PORTAGE_BINHOST)"' >> /etc/portage/make.conf
	echo 'USE="gdbm berkdb" # hardened profile starts with empty USE flags, but stage3 is built with them so we reduce the number of rebuilds' >> /etc/portage/make.conf
	echo 'sys-devel/gcc pgo' > /etc/portage/package.use/gcc
	echo 'dev-lang/python pgo ' > /etc/portage/package.use/python
	echo 'app-portage/layman sync-plugin-portage git' > /etc/portage/package.use/layman
	readlink /etc/portage/make.profile | grep no-multilib 2>&1 >/dev/null && eselect profile set default/linux/amd64/17.0/no-multilib/hardened || eselect profile set default/linux/amd64/17.0/hardened
	$(EMERGE) -q --info
	$(EMERGE) --pretend -uDU --with-bdeps=y @world
	$(EMERGE) -q        -uDU --with-bdeps=y @world
	$(EMERGE) -q --depclean
	$(EMERGE) --pretend $(INSTALL_PACKAGES)
	$(EMERGE) -q $(INSTALL_PACKAGES)

clean:
	rm -rf packages
	rm -rf Dockerfile.build
