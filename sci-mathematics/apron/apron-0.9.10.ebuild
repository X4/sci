# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

inherit eutils toolchain-funcs

DESCRIPTION="The APRON library is dedicated to the static analysis of the numerical variables of a program by Abstract Interpretation"
HOMEPAGE="http://apron.cri.ensmp.fr/library/"
SRC_URI="http://apron.cri.ensmp.fr/library/${P}.tgz"

LICENSE="LGPL-2 GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="cxx doc ocaml ppl"

RDEPEND="dev-libs/gmp
		dev-libs/mpfr
		ocaml? ( >=dev-lang/ocaml-3.09
				dev-ml/camlidl 
				dev-ml/mlgmpidl )
		ppl? ( dev-libs/ppl )"
DEPEND="${RDEPEND}
		doc? ( app-text/texlive
				app-text/ghostscript-gpl 
				cxx? ( app-doc/doxygen ) )"

src_unpack() {
	unpack ${A}
	cd ${S}

	mv Makefile.config.model Makefile.config

	#fix compile process
	sed -i Makefile.config \
		-e "s/FLAGS = \\\/FLAGS += \\\/g" \
		-e "s/-O3 -DNDEBUG/-DNDEBUG/g" \
		-e "s/APRON_PREFIX = \/usr/APRON_PREFIX = \${DESTDIR}\/usr/g" \
		-e "s/MLGMPIDL_PREFIX = \/usr\/local/MLGMPIDL_PREFIX = \${DESTDIR}\/usr/g"
	
	#fix doc building process
	sed -i Makefile -e "s/; make html/; make/g"
	sed -i apronxx/doc/Doxyfile \
		-e "s/OUTPUT_DIRECTORY       = \/.*/OUTPUT_DIRECTORY       = .\//g" \
		-e "s/STRIP_FROM_PATH        = \/.*/STRIP_FROM_PATH        = .\//g"

	#fix ppl install for 32 platforms
	sed -i ppl/Makefile -e "s/libap_ppl_caml\*\./libap_ppl\*\./g"

	if [[ "$(gcc-major-version)" == "4" ]]; then
		sed -i -e "s/# HAS_LONG_DOUBLE = 1/HAS_LONG_DOUBLE = 1/g" Makefile.config
	fi
	if use !ocaml; then
		sed -i -e "s/HAS_OCAML = 1/#HAS_OCAML = 0/g" Makefile.config
	fi
	if use ppl; then
		sed -i -e "s/# HAS_PPL = 1/HAS_PPL = 1/g" Makefile.config
	fi
	if use cxx && use ppl; then
		sed -i -e "s/# HAS_CPP = 1/HAS_CPP = 1/g" Makefile.config
	else
		die "USE flag 'cxx' needs USE flag 'ppl' set"
	fi

	epatch "${FILESDIR}/${P}-pkgrid_manager.patch"
}

src_compile() {
	#damn crappy Makefile
	emake || emake || die "emake failed"

	if use doc; then
		emake doc || "emake doc failed"
	fi
}

src_install(){
	emake install DESTDIR="${D}" || die "emake install failed"
	dodoc AUTHORS Changes COPYING README

	if use doc; then
		dodoc apron/apron.pdf
		if use ocaml; then
			dodoc mlapronidl/mlapronidl.pdf
		fi
		if use cxx; then
			mv apronxx/doc/latex/refman.pdf apronxx/apronxx.pdf
			dodoc ./apronxx/apronxx.pdf
		fi
	fi
}
