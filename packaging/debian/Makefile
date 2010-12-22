
include Makefile.eu

euphoria : update
	echo TARGET: $@
	cd $(DEB_SOURCE_DIR) && dpkg-buildpackage -nc
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

DEB_SOURCE_DIR = euphoria

copy-files :

source :

update :
	hg archive $(DEB_SOURCE_DIR)
	cp Makefile.fake $(DEB_SOURCE_DIR)/Makefile
	-rm -r $(DEB_SOURCE_DIR)/debian
	-mkdir $(DEB_SOURCE_DIR)/debian
	-cp rules $(DEB_SOURCE_DIR)/debian
	-cp postinst $(DEB_SOURCE_DIR)/debian
	-cp prerm $(DEB_SOURCE_DIR)/debian
	-cp $(DEB_SOURCE_DIR)/docs/man/*.1 $(DEB_SOURCE_DIR)/debian
	-sed s/%arch%/$(ARCH)/ control > $(DEB_SOURCE_DIR)/debian/control
	-cp changelog $(DEB_SOURCE_DIR)/debian
	-cp copyright $(DEB_SOURCE_DIR)/debian
	-rm $(DEB_SOURCE_DIR)/*stamp
	-cp euphoria-manual $(DEB_SOURCE_DIR)/debian
	-echo 7 > $(DEB_SOURCE_DIR)/debian/compat
	cd $(DEB_SOURCE_DIR)/source && ./configure --prefix /usr $(CONFIG)
	echo TARGET: UPDATE - MAKING SOURCE
	$(MAKE) -C $(DEB_SOURCE_DIR)/source source
	

dh-make : update
	@cd $(DEB_SOURCE_DIR) && dh_make -e mattlewis@openeuphoria.org --createorig
	@-rm $(DEB_SOURCE_DIR)/debian/emacsen*
	@cp rules $(DEB_SOURCE_DIR)/debian CONFIG="$(CONFIG)"
	@cp postinst $(DEB_SOURCE_DIR)/debian;
	@cp ../doc/*.1 $(DEB_SOURCE_DIR)/debian;
	@cp control $(DEB_SOURCE_DIR)/debian;



.PHONY : clean binclean update dh-make