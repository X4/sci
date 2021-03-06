# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit webapp eutils perl-module

[ "$PV" == "9999" ] && inherit git-2

DESCRIPTION="EST assembly+annotation: a perl-based analysis pipeline including php-based web interface"
HOMEPAGE="http://cichlid.umd.edu/est2uni/download.php"
if [ "$PV" == "9999" ]; then
	EGIT_REPO_URI="git://gitolite@bioinfo.comav.upv.es:2203/est2uni.git"
	KEYWORDS=""
else
	SRC_URI="http://cichlid.umd.edu/est2uni/est2uni.tar.gz
		ftp://ftp.ncbi.nih.gov/pub/UniVec/UniVec
		ftp://ftp.ncbi.nih.gov/pub/UniVec/UniVec_Core
		http://www.geneontology.org/ontology/gene_ontology.obo
		http://www.geneontology.org/doc/GO.terms_and_ids"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	sci-biology/lucy
	sci-biology/cap3-bin
	sci-biology/estscan
	<sci-biology/hmmer-3.0
	sci-biology/phred
	sci-biology/seqclean
	sci-biology/repeatmasker
	sci-biology/tgicl
	sci-biology/ncbi-tools
	sci-biology/bioperl
	sci-biology/exonerate
	dev-perl/go-perl
	www-servers/apache
	>=dev-db/mysql-4.1
	<dev-lang/php-5.3"

S="${WORKDIR}"/est2uni

src_prepare(){
	for f in "${FILESDIR}"/9999-*.pm.patch; do
		cd perl; epatch $f || die "Failed to apply patch $f"
	done
	cd ../php || die "Failed to chdir to ../php"
	epatch "${FILESDIR}"/configuration.php.patch || die "Failed to apply config patch for VHOSTS setup"
}

src_compile(){
	"$(tc-getCC)" external_software/sputnik/sputnik.c -o external_software/sputnik/sputnik
}

src_install(){
	mkdir -p "${D}"/opt/est2uni
	mv external_software/sputnik/sputnik "${D}"/opt/est2uni || die

	chmod a+rx perl/*.pl perl/*.pm || die
	mv perl/* "${D}"/opt/est2uni || die

	doenvd "${FILESDIR}"/99est2uni || die

	mkdir -p "${D}"/usr/share/webapps/"${PN}"/"${PV}"/htdocs
	cp -r php/* "${D}"/usr/share/webapps/"${PN}"/"${PV}"/htdocs || die

	mkdir -p "${D}"/opt/est2uni/test_data || die
	mv test_data/* "${D}"/opt/est2uni/test_data || die
	# mkdir -p "${D}"/usr/share/"${PN}" || die
	# mv test_data "${D}"/usr/share/"${PN}" || die
	perl-module_src_install || die

	webapp_src_preinst
	webapp_postinst_txt en "${S}"/README
	webapp_src_install
	# mkdir -p /var/www/localhost/htdocs/est2uni/est2uni/temp
	# mkdir -p /var/www/localhost/htdocs/est2uni/est2uni/blast

	# cp "${DISTDIR}"/UniVec_Core "${DISTDIR}"/UniVec "${D}"/usr/share/ncbi/data/ || die

	einfo "Please follow the pipeline installation and web configuration docs at"
	einfo "http://cichlid.umd.edu/est2uni/install.php"
	einfo ""
	einfo "Example changes to the config file are in ${FILESDIR}/configuration.php.patch"
	einfo ""
	einfo "BEWARE the software is not maintained anymore by upstream but I do not"
	einfo "know any better available (replaced by ngs_backbone which has no web"
	einfo "interface yet). Consider using latest svn checkout instead of 0.27"
	einfo "release from 2007 or so."
	einfo "Possible fixes and stuff to read:"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-January/000069.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-March/000103.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-March/000101.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-April/000135.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-April/000131.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-February/000070.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-April/000129.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-April/000128.html"
	einfo "https://listas.upv.es/pipermail/est2uni/2008-May/000139.html"
	einfo ""
	einfo "Current code is at http://bioinf.comav.upv.es/git///?p=est2uni;a=summary"
}

pkg_postinst(){
	webapp_pkg_postinst || die "webapp_pkg_postinst failed"
}
