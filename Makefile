#!/usr/bin/make -f
# Set environment variables

# this makefile follows the below conventions for variables denoting files and directories
# all directory names must end with a terminal '/' character
# file names never end in terminal '/' character


#===================================================
SHELL = /bin/bash

# set this variable to any value to make shared libraries (cleaning existing build files may be necessary)
SHARED =
ifdef SHARED
SHARED = true
endif

#===================================================
# Compile commands
#===================================================
CXX        = g++
CXXLIBS    =
CXXFLAGS   = -g -O -Wall
RPATH      =
ifneq ($(strip $(filter install install-bin,$(MAKECMDGOALS))),)
RPATH    = $(DESTDIR)$(libdir)
else
RPATH    = $(buildir)
endif
AR       = ar
ARFLAGS  = crs
#======================================================
#Internal cflags
#======================================================
#error detection
ifdef SHARED
ifneq ($(strip $(filter -pie,$(CXXFLAGS))),)
$(error -pie is for executable only do mot specify it for CXXFLAGS)
endif
endif
#setting variables
override cxxflags            := $(filter-out -pic -fpic -Fpic -FPIC -fPIC -pie -fpie -Fpie -FPIE -fpie,$(CXXFLAGS))
override cxxflags_shared     := $(filter-out -fpie -Fpie -FPIE -fPIE,$(CXXFLAGS))
ifeq ($(strip $(filter -fpic -Fpic -FPIC -fPIC,$(cxxflags_shared))),)
override cxxflags_shared     += -fpic
endif
override cxxflags_shared_lib := $(cflags_shared) --shared
#======================================================
# Build Directories
#======================================================
override srcdir     = src/
override buildir    = build/
#======================================================
# Install directories
#======================================================
DESTDIR     =
prefix      = /usr/local/
override exec_prefix = $(prefix)
override bindir      = $(exec_prefix)/bin/
override datarootdir = $(prefix)/share/
override datadir     = $(datarootdir)
override libdir      = $(prefix)/lib/
#=======================================================
prog_name = main
#=======================================================
override INSTALL          = install -D -p
override INSTALL_PROGRAM  = $(INSTALL) -m 755
override INSTALL_DATA     = $(INSTALL) -m 644
#=======================================================
#Other files
#=======================================================
override libconfigfile  = config.mk
override mainconfig    = libconfig.mk
#updating of installstamp instucts to recompile the executable
override installstamp  = installstamp.txt
#=======================================================
# DO NOT MODIFY VARIABLES!
#====================================================
# Source and target objects
#====================================================
#Source files
override CXX1SRCS      = $(wildcard $(srcdir)*/*.cpp)
override CXX2SRCS      = $(wildcard $(srcdir)*/*.cxx)
override CXX3SRCS      = $(wildcard $(srcdir)*/*.cc)
override SRCS          = $(CXX1SRCS) $(CXX2SRCS) $(CXX3SRCS)
override MAIN_CXX1SRCS = $(wildcard $(srcdir)*.cpp)
override MAIN_CXX2SRCS = $(wildcard $(srcdir)*.cxx)
override MAIN_CXX3SRCS = $(wildcard $(srcdir)*.cc)
override MAIN_SRCS     = $(MAIN_CXX1SRCS) $(MAIN_CXX2SRCS) $(MAIN_CXX3SRCS)
override SRCDIRS       = $(sort $(dir $(SRCS)))
#build objects
override BUILD_DIRS    = $(addprefix $(buildir),$(subst $(srcdir),,$(SRCDIRS)))
override OBJS          = $(patsubst %.cpp,%.cpp.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%.cxx.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%.cc.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
override OBJS_S        = $(patsubst %.cpp,%-shared.cpp.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%-shared.cxx.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%-shared.cc.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
#make files for build objects
override MKS           = $(patsubst %.cpp,%cpp.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%cxx.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%cc.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
override MKS_S         = $(patsubst %.cpp,%-sharedcpp.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%-sharedcxx.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%-sharedcc.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
override MKSLIBS       = $(addprefix $(buildir),$(addsuffix .mk,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(BUILD_DIRS))))))
#Library config files
override LIBCONFS      = $(addsuffix $(libconfigfile),$(SRCDIRS))
override GLOBALCONFS   = $(srcdir)$(mainconfig)
#config varaiables
override CXXLIBS_DEP :=
ifeq ($(strip $(filter generate% remove%,$(MAKECMDGOALS))),)
# read config variables
-include $(LIBCONFS) $(GLOBALCONFS)
endif
#set the libraries to build and their makefiles
ifdef SHARED
override LIBS = $(addprefix $(buildir),$(addsuffix .so,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(BUILD_DIRS))))))
else
ifndef SHAREDCOSTOM
override LIBS = $(addprefix $(buildir),$(addsuffix .a,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(BUILD_DIRS))))))
endif
endif
#set  C libraries to use while makeing executables
ifndef CXXLIBS
override CXXLIBS += -L./$(buildir) $(addprefix -l,$(subst /,,$(subst $(buildir),,$(BUILD_DIRS))))
endif
override CXXLIBS += $(sort $(CXXLIBS_DEP))
#=====================================================
# Exporting variables
export CXX CXXFLAGS INCLUDES RPATH CXXLIBS
export INSTALL INSTALL_DATA INSTALL_PROGRAM
export buildir srcdir
export prog_name
export SHARED
#=====================================================

build: $(buildir)$(prog_name)
.PHONY:build

.DEFUALT_GOAL:build

install: install-bin install-libs
.PHONY:install

install-bin: build
	@[[ -f "$(DESTDIR)$(bindir)$(prog_name)" ]] && { echo -e "\e[31mError\e[0m Refusing to ovewrite existing file \"$(DESTDIR)$(bindir)$(prog_name)\"" ; exit 23; } || true;
	$(INSTALL_PROGRAM) "$(buildir)$(prog_name)" -t "$(DESTDIR)$(bindir)"
.PHONY: install-bin

install-libs: LIB_STATIC = $(filter %.a,$(LIBS))
install-libs: LIB_SHARED = $(filter %.so,$(LIBS))
install-libs: libs = $(addprefix "$(DESTDIR)$(libdir)",$(notdir $(LIBS)))
install-libs: build-libs
	@for file in $(libs); do \
		[[ -f "$$file" ]] && { echo -e "\e[31mError\e[0m Refusing to overwrite existing file \"$$file\""; exit 23; } || true; \
	done
ifndef SHARED
ifdef SHAREDCOSTOM
	$(INSTALL_PROGRAM) $(LIB_SHARED) -t "$(DESTDIR)$(libdir)"
	$(INSTALL_DATA) $(LIB_STATIC) -t "$(DESTDIR)$(libdir)"
else
	$(INSTALL_DATA) $(LIBS) -t "$(DESTDIR)$(libdir)"
endif
else
	$(INSTALL_PROGRAM) $(LIBS) -t "$(DESTDIR)$(libdir)"
endif
.PHONY: install-libs

debug:
	@echo -e "\e[35mBuild Directories \e[0m: $(BUILD_DIRS)"
	@echo -e "\e[35mSource Directories\e[0m: $(SRCDIRS)"
	@echo -e "\e[35mLibconf Files     \e[0m: $(LIBCONFS)"
	@echo -e "\e[35mGlobalconfig File \e[0m: $(GLOBALCONFS)"
	@echo -e "\e[35mLibraries Files   \e[0m: $(LIBS)"
	@echo    "#-------------------------------------------#"
	@echo -e "\e[35mSource Library Files       \e[0m: $(SRCS)"
	@echo -e "\e[35mSource Executable Files    \e[0m: $(MAIN_SRCS)"
	@echo -e "\e[35mMake Object Files          \e[0m: $(MKS)"
	@echo -e "\e[35mMake Shared-Object Files   \e[0m: $(MKS_S)"
	@echo -e "\e[35mMake Library Files         \e[0m: $(MKSLIBS)"
	@echo -e "\e[35mObject Files               \e[0m: $(OBJS)"
	@echo -e "\e[35mObject Shared Files        \e[0m: $(OBJS_S)"
	@echo -e "\e[35mSHARED     \e[0m: $(SHARED)"
	@echo -e "\e[35mCMD Goals  \e[0m: $(MAKECMDGOALS)"
	@echo -e "\e[35mMakeflags  \e[0m: $(MAKEFLAGS)"
	@echo -e "\e[35mCxxlibs    \e[0m: $(CXXLIBS)"
	@echo -e "\e[35mCxxlibs DEP\e[0m: $(CLIBS_DEP)"
	@echo -e "\e[35mCXXFLAGS   \e[0m: $(CFLAGS)"
	@echo -e "\e[35mComputed cxxflags        \e[0m: $(cxxflags)"
	@echo -e "\e[35mComputed cxxflags shared \e[0m: $(cxxflags_shared)"
	@echo -e "\e[35mComputed cxxflags library\e[0m: $(cxxflags_shared_lib)"
	@echo -e "\e[35mTest Var  \e[0m: $(prog_name)"
	@echo    "#-------------------------------------------#"
	$(MAKE) -e -C "$(CURDIR)" -f Makefile2 $(MAKEFLAGS) $(if $(SHAREDCOSTOM),SHARED="true") debug
.PHONY:debug

help:
	@echo "The follwing targets may be given..."
	@echo -e "\t...install"
	@echo -e "\t...install-bin"
	@echo -e "\t...install-libs"
	@echo -e "\t...build*"
	@echo -e "\t...build-libs"
	@echo -e "\t...build-obj"
	@echo -e "\t...build-obj-static"
	@echo -e "\t...build-obj-shared"
	@echo -e "\t...uninstall"
	@echo -e "\t...uninstall-bin"
	@echo -e "\t...uninstall-libs"
	@echo -e "\t...clean"
	@echo -e "\t...clean-all"
	@echo "Other options"
	@echo -e "\t...debug"
	@echo -e "\t...help"
	@echo -e "\t...create-makes"
	@echo -e "\t...create-makes-libs"
	@echo -e "\t...create-makes-static"
	@echo -e "\t...create-makes-shared"
	@echo "configuration file options"
	@echo -e "\t...generate-config-files"
	@echo -e "\t...generate-libdependancy-config-files"
	@echo -e "\t...generate-testlibconf-file"
	@echo -e "\t...remove-config-files"
	@echo -e "\t...remove-libdependancy-config-files"
	@echo -e "\t...remove-testlibconf-file"
.PHONY: help

build-libs: $(LIBS)
.PHONY: build-libs

build-obj: build-obj-static build-obj-shared ;
.PHONY: build-obj

build-obj-static: $(OBJS)
.PHONY:build-obj-static

build-obj-shared: $(OBJS_S)
.PHONY:build-obj-shared

#phony to go in install mode
installmode:
	@rm -f $(buildir)$(installstamp)
.PHONY: installmode

#=====================================================
ifneq ($(strip $(filter install%,$(MAKECMDGOALS))),)
export INSTALLMODE = true
$(buildir)$(prog_name): installmode
endif
export COMPILESTAMP = $(LIBS) $(buildir)$(installstamp)
$(buildir)$(prog_name): $(MAIN_SRCS) $(LIBS) $(buildir)$(installstamp)
	$(MAKE) -e -C "$(CURDIR)" -f Makefile2 $(MAKEFLAGS) $(if $(SHAREDCOSTOM),SHARED="true") build

$(buildir)$(installstamp):
	touch $@
#============

#disable builtin rules
.SUFFIXES:

#makefiles to build object code
$(buildir)%cpp.mk : $(srcdir)%.cpp
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*.cpp.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%cxx.mk : $(srcdir)%.cxx
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*.cxx.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%cc.mk : $(srcdir)%.cc
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*.cc.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

#makefiles to build position independant object code
$(buildir)%-sharedcpp.mk : $(srcdir)%.cpp
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*-shared.cpp.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags_shared) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%-sharedcxx.mk : $(srcdir)%.cxx
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*-shared.cxx.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags_shared) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%-sharedcc.mk : $(srcdir)%.cc
	@mkdir -p $(@D)
	@$(CC) -M $< -MT $(buildir)$*-shared.cc.o | awk '{ print $$0 } END { printf("\t$$(CXX) $$(cxxflags_shared) $$(INCLUDES_$(subst /,,$(dir $*))) -c -o $$@ $$<\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

#makefiles to create the libraries
$(buildir)lib%.mk : $(srcdir)%/
	@mkdir -p $(@D)
	@echo -e "ifdef SHARED"\
	"\ninclude \$$(filter \$$(buildir)$*/%.mk,\$$(MKS_S))"\
	"\nelse"\
	"\nifneq (\$$(strip \$$(SHARED_$*)),)"\
	"\ninclude \$$(filter \$$(buildir)$*/%.mk,\$$(MKS_S))"\
	"\nelse"\
	"\ninclude \$$(filter \$$(buildir)$*/%.mk,\$$(MKS))"\
	"\nendif"\
	"\nendif\n"\
	"\n\$$(buildir)lib$*.so : \$$(filter \$$(buildir)$*/%.cpp.o \$$(buildir)$*/%.cxx.o \$$(buildir)$*/%.cc.o,\$$(OBJS_S))"\
	"\n\t\$$(CXX) \$$(cxxflags_shared_lib) \$$^ \$$(sort \$$(CXXLIBS_$*)) -o \$$@\n"\
	"\n\$$(buildir)lib$*.a : \$$(filter \$$(buildir)$*/%.cpp.o \$$(buildir)$*/%.cxx.o \$$(buildir)$*/%.cc.o,\$$(OBJS))"\
	"\n\t\$$(AR) \$$(ARFLAGS) \$$@ \$$^ \$$(if \$$(CXXLIBS_$*),-l\"\$$(sort \$$(CXXLIBS_$*))\")\n" > $@

# include ilbrary make files
ifneq ($(strip $(filter build build-libs install% $(LIBS) $(buildir)$(prog_name),$(MAKECMDGOALS))),)
include $(MKSLIBS)
else
ifeq ($(strip $(MAKECMDGOALS)),)
include $(MKSLIBS)
endif
endif

# include object make files
ifneq ($(strip $(filter build-obj%,$(MAKECMDGOALS))),)
include $(MKS) $(MKS_S)
endif
#=====================================================
#use with caution
uninstall: uninstall-bin uninstall-libs
.PHONY: uninstall

#use with caution
uninstall-bin:
	rm "$(DESTDIR)$(bindir)$(prog_name)"
.PHONY: uninstall-bin

#use with caution
uninstall-libs:
	rm $(addprefix "$(DESTDIR)$(libdir)",$(notdir $(LIBS)))
.PHONY:uninstall-libs

hash = \#

create-makes: create-makes-shared create-makes-static
.PHONY:create-makes

create-makes-shared: $(MKS)
.PHONY:create-makes-static

create-makes-static: $(MKS_S)
.PHONY:create-makes

create-makes-libs: $(MKSLIBS)
.PHONY: create-makes-libs

clean:
	rm -rf $(buildir)
.PHONY:clean

clean-all:clean remove-config-files
.PHONY:clean-all

#config files

generate-config-files: generate-libdependancy-config-files generate-testlibconf-file
.PHONY:generate-config-files

generate-testlibconf-file: $(srcdir)$(MAINCONFIG)
.PHONY:generate-testlibconf-file

generate-libdependancy-config-files: $(LIBCONFS)
.PHONY:generate-libdependancy-config-files

ifneq ($(strip $(filter generate% remove%,$(MAKECMDGOALS))),)
$(GLOBALCONFS):
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\noverride CXXLIBS += -L./$(buildir) $(addprefix -l,$(subst /,,$(subst $(buildir),,$(DIRS))))"\
	"\noverride INCLUDES +=" >  $@

$(srcdir)%/$(libconfigfile):
	@echo -e "$(hash)!/bin/make -f"\
	"\n$(hash) Make config file for library options, do not rename."\
	"\n$(hash) The name of the variable must be CXXLIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCXXLIBS_$* ="\
	"\nINCLUDES_$* ="\
	"\n$(hash) Set this variable to true if you want a shared library for this variable"\
	"\nSHARED_$* ="\
	"\n$(hash) DO NOT modify below this line unless you know what you are doing.\n"\
	"\noverride CXXLIBS_DEP += \$$(filter-out \$$(CXXLIBS),\$$(CXXLIBS_$*))\n"\
	"\nifndef buildir"\
	"\n\$$(error buildir must be defined)"\
	"\nendif"\
	"\nifneq (\$$(strip \$$(SHARED_$*)),)"\
	"\noverride SHAREDCOSTOM = true"\
	"\noverride LIBS += \$$(buildir)lib$*.so"\
	"\nelse"\
	"\noverride LIBS += \$$(buildir)lib$*.a"\
	"\nendif" > $@
endif

remove-config-files: remove-libdependancy-config-files remove-testlibconf-file
.PHONY:remove-config-files

remove-testlibconf-file:
	rm -f $(GLOBALCONFS)
.PHONY:generate-testlibconf-file

remove-libdependancy-config-files:
	rm -f $(LIBCONFS)
.PHONY:remove-libdependancy-config-files
