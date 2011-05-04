!ifndef DEBUG
DEBUG = 0
!endif
!ifndef TCLVER
TCLVER=8.5
!endif
!ifndef TCLDIR
TCLDIR=\opt\tcl$(TCLVER)
!endif

!ifndef MACHINE
!ifndef CPU
CPU = IX86
!endif
MACHINE = $(CPU)
!endif

CC      =cl -nologo
LD      =link -nologo
RM      =del /q/f >NUL

!if $(DEBUG)
CFLAGS  =-W4 -MDd -Od -Zi -DDEBUG
LDFLAGS =-debug
!else
CFLAGS  =-W3 -MD -O2 -Zi -D_NDEBUG
LDFLAGS =-debug
!endif

CFLAGS =-DTCL_VERSION_MINIMUM=\"$(TCLVER)\"
V=$(TCLVER:.=)

INC     =-I. -I$(TCLDIR)\include
LIBS    =-libpath:$(TCLDIR)\lib tclstub$V.lib tkstub$V.lib

!if "$(MACHINE)" == "AMD64"
OUT_DIR  =win32-x86_64
LDFLAGS = $(LDFLAGS) -machine:AMD64
LIBS    = $(LIBS) bufferoverflowU.lib
!else
OUT_DIR =win32-ix86
!endif

TMP_DIR = $(OUT_DIR)

all: setup $(OUT_DIR)\imgscale.dll pkgIndex.tcl

setup:
	@if not exist $(OUT_DIR) mkdir $(OUT_DIR)
	@if not exist $(TMP_DIR) mkdir $(TMP_DIR)

$(OUT_DIR)\imgscale.dll: $(TMP_DIR)\imgscale.obj
	@$(LD) -dll -out:$@ $(LDFLAGS) $** $(LIBS)
	@$(RM) $(@:.dll=.exp) $(@:.dll=.ilk)

pkgIndex.tcl:
	@echo. ^ ^ Creating pkgIndex file.
	@type << >$@
package ifneeded imgscale 1.0 \
    "package require platform
load \[file join [list $$dir] \[platform::generic\]\
          imgscale[info sharedlibextension]\]"
<<

{}.c{$(TMP_DIR)}.obj::
	@$(CC) $(CFLAGS) $(INC) -DUSE_TCL_STUBS -DUSE_TK_STUBS -Fo$(TMP_DIR)\ -c @<<
$<
<<

clean:
	-@rmdir /s/q $(OUT_DIR) >NUL
	-@$(RM) vc*.pdb
	-@$(RM) pkgIndex.tcl

.PHONY: clean setup
