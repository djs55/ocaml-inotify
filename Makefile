OCAMLC = ocamlc
OCAMLOPT = ocamlopt

OCAMLOPTFLAGS =

OCAMLABI := $(shell ocamlc -version)
OCAMLLIBDIR := $(shell ocamlc -where)
OCAMLDESTDIR ?= $(DESTDIR)/$(OCAMLLIBDIR)

OCAML_TEST_INC = -I `ocamlfind query oUnit`
OCAML_TEST_LIB = `ocamlfind query oUnit`/oUnit.cmxa

LIBS = inotify.cmi inotify.cmxa inotify.cma
PROGRAMS = test.inotify

PKG_NAME = inotify

all: $(LIBS)

all-byte: inotify.cmi inotify.cma

all-opt: inotify.cmi inotify.cmxa inotify.cma

bins: $(PROGRAMS)

libs: $(LIBS)

inotify.cmxa: libinotify_stubs.a inotify_stubs.a inotify.cmx
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -a -cclib -linotify_stubs -o $@ inotify.cmx

inotify.cma: libinotify_stubs.a inotify.cmi inotify.cmo
	$(OCAMLC) -a -dllib dllinotify_stubs.so -cclib -linotify_stubs -o $@ inotify.cmo

inotify_stubs.a: inotify_stubs.o
	ocamlmklib -o inotify_stubs $+

libinotify_stubs.a: inotify_stubs.o
	ar rcs $@ $+
	ocamlmklib -o inotify_stubs $+

%.cmo: %.ml
	$(OCAMLC) -c -o $@ $<

%.cmi: %.mli
	$(OCAMLC) -c -o $@ $<

%.cmx: %.ml
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c -o $@ $<

%.o: %.c
	$(OCAMLC) -c -o $@ $<

OCAMLFIND_INSTALL_FLAGS ?= -destdir $(OCAMLDESTDIR) -ldconf ignore

.PHONY: install
install: $(LIBS)
	mkdir -p $(OCAMLDESTDIR)
	ocamlfind install $(OCAMLFIND_INSTALL_FLAGS) $(PKG_NAME) META inotify.cmi inotify.mli inotify.cma inotify.cmxa *.a *.so *.cmx

install-byte:
	mkdir -p $(OCAMLDESTDIR)
	ocamlfind install $(OCAMLFIND_INSTALL_FLAGS) $(PKG_NAME) META inotify.cmi inotify.mli inotify.cma *.a *.so

install-opt:
	mkdir -p $(OCAMLDESTDIR)
	ocamlfind install $(OCAMLFIND_INSTALL_FLAGS) $(PKG_NAME) META inotify.cmi inotify.mli inotify.cma inotify.cmxa *.a *.so *.cmx

uninstall:
	ocamlfind remove $(OCAMLFIND_INSTALL_FLAGS) $(PKG_NAME)

test.inotify: inotify.cmxa test.inotify.ml
	$(OCAMLOPT) -o $@ unix.cmxa -cclib -L. $+

RPM_SOURCEDIR?=/usr/src/redhat/SOURCES
RPM_RELEASE=$(call git rev-list HEAD | wc -l)
.PHONY: version.inc 
version.inc:
	echo -n 'RPM_RELEASE=' > $@
	git rev-list HEAD | wc -l >> $@
include version.inc
ocaml-inotify.spec: ocaml-inotify.spec.in version.inc
	sed -e 's/@RPM_RELEASE@/$(RPM_RELEASE)/g' < $< > $@

srpm: ocaml-inotify.spec version.inc
	git archive --prefix=ocaml-inotify-0/ --format=tar HEAD | bzip2 -z > $(RPM_SOURCEDIR)/ocaml-inotify.tar.bz2
	rpmbuild -bs --nodeps ocaml-inotify.spec


clean:
	-rm -f *.o *.so *.a *.cmo *.cmi *.cma *.cmx *.cmxa $(LIBS) $(PROGRAMS)
