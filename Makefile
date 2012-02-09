# vim:ft=make
#
# Makefile
# Adrian Perez, 2011-12-24 19:49
# Chisel is distributed under the terms of the GNU GPLv2 license.
#
#

include Makefile.rules
include Makefile.config

CHSL_DEVICES  := $(patsubst %,-DCHSL_%,$(CHSL_DEVICES))
CHSL_CONFDEFS := $(patsubst %,-DCHSL_%=1,$(CHSL_CONFIG))
CPPFLAGS      += $(CHSL_DEVICES) $(CHSL_CONFDEFS)
CFLAGS        += -Wall -W -g -O0

$(foreach option,$(CHSL_CONFIG),$(eval CHSL_CONFIG_$$(option) := 1))

ifeq ($(CHSL_CONFIG_CUPS),1)
CUPS_CFLAGS  := $(shell cups-config --cflags)
CUPS_LDFLAGS := $(shell cups-config --ldflags)
CUPS_LDLIBS  := $(shell cups-config --libs)
CUPS_BINDIR  := $(shell cups-config --serverbin)
endif

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

install_FILTERS      := chisel
install_FILTERS_MODE := 755

ifeq ($(CHSL_CONFIG_CUPS),1)
install_FILTERS_PATH := $(CUPS_BINDIR)/filter
else
install_FILTERS_PATH := $(PREFIX)/lib/chisel
endif

all: $(install_FILTERS)

chisel: CFLAGS  += $(CUPS_CFLAGS)
chisel: LDLIBS  += $(CUPS_LDLIBS) $(EXTRA_LDLIBS)
chisel: LDFLAGS += $(CUPS_LDFLAGS)
chisel: $(chisel_OBJS) $(liblua_OBJS)

# If the configuration changes, all object files should be rebuilt
$(chisel_OBJS): Makefile.config

clean:
	$(RM) $(chisel_OBJS)
	$(RM) $(liblua_OBJS)
	$(RM) chisel

$(eval $(call install-target,FILTERS))


