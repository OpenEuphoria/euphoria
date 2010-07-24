
include Makefile.eu

EU_VERSION =4.0
EU_BASE_DIR =../..
DEBIAN_VERSION =1
EU_ALL_FILES = \
	source/be_alloc.c \
	source/be_callc.c \
	source/be_decompress.c \
	source/be_execute.c \
	source/be_inline.c \
	source/be_machine.c \
	source/be_main.c \
	source/be_pcre.c \
	source/be_rterror.c \
	source/be_runtime.c \
	source/be_socket.c \
	source/be_symtab.c \
	source/be_syncolor.c \
	source/be_task.c \
	source/be_w.c \
	source/version.h \
	source/int.ex \
	source/ec.ex \
	source/eu.ex \
	source/backend.ex \
	source/bind.ex \
	source/backend.e \
	source/block.e \
	source/buildsys.e \
	source/c_decl.e \
	source/cominit.e \
	source/common.e \
	source/compile.e \
	source/compress.e \
	source/c_out.e \
	source/emit.e \
	source/error.e \
	source/execute.e \
	source/fwdref.e \
	source/global.e \
	source/il.e \
	source/inline.e \
	source/intinit.e \
	source/keylist.e \
	source/main.e \
	source/mode.e \
	source/msgtext.e \
	source/opnames.e \
	source/parser.e \
	source/pathopen.e \
	source/platform.e \
	source/preproc.e \
	source/reswords.e \
	source/rev.e \
	source/revget.ex \
	source/scanner.e \
	source/scinot.e \
	source/shift.e \
	source/symtab.e \
	source/traninit.e \
	source/tranplat.e \
	source/alldefs.h \
	source/execute.h  \
	source/opnames.h  \
	source/reswords.h \
	source/global.h \
	source/redef.h \
	source/symtab.h \
	source/Makefile \
	source/Makefile.gnu \
	source/configure \
	source/dis.ex \
	source/dis.e \
	source/dot.e \
	source/dox.e \
	source/std.ex \
	source/coverage.e \
	source/coverage.ex \
	source/be_alloc.h \
	source/be_callc.h \
	source/be_decompress.h \
	source/be_execute.h \
	source/be_inline.h \
	source/be_machine.h \
	source/be_main.h \
	source/be_pcre.h \
	source/be_rterror.h \
	source/be_runtime.h \
	source/be_socket.h \
	source/be_symtab.h \
	source/be_syncolor.h \
	source/be_task.h \
	source/be_w.h \
	source/object.h

EU_DIRS = include \
	include/std/ \
	include/std/net \
	include/std/unix \
	include/std/win32 \
	include/euphoria \
	html \
	doc \
	demo \
	tutorial \
	demo/bench \
	demo/linux \
	demo/langwar \
	demo/langwar/Linux

EU_BIN_FILES = ed.ex \
	ascii.ex \
	buildcpdb.ex \
	bugreport.ex \
	ed.ex \
	eutest \
	eprint.ex \
	guru.ex \
	key.ex \
	lines.ex \
	search.ex \
	where.ex

BUILD_DIRS = intobj/ \
	transobj/ \
	libobj/ \
	backobj/ \
	backobj/back/ \
	intobj/back/ \
	transobj/back/ \
	libobj/back/

euphoria-$(EU_VERSION)-$(DEBIAN_VERSION)_i386 : update
	cd $(DEB_SOURCE_DIR) && dpkg-buildpackage
# 	cd $(DEB_SOURCE_DIR) && fakeroot debian/rules binary

binclean :
	for d in $(BUILD_DIRS); \
	do \
	    -rm "$$d"/*o; \
	done
	-rm eui euc eu.a eub

clean : 
	-rm -rf $(DEB_SOURCE_DIR)
	-rm *deb
	-rm *gz

DEB_SOURCE_DIR = euphoria-$(EU_VERSION)

update :
	-mkdir -p $(DEB_SOURCE_DIR)/source/pcre
	cd $(EU_BASE_DIR)/source && ./configure && make distclean && ./configure && make svn_rev
	for file in $(EU_ALL_FILES); \
	do \
	    cp $(EU_BASE_DIR)/"$$file" $(DEB_SOURCE_DIR)/"$$file"; \
	done
	cp -r $(EU_BASE_DIR)/source/pcre/* $(DEB_SOURCE_DIR)/source/pcre/
	-for dir in $(EU_DIRS); \
	do \
	    mkdir -p $(DEB_SOURCE_DIR)/"$$dir"; \
	    cp $(EU_BASE_DIR)/"$$dir"/* $(DEB_SOURCE_DIR)/"$$dir"; \
	done
	-mkdir $(DEB_SOURCE_DIR)/bin
	for file in $(EU_BIN_FILES); \
	do \
	    cp $(EU_BASE_DIR)/bin/"$$file" $(DEB_SOURCE_DIR)/bin; \
	done
	-mkdir -p $(DEB_SOURCE_DIR)/source/codepage
	cp $(EU_BASE_DIR)/source/codepage/*ecp $(DEB_SOURCE_DIR)/source/codepage
	-mkdir -p $(DEB_SOURCE_DIR)/docs/html/images
	cp $(EU_BASE_DIR)/docs/*.af $(DEB_SOURCE_DIR)/docs
	cp $(EU_BASE_DIR)/docs/*.txt $(DEB_SOURCE_DIR)/docs
	cp $(EU_BASE_DIR)/*.txt $(DEB_SOURCE_DIR)
	cp $(EU_BASE_DIR)/docs/*.html $(DEB_SOURCE_DIR)/docs
	cp $(EU_BASE_DIR)/docs/*.css $(DEB_SOURCE_DIR)/docs
	cp $(EU_BASE_DIR)/docs/*.js $(DEB_SOURCE_DIR)/docs
	cp $(EU_BASE_DIR)/docs/html/images/* $(DEB_SOURCE_DIR)/docs/html/images
	cp Makefile.fake $(DEB_SOURCE_DIR)/Makefile
# 	cd $(DEB_SOURCE_DIR)/source && ./configure
# 	cd $(DEB_SOURCE_DIR)/source && $(MAKE)  source
# 	-rm *.gz
	-rm -r $(DEB_SOURCE_DIR)/debian
# 	tar -czf euphoria-$(EU_VERSION).tar.gz $(DEB_SOURCE_DIR)
	-mkdir $(DEB_SOURCE_DIR)/debian
	-cp rules $(DEB_SOURCE_DIR)/debian
	-cp postinst $(DEB_SOURCE_DIR)/debian
	-cp prerm $(DEB_SOURCE_DIR)/debian
	-cp $(EU_BASE_DIR)/docs/man/*.1 $(DEB_SOURCE_DIR)/debian
	-sed s/%arch%/$(ARCH)/ control > $(DEB_SOURCE_DIR)/debian/control
	-cp changelog $(DEB_SOURCE_DIR)/debian
	-cp copyright $(DEB_SOURCE_DIR)/debian
	-rm $(DEB_SOURCE_DIR)/*stamp
	-cp euphoria-manual $(DEB_SOURCE_DIR)/debian
	-echo 7 > $(DEB_SOURCE_DIR)/debian/compat
	

dh-make : update
	@cd $(DEB_SOURCE_DIR) && dh_make -e matthewwalkerlewis@gmail.com --createorig
	@-rm $(DEB_SOURCE_DIR)/debian/emacsen*
	@cp rules $(DEB_SOURCE_DIR)/debian
	@cp postinst $(DEB_SOURCE_DIR)/debian;
	@cp ../doc/*.1 $(DEB_SOURCE_DIR)/debian;
	@cp control $(DEB_SOURCE_DIR)/debian;



.PHONY : clean binclean update dh-make