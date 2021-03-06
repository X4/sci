# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

OASIS_BUILD_DOCS=1
inherit oasis

DESCRIPTION="BLAS/LAPACK interface for OCaml"
HOMEPAGE="http://forge.ocamlcore.org/projects/lacaml"
SRC_URI="http://forge.ocamlcore.org/frs/download.php/806/${P}.tar.gz"

LICENSE="LGPL-2.1-linking-exception"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

RDEPEND="virtual/blas
	virtual/lapack"
DEPEND="${DEPEND}
	dev-util/pkgconfig"

DOCS=( "README.txt" "Changelog" )

src_prepare() {
	cclib="$(pkg-config --libs blas lapack)"
	cclib="[$(echo $cclib|sed -e 's/\(-[a-z0-9]*\) /\"\1\"\;/g' -e \
	's/\(-[a-z0-9]*\)$/\"\1\"/')]"
	sed -i "s/cclib = \[\]/cclib = ${cclib}/" setup.conf
	#would like to do the below, but doesn't work from ebuild
	#oasis_configure_opts="--override conf_cclib $(pkg-config --libs blas atlas)
}
