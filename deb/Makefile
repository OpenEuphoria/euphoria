
EU_VERSION =4.0
EU_BASE_DIR =..
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
	source/be_symtab.c \
	source/be_syncolor.c \
	source/be_task.c \
	source/be_w.c \
	source/int.ex \
	source/ec.ex \
	source/backend.ex \
	source/bind.ex \
	source/backend.e \
	source/c_decl.e \
	source/cominit.e \
	source/common.e \
	source/compile.e \
	source/compress.e \
	source/c_out.e \
	source/emit.e \
	source/error.e \
	source/execute.e \
	source/global.e \
	source/il.e \
	source/intinit.e \
	source/keylist.e \
	source/main.e \
	source/mode.e \
	source/opnames.e \
	source/parser.e \
	source/pathopen.e \
	source/reswords.e \
	source/rev.e \
	source/revget.ex \
	source/scanner.e \
	source/scientific.e \
	source/symtab.e \
	source/traninit.e \
	source/tranplat.e \
	source/alldefs.h \
	source/execute.h  \
	source/opnames.h  \
	source/reswords.h \
	source/alloc.h \
	source/global.h \
	source/redef.h \
	source/symtab.h \
	source/Makefile \
	source/eushroud \
	source/eubind \
	source/configure

EU_DIRS = include html doc demo tutorial demo/bench demo/linux demo/langwar demo/langwar/Linux
EU_BIN_FILES = ed.ex ascii.ex eprint.ex guru.ex key.ex keywords.e \
	lines.ex search.ex syncolor.e where.ex
BUILD_DIRS = intobj/ transobj/ libobj/ backobj/ backobj/back/ intobj/back/ transobj/back/ libobj/back/
euphoria-$(EU_VERSION)-$(DEBIAN_VERSION)_i386 : update
	cd $(DEB_SOURCE_DIR) && fakeroot debian/rules binary

binclean :
	for d in $(BUILD_DIRS); \
	do \
	    -rm "$$d"/*o; \
	done
	-rm exu ecu ecu.a eubackend

clean : 
	-rm -rf $(DEB_SOURCE_DIR)
	-rm *deb
	-rm *gz

DEB_SOURCE_DIR = euphoria-$(EU_VERSION)

update :
	cd $(EU_BASE_DIR)/source && ./configure && make distclean && ./configure && make svn_rev
	-mkdir -p $(DEB_SOURCE_DIR)/source/pcre
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
	cp Makefile.fake $(DEB_SOURCE_DIR)/Makefile
	cd $(DEB_SOURCE_DIR)/source && ./configure
	cd $(DEB_SOURCE_DIR)/source && $(MAKE)  source
	-rm *.gz
	-rm -r $(DEB_SOURCE_DIR)/debian
	tar -czf euphoria-$(EU_VERSION).tar.gz $(DEB_SOURCE_DIR)
	-mkdir $(DEB_SOURCE_DIR)/debian
	-cp rules $(DEB_SOURCE_DIR)/debian
	-cp postinst $(DEB_SOURCE_DIR)/debian
	-cp $(EU_BASE_DIR)/htx/*.1 $(DEB_SOURCE_DIR)/debian
	-cp control $(DEB_SOURCE_DIR)/debian
	-cp changelog $(DEB_SOURCE_DIR)/debian
	-cp copyright $(DEB_SOURCE_DIR)/debian
	-rm $(DEB_SOURCE_DIR)/*stamp

dh-make : update
	@cd $(DEB_SOURCE_DIR) && dh_make -e matthewwalkerlewis@gmail.com --createorig
	@-rm $(DEB_SOURCE_DIR)/debian/emacsen*
	@cp rules $(DEB_SOURCE_DIR)/debian
	@cp postinst $(DEB_SOURCE_DIR)/debian;
	@cp ../htx/*.1 $(DEB_SOURCE_DIR)/debian;
	@cp control $(DEB_SOURCE_DIR)/debian;



.PHONY : clean binclean update dh-make