# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit autotools base versionator

MY_S2_PV=$(replace_version_separator 2 - ${PV})
MY_S2_P=${PN}-${MY_S2_PV/pre1/pre-1}
MY_S_P=${MY_S2_P}-${PR/r/revision-}
MY_PV=${PV}
MY_P=${PN}-${MY_PV}

ESVN_REPO_URI="http://coot.googlecode.com/svn/trunk"

DESCRIPTION="Crystallographic Object-Oriented Toolkit for model building, completion and validation"
HOMEPAGE="http://www.biop.ox.ac.uk/coot/"
SRC_URI="
	http://www.biop.ox.ac.uk/coot/software/source/releases/${MY_P}.tar.gz
	test? ( http://www.biop.ox.ac.uk/coot/devel/greg-data.tar.gz  )"

SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
IUSE="test"

SCIDEPS="
	>=sci-libs/ccp4-libs-6.1
	>=sci-libs/clipper-20090520
	>=sci-libs/coot-data-2
	>=sci-libs/gsl-1.3
	sci-chemistry/reduce
	sci-chemistry/refmac
	sci-chemistry/probe"

XDEPS="
	gnome-base/libgnomecanvas
	gnome-base/librsvg
	virtual/glut
	>=x11-libs/gtk+-2.2
	x11-libs/gtkglext"

SCHEMEDEPS="
	dev-scheme/net-http
	dev-scheme/guile-gui
	>=dev-scheme/guile-lib-0.1.6
	dev-scheme/guile-www
	=x11-libs/guile-gtk-2.1"

RDEPEND="
	${SCIDEPS}
	${XDEPS}
	${SCHEMEDEPS}
	dev-python/pygtk
	>=dev-libs/gmp-4.2.2-r2
	>=net-misc/curl-7.19.6"
DEPEND="${RDEPEND}
	dev-lang/swig
	test? ( dev-scheme/greg )"

#S="${WORKDIR}/${MY_P}"
S="${WORKDIR}/${MY_S2_P}"

PATCHES=(
	"${FILESDIR}"/link-against-guile-gtk-properly.patch
	"${FILESDIR}"/fix-namespace-error.patch
	)

src_prepare() {
	base_src_prepare

	# Link against single-precision fftw
	sed -i \
		-e "s:lfftw:lsfftw:g" \
		-e "s:lrfftw:lsrfftw:g" \
		"${S}"/macros/clipper.m4

	# So we don't need to depend on crazy old gtk and friends
	cp "${FILESDIR}"/*.m4 "${S}"/macros/

	eautoreconf
}

src_configure() {
	# All the --with's are used to activate various parts.
	# Yes, this is broken behavior.
	econf \
		--includedir='${prefix}/include/coot' \
		--with-gtkcanvas-prefix=/usr \
		--with-clipper-prefix=/usr \
		--with-mmdb-prefix=/usr \
		--with-ssmlib-prefix=/usr \
		--with-gtkgl-prefix=/usr \
		--with-guile \
		--with-python=/usr \
		--with-guile-gtk \
		--with-gtk2 \
		--with-pygtk
}

src_compile() {
	emake || die "emake failed"

	cp "${S}"/src/coot_gtk2.py python/coot.py || die
}

src_test() {
#	emake check || die

	mkdir "${T}"/coot_test

	export COOT_STANDARD_RESIDUES="${S}/standard-residues.pdb"
	export COOT_SCHEME_DIR="${S}/scheme/"
	export COOT_RESOURCES_FILE="${S}/cootrc"
	export COOT_PIXMAPS_DIR="${S}/pixmaps"
	export COOT_DATA_DIR="${S}"
	export COOT_PYTHON_DIR="${S}/python"
	export PYTHONPATH="${COOT_PYTHON_DIR}:${PYTHONPATH}"
	export PYTHONHOME=/usr
	export CCP4_SCR="${T}"/coot_test

	export COOT_TEST_DATA_DIR="${WORKDIR}"/data/greg-data

	cat > command-line-greg.scm <<- EOF
	(use-modules (ice-9 greg))
		(set! greg-tools (list "greg-tests"))
			(set! greg-debug #t)
			(set! greg-verbose 5)
			(let ((r (greg-test-run)))
				(if r
				(coot-real-exit 0)
				(coot-real-exit 1)))
	EOF

	einfo "Running test with following paths ..."
	einfo "COOT_STANDARD_RESIDUES $COOT_STANDARD_RESIDUES"
	einfo "COOT_SCHEME_DIR $COOT_SCHEME_DIR"
	einfo "COOT_RESOURCES_FILE $COOT_RESOURCES_FILE"
	einfo "COOT_PIXMAPS_DIR $COOT_PIXMAPS_DIR"
	einfo "COOT_DATA_DIR $COOT_DATA_DIR"
	einfo "COOT_PYTHON_DIR $COOT_PYTHON_DIR"
	einfo "PYTHONPATH $PYTHONPATH"
	einfo "PYTHONHOME $PYTHONHOME"
	einfo "CCP4_SCR ${CCP4_SCR}"

	"${S}"/src/coot-real --no-graphics --script command-line-greg.scm || die
}