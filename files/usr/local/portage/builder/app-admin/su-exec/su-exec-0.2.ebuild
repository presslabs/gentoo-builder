# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
DESCRIPTION="switch user and group id and exec"
HOMEPAGE="https://github.com/ncopa/su-exec"
SRC_URI="https://github.com/ncopa/${PN}/archive/v${PV}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"

src_compile() {
	emake
}

src_install() {
	exeinto /usr/sbin
	doexe su-exec
}
