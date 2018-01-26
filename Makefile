IMAGE ?= gentoo-builder

INSTALL_PACKAGES = dev-vcs/git net-misc/curl app-portage/layman

.PHONY: image
image:
	docker build -f Dockerfile -t $(IMAGE) .

digest:
	docker run -it --volumes-from portage -v $(PWD)/files/usr/local/portage:/usr/local/portage --rm docker.io/gentoo/stage3-amd64-hardened ebuild /usr/local/portage/dev-libs/openssl/openssl-1.0.2n-r1.ebuild manifest
