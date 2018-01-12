BASE_IMAGE ?= docker.io/gentoo/stage3-amd64:20171228
IMAGE ?= gentoo-builder
GENTOO_MIRRORS ?= http://mirror.leaseweb.com/gentoo/ http://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/
PORTAGE_REF ?= origin/master

BUILD_PACKAGES = dev-vcs/git app-portage/mirrorselect net-misc/curl

.PHONY: image
image: portage packages/Packages Dockerfile.build
	docker build -f Dockerfile.build -t $(IMAGE) .

Dockerfile.build: Dockerfile
	cat Dockerfile | sed "s|BASEIMAGE|$(BASE_IMAGE)|g" > Dockerfile.build

.PHONY: packages
packages: portage packages/Packages

packages/Packages: portage/.git/HEAD
	docker run --rm -it --cap-add=SYS_PTRACE -v $(PWD)/portage:/usr/portage:cached -v $(PWD)/packages:/usr/portage/packages:cached -v $(PWD)/Makefile:/Makefile $(BASE_IMAGE) sh -c 'cd / ; make emerge'
	touch packages/Packages

emerge:
	echo 'GENTOO_MIRRORS="$(GENTOO_MIRRORS)"' >> /etc/portage/make.conf
	readlink /etc/portage/make.profile | grep no-multilib 2>&1 >/dev/null && eselect profile set default/linux/amd64/17.0/no-multilib || eselect profile set default/linux/amd64/17.0
	FEATURES="buildpkg" emerge -k -j$(shell sh -c 'grep processor /proc/cpuinfo | wc -l') -e @world $(BUILD_PACKAGES)

.PHONY: portage
portage: portage/.git
	(cd portage && git fetch && git checkout $(PORTAGE_REF))

portage/.git:
	git clone https://github.com/gentoo/gentoo.git portage
