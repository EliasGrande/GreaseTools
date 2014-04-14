# package info
PACKAGE = greasetools

# filenames
name_srcbin = $(PACKAGE).sh
name_srcman = $(PACKAGE).1
name_bin    = $(PACKAGE)
name_man    = $(PACKAGE).1.gz
name_yui    = yuicompressor.jar

# source
srcdir  = .
src_bin = $(srcdir)/$(name_srcbin)
src_man = $(srcdir)/$(name_srcman)

# build
builddir  = ./build
build_bin = $(builddir)/$(name_bin)
build_man = $(builddir)/$(name_man)
build_yui = $(builddir)/$(name_yui)
BUILD_ALL = $(build_bin) $(build_man) $(build_yui)

# install (prefix)
PREFIX = /usr/local
dest_lib = $(DESTDIR)$(PREFIX)/lib
dest_bin = $(DESTDIR)$(PREFIX)/bin
dest_man = $(DESTDIR)$(PREFIX)/share/man/man1
DEST_ALL = $(dest_lib) $(dest_bin) $(dest_man)

# install (files)
install_lib = $(dest_lib)/$(PACKAGE)
install_bin = $(dest_bin)/$(name_bin)
install_man = $(dest_man)/$(name_man)
INSTALL_ALL = $(install_lib) $(install_bin) $(install_man)

.PHONY: all clean install uninstall

all: $(BUILD_ALL)

$(builddir):
	mkdir -p $(builddir)

$(build_bin): $(builddir) $(src_bin)
	cp -f $(src_bin) $(build_bin)
	chmod +x $(build_bin)

$(build_man): $(builddir) $(src_man)
	rm -f $(build_man)
	gzip -c $(src_man) > $(build_man)

$(build_yui): $(build_bin)
	test -f "$(build_yui)" || $(build_bin) yui-update

clean:
	rm -Rf $(builddir)
	sh $(src_bin) clean-trash -r

install: $(BUILD_ALL) uninstall
	mkdir -p $(DEST_ALL)
	cp -R $(builddir) $(install_lib)
	chmod +x $(install_lib)/$(name_bin)
	ln -s $(install_lib)/$(name_bin) $(install_bin)
	ln -s $(install_lib)/$(name_man) $(install_man)

uninstall:
	rm -Rf $(INSTALL_ALL)
	for i in $(INSTALL_ALL); do rmdir -p "`dirname "$$i"`" 2>&1|: ;done



























