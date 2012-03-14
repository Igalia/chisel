# vim:ft=make
#
# Makefile
# Adrian Perez, 2011-12-24 19:49
# Chisel is distributed under the terms of the GNU GPLv2 license.
#
#

include Makefile.rules
include Makefile.config

CHSL_CONFDEFS := $(patsubst %,-DCHSL_%=1,$(CHSL_CONFIG))
CPPFLAGS      += $(CHSL_CONFDEFS) -DCHSL_LIBDIR=\"$(PREFIX)/share/chisel\"
CFLAGS        += -Wall -W -g -O0

$(foreach option,$(CHSL_CONFIG),$(eval CHSL_CONFIG_$$(option) := 1))

ifeq ($(CHSL_CONFIG_READLINE),1)
EXTRA_LDLIBS += -lreadline
endif

liblua_SRCS  := lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c  \
	lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c \
	ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lbitlib.c  \
	lcorolib.c ldblib.c liolib.c lmathlib.c loslib.c lstrlib.c ltablib.c  \
	loadlib.c linit.c
liblua_OBJS  := $(patsubst %.c,lua/%.o,$(liblua_SRCS))

# We want the extras that Lua can use from Unix-like systems
$(liblua_OBJS): CPPFLAGS += -DLUA_USE_POSIX

filters := texttochisel
drivers := chisel-ppd

symlink_BIN      := $(filters) $(drivers)
install_BIN      := chisel
install_BIN_PATH := $(PREFIX)/bin
install_BIN_MODE := 755

chisel_SRCS := src/chisel.c src/fs.c

ifeq ($(CHSL_CONFIG_CUPS),1)
chisel_SRCS += src/cups.c

CUPS_CFLAGS  := $(shell cups-config --cflags)
CUPS_LDFLAGS := $(shell cups-config --ldflags)
CUPS_LDLIBS  := $(shell cups-config --libs)
CUPS_BINDIR  := $(shell cups-config --serverbin)
CUPS_DATADIR := $(shell cups-config --datadir)

symlinks_CUPS_DRIVERS        := $(drivers)
symlinks_CUPS_DRIVERS_PATH   := $(CUPS_BINDIR)/driver
symlinks_CUPS_DRIVERS_TARGET := $(PREFIX)/bin/chisel

symlinks_CUPS_FILTERS        := $(filters)
symlinks_CUPS_FILTERS_PATH   := $(CUPS_BINDIR)/filter
symlinks_CUPS_FILTERS_TARGET := $(PREFIX)/bin/chisel

symlinks_CUPS_MIMETYPES        := chisel.types
symlinks_CUPS_MIMETYPES_PATH   := $(CUPS_DATADIR)/mime
symlinks_CUPS_MIMETYPES_TARGET := $(PREFIX)/share/chisel/data/mime.types

symlinks_CUPS_MIMECONVS        := chisel.convs
symlinks_CUPS_MIMECONVS_PATH   := $(CUPS_DATADIR)/mime
symlinks_CUPS_MIMECONVS_TARGET := $(PREFIX)/share/chisel/data/mime.convs

$(eval $(call symlinks-target,CUPS_DRIVERS))
$(eval $(call symlinks-target,CUPS_FILTERS))
$(eval $(call symlinks-target,CUPS_MIMETYPES))
$(eval $(call symlinks-target,CUPS_MIMECONVS))
endif

chisel_OBJS := $(patsubst %.c,%.o,$(chisel_SRCS))

install_LIB          := $(wildcard src/*.lua)
install_LIB_PATH     := $(PREFIX)/share/chisel
install_SCRIPTS      := $(wildcard src/scripts/*.lua)
install_SCRIPTS_PATH := $(install_LIB_PATH)/scripts

all: $(install_BIN) $(filters) $(drivers)

chisel: CFLAGS  += $(CUPS_CFLAGS)
chisel: LDLIBS  += $(CUPS_LDLIBS) $(EXTRA_LDLIBS) -lm
chisel: LDFLAGS += $(CUPS_LDFLAGS)
chisel: $(chisel_OBJS) $(liblua_OBJS)

# If the configuration changes, all object files should be rebuilt
$(chisel_OBJS): Makefile.config

$(filters) $(drivers): chisel
	$(cmd_print) SYMLINKS .
	for i in $(filters) $(drivers) ; do \
		ln -sf chisel $$i ; \
	done

.NOTPARALLEL: $(filters) $(drivers)

install: install-data

install-data:
	$(cmd_print) INSTALL "[data]"
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/chisel/data
	cp -r src/data/* $(DESTDIR)$(PREFIX)/share/chisel/data/
	find $(DESTDIR)$(PREFIX)/share/chisel/data -type d | xargs chmod 755
	find $(DESTDIR)$(PREFIX)/share/chisel/data -type f | xargs chmod 644

.PHONY: install-data


clean:
	$(RM) $(chisel_OBJS)
	$(RM) $(liblua_OBJS)
	$(RM) chisel
	$(RM) $(filters) $(drivers)

$(eval $(call install-target,BIN))
$(eval $(call install-target,LIB))
$(eval $(call install-target,SCRIPTS))

