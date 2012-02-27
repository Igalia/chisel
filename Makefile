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

chisel_SRCS  := $(wildcard src/*.c)
chisel_OBJS  := $(patsubst %.c,%.o,$(chisel_SRCS))

filters := texttochisel
drivers := chisel-ppd

symlink_BIN      := $(filters) $(drivers)
install_BIN      := chisel
install_BIN_PATH := $(PREFIX)/bin
install_BIN_MODE := 755

ifeq ($(CHSL_CONFIG_CUPS),1)
CUPS_CFLAGS  := $(shell cups-config --cflags)
CUPS_LDFLAGS := $(shell cups-config --ldflags)
CUPS_LDLIBS  := $(shell cups-config --libs)
CUPS_BINDIR  := $(shell cups-config --serverbin)

symlinks_CUPS_DRIVERS        := $(drivers)
symlinks_CUPS_DRIVERS_PATH   := $(CUPS_BINDIR)/driver
symlinks_CUPS_DRIVERS_TARGET := $(PREFIX)/bin/chisel

symlinks_CUPS_FILTERS        := $(filters)
symlinks_CUPS_FILTERS_PATH   := $(CUPS_BINDIR)/filter
symlinks_CUPS_FILTERS_TARGET := $(PREFIX)/bin/chisel

$(eval $(call symlinks-target,CUPS_DRIVERS))
$(eval $(call symlinks-target,CUPS_FILTERS))
endif


install_SCRIPTS      := $(wildcard src/*.lua)
install_SCRIPTS_PATH := $(PREFIX)/share/chisel


all: $(install_BIN) $(filters) $(drivers)

chisel: CFLAGS  += $(CUPS_CFLAGS)
chisel: LDLIBS  += $(CUPS_LDLIBS) $(EXTRA_LDLIBS)
chisel: LDFLAGS += $(CUPS_LDFLAGS)
chisel: $(chisel_OBJS) $(liblua_OBJS)

# If the configuration changes, all object files should be rebuilt
$(chisel_OBJS): Makefile.config

$(filters) $(drivers): chisel
	$(cmd_print) SYMLINKS .
	for i in $(filters) $(drivers) ; do \
		ln -sf chisel $$i ; \
	done


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
$(eval $(call install-target,SCRIPTS))

