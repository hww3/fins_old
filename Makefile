#
#  Makefile stub for generating module reference documentation.
#


RUNPIKE=/usr/local/pike/7.8.352/bin/pike
SYSTEM_DOC_PATH=/usr/local/pike/7.8.352/doc
AUTODOC_SRC_IN=lib
CORE_AUTODOC_PATH=/usr/local/pike/7.8.352/doc/autodoc.xml
FULL_SRCDIR=/Users/hww3/devel/fins

refdoc:
	@test -d refdoc || mkdir refdoc

refdoc/modref: refdoc
	@test -d refdoc/modref || mkdir refdoc/modref

plib/doc_build/images: plib/doc_build
	@test -d plib/doc_build/images || mkdir plib/doc_build/images

plib/doc_build: plib
	@test -d plib/doc_build || mkdir plib/doc_build

plib/modules: plib
	@test -d plib/modules || mkdir plib/modules

plib/refdoc: plib
	@test -d plib/refdoc || mkdir plib/refdoc

plib:
	@test -d plib || mkdir plib


extract_autodoc:  plib/refdoc plib/doc_build/images
	$(RUNPIKE) -x extract_autodoc --builddir=plib/refdoc --srcdir=plib/modules
	if test "X$(AUTODOC_SRC_IN)" != "X"; then \
	$(RUNPIKE) -x extract_autodoc --builddir=plib/refdoc --srcdir=$(AUTODOC_SRC_IN); \
	fi

join_autodoc: extract_autodoc
	$(RUNPIKE) -x join_autodoc --quiet --post-process  "plib/autodoc.xml" "$(CORE_AUTODOC_PATH)" "plib/refdoc"

modref: join_autodoc modref.xml
	cd $(SYSTEM_DOC_PATH)/src && $(MAKE) $(MAKE_FLAGS) BUILDDIR="$(FULL_SRCDIR)/plib" DESTDIR="$(SYSTEM_DOC_PATH)" modref

module_join_autodoc: extract_autodoc refdoc/modref
	$(RUNPIKE) -x join_autodoc --quiet --post-process  "plib/autodoc.xml" "plib/refdoc"

module_modref: module_join_autodoc module_modref.xml
	cd $(SYSTEM_DOC_PATH)/src && $(MAKE) $(MAKE_FLAGS) BUILDDIR="$(FULL_SRCDIR)/plib" DESTDIR="$(FULL_SRCDIR)/refdoc/" module_modref

modref.xml: plib/autodoc.xml $(SYSTEM_DOC_PATH)/src/structure/modref.xml
	$(RUNPIKE) -x assemble_autodoc $(SYSTEM_DOC_PATH)/src/structure/modref.xml \
	plib/autodoc.xml >plib/modref.xml

module_modref.xml: plib/autodoc.xml $(SYSTEM_DOC_PATH)/src/structure/module_modref.xml
	$(RUNPIKE) -x assemble_autodoc $(SYSTEM_DOC_PATH)/src/structure/module_modref.xml \
	plib/autodoc.xml >plib/module_modref.xml

