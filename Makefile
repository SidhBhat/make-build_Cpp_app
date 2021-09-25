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
ifdef SHARED
CXXFLAGS  += -fpic -fpie
endif
ifneq ($(strip $(filter install install-bin,$(MAKECMDGOALS))),)
RPATH    = $(DESTDIR)$(libdir)
else
RPATH    = $(buildir)
endif
AR       = ar
ARFLAGS  = crs
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
override LIBCONFIGFILE = config.mk
override MAINCONFIG    = libconfig.mk
override TIMESTAMP     = timestamp.txt
#existance of file INSTALLSTAMP instructs to go in non-installmode
override COMPILESTAMP  = compilestamp.txt
#=======================================================
# DO NOT MODIFY VARIABLES!
#====================================================
# Source and target objects
#====================================================
CXX1SRCS      = $(wildcard $(srcdir)*/*.cpp)
CXX2SRCS      = $(wildcard $(srcdir)*/*.cxx)
CXX3SRCS      = $(wildcard $(srcdir)*/*.cc)
SRCS          = $(CXX1SRCS) $(CXX2SRCS) $(CXX3SRCS)
MAIN_CXX1SRCS = $(wildcard $(srcdir)*.cpp)
MAIN_CXX2SRCS = $(wildcard $(srcdir)*.cxx)
MAIN_CXX3SRCS = $(wildcard $(srcdir)*.cc)
MAIN_SRCS     = $(MAIN_CXX1SRCS) $(MAIN_CXX2SRCS) $(MAIN_CXX3SRCS)
SRCDIRS       = $(sort $(dir $(SRCS)))
DIRS          = $(addprefix $(buildir),$(subst $(srcdir),,$(SRCDIRS)))
OBJS          = $(patsubst %.cpp,%.cpp.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%.cxx.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%.cc.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
OBJS_S        = $(patsubst %.cpp,%-shared.cpp.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%-shared.cxx.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%-shared.cc.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
MKS           = $(patsubst %.cpp,%cpp.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%cxx.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%cc.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
MKS_S         = $(patsubst %.cpp,%-sharedcpp.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%-sharedcxx.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS)))) $(patsubst %.cc,%-sharedcc.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX3SRCS))))
override CLIBS_DEP :=
LIBCONFS  = $(addsuffix $(LIBCONFIGFILE),$(SRCDIRS))
ifeq ($(strip $(filter generate% remove%,$(MAKECMDGOALS))),)
-include $(LIBCONFS) $(srcdir)$(MAINCONFIG)
endif
ifdef SHARED
LIBS      = $(addprefix $(buildir),$(addsuffix .so,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
else
ifndef SHAREDCOSTOM
LIBS      = $(addprefix $(buildir),$(addsuffix .a,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
endif
endif

ifndef CXXLIBS
override CXXLIBS += -L./$(buildir) $(addprefix -l,$(subst /,,$(subst $(buildir),,$(DIRS))))
endif
override CXXLIBS += $(sort $(CLIBS_DEP))
#=====================================================

build: $(LIBS)
.PHONY:build

.DEFUALT_GOAL:build

install: install-libs install-bin
.PHONY: install

install-libs: LIB_FILES = $(addprefix $(DESTDIR)$(libdir),$(notdir $(LIBS)))
install-libs: build
	@for file in $(LIB_FILES); do \
		[ -f "$$file" ] && { echo -e "\e[31mError\e[32m $$file exists Defualt behavior is not to overwrite...\e[0m Terminating..."; exit 23; } || true; \
	done
ifndef SHARED
	$(INSTALL_DATA) $(LIBS) -t $(DESTDIR)$(libdir)
else
	$(INSTALL_PROGRAM) $(LIBS) -t $(DESTDIR)$(libdir)
endif
.PHONY: install

install-bin: test
	@[ -f "$(DESTDIR)$(bindir)$(prog_name)" ] && { echo -e "\e[31mError\e[32m $$file exists Defualt behavior is not to overwrite...\e[0m Terminating..."; exit 24; } || true
	$(INSTALL_PROGRAM) $(buildir)$(prog_name) -t $(DESTDIR)$(bindir)
.PHONY:install-bin

#phony to go in install mode
installmode:
	rm -f $(buildir)$(COMPILESTAMP)
.PHONY:installmode

debug:
	@echo -e "\e[35mBuild Directories \e[0m: $(DIRS)"
	@echo -e "\e[35mSource Directories\e[0m: $(SRCDIRS)"
	@echo -e "\e[35mLibconf Files     \e[0m: $(LIBCONFS)"
	@echo -e "\e[35mGlobalconfig File \e[0m: $(srcdir)$(MAINCONFIG)"
	@echo -e "\e[35mLibraries Files   \e[0m: $(LIBS)"
	@echo    "#-------------------------------------------#"
	@echo -e "\e[35mSource Files        \e[0m: $(SRCS) $(MAIN_SRCS)"
	@echo -e "\e[35mMake Files          \e[0m: $(MKS)"
	@echo -e "\e[35mMake Files Shared   \e[0m: $(MKS_S)"
	@echo -e "\e[35mObject Files        \e[0m: $(OBJS)"
	@echo -e "\e[35mObject Shared Files\e[0m: $(OBJS_S)"
	@echo -e "\e[35mCMD Goals \e[0m: $(MAKECMDGOALS)"
	@echo -e "\e[35mMakeflags \e[0m: $(MAKEFLAGS)"
	@echo -e "\e[35mClibs     \e[0m: $(CXXLIBS)"
	@echo -e "\e[35mClibs DEP \e[0m: $(CXXLIBS_DEP)"
	@echo -e "\e[35mTest Var  \e[0m: $(prog_name)"
	$(MAKE) -C "$(CURDIR)" -e -f Makefile2 debug
.PHONY:debug

help:
	@echo "The follwing targets may be given..."
	@echo -e "\t...install"
	@echo -e "\t...install-bin"
	@echo -e "\t...install-libs"
	@echo -e "\t...build*"
	@echo -e "\t...build-obj"
	@echo -e "\t...test"
	@echo -e "\t...uninstall"
	@echo -e "\t...uninstall-bin"
	@echo -e "\t...uninstall-libs"
	@echo -e "\t...clean"
	@echo -e "\t...clean-all"
	@echo "Other options"
	@echo -e "\t...debug"
	@echo -e "\t...help"
	@echo -e "\t...generate-config-files"
	@echo -e "\t...remove-config-files"
	@echo -e "\t...generate-libdependancy-config-files"
	@echo -e "\t...generate-testlibconf-file"
	@echo -e "\t...remove-libdependancy-config-files"
	@echo -e "\t...remove-testlibconf-file"
	@echo -e "\t...create-makes"
	@echo -e "\t...create-makes-static"
	@echo -e "\t...create-makes-shared"
	@echo -e "\t...build-obj-static"
	@echo -e "\t...build-obj-shared"
.PHONY: help

test: $(buildir)$(prog_name)
.PHONY:test

build-obj: build-obj-static build-obj-shared ;
.PHONY: build-obj

build-obj-static: $(OBJS)
.PHONY:build-obj-static

build-obj-shared: $(OBJS_S)
.PHONY:build-obj-shared

#=====================================================
export CXX CXXFLAGS INCLUDES RPATH CXXLIBS
export INSTALL INSTALL_DATA INSTALL_PROGRAM
export buildir srcdir
export prog_name
export SHARED
#============
ifdef SHAREDCOSTOM
$(buildir)$(prog_name): export SHARED = true
endif
ifneq ($(strip $(filter install install-bin,$(MAKECMDGOALS))),)
export override INSTALLMODE = true
$(buildir)$(prog_name) : $(LIBS) installmode $(MAIN_SRCS)
else
export override INSTALLMODE =
$(buildir)$(prog_name): COMPILESTAMP_TMP = $(buildir)$(COMPILESTAMP) $(addsuffix $(TIMESTAMP),$(DIRS))
$(buildir)$(prog_name): $(LIBS) $(buildir)$(COMPILESTAMP) $(MAIN_SRCS)
endif
	$(MAKE) -e -f Makefile2 $(patsubst INSTALLSTAMP=%,,$(MAKEFLAGS)) COMPILESTAMP="$(COMPILESTAMP_TMP)"

$(buildir)$(COMPILESTAMP): $(LIBS)
	touch $@

#============

$(buildir)%cpp.mk : $(srcdir)%.cpp
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*.cpp.o | awk '{ print $$0 } END { printf("\t$(CXX) $(CXXFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cpp.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%-sharedcpp.mk : $(srcdir)%.cpp
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*-shared.cpp.o | awk '{ print $$0 } END { printf("\t$(CXX) $(filter-out -pie -fpie -Fpie,$(CXXFLAGS)) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*-shared.cpp.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%cxx.mk : $(srcdir)%.cxx
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*.cxx.o | awk '{ print $$0 } END { printf("\t$(CXX) $(CXXFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cxx.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%-sharedcxx.mk : $(srcdir)%.cxx
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*-shared.cxx.o | awk '{ print $$0 } END { printf("\t$(CXX) $(filter-out -pie -fpie -Fpie,$(CXXFLAGS)) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*-shared.cxx.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%cc.mk : $(srcdir)%.cc
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*.cc.o | awk '{ print $$0 } END { printf("\t$(CXX) $(CXXFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cc.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%-sharedcc.mk : $(srcdir)%.cc
	@mkdir -p $(@D)
	@$(CXX) -M $< -MT $(buildir)$*-shared.cc.o | awk '{ print $$0 } END { printf("\t$(CXX) $(filter-out -pie -fpie -Fpie,$(CXXFLAGS)) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*-shared.cc.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

ifdef SHARED
MAKE_BUILD_FILES=$(MKS_S)
else
ifndef SHAREDCOSTOM
MAKE_BUILD_FILES=$(MKS)
else
MAKE_BUILD_FILES=$(MKS)	$(MKS_S)
endif
endif

ifneq ($(strip $(filter build build-obj test install install-bin install-libs install $(buildir)$(prog_name) $(LIBS) $(OBJS),$(MAKECMDGOALS))),)
include $(MAKE_BUILD_FILES)
else ifeq ($(MAKECMDGOALS),)
include $(MAKE_BUILD_FILES)
endif

lib%.a: %/$(TIMESTAMP) | $(buildir)
	$(AR) $(ARFLAGS) $@ $(filter $*/%.o,$(OBJS)) $(if $(CXXLIBS_$(notdir $*)),-l"$(strip $(CXXLIBS_$(notdir $*)))")
lib%.so: %/$(TIMESTAMP) | $(buildir)
	$(CXX) $(filter-out -pie -fpie -Fpie -pic -fpic -Fpic,$(CXXFLAGS)) --shared $(filter $*/%.o,$(OBJS_S)) $(strip $(CXXLIBS_$(notdir $*))) -o $@

%/$(TIMESTAMP): $(buildir) ;

.SECONDARY: $(addsuffix $(TIMESTAMP),$(DIRS))

ifdef SHARED
$(buildir): build-obj-shared ;
else
ifndef SHAREDCOSTOM
$(buildir) : build-obj-static ;
else
$(buildir) : build-obj-static build-obj-shared;
endif
endif
#=====================================================

hash = \#

create-makes: create-makes-shared create-makes-static
.PHONY:create-makes

create-makes-shared: $(MKS)
.PHONY:create-makes-static

create-makes-static: $(MKS_S)
.PHONY:create-makes

clean:
	rm -rf $(buildir)
.PHONY:clean

clean-all:clean remove-config-files
.PHONY:clean-all

#use with caution!
uninstall-libs:
	rm -f $(addprefix $(DESTDIR)$(libdir),$(notdir $(LIBS)))
.PHONY:uninstall-libs

#use with caution!
uninstall-bin:
	rm -f $(DESTDIR)$(bindir)$(prog_name)
.PHONY:uninstall-bin

#use with caution!
uninstall:uninstall-bin uninstall-libs
.PHONY:uninstall

generate-config-files: generate-libdependancy-config-files generate-testlibconf-file
.PHONY:generate-config-files

remove-config-files: remove-libdependancy-config-files remove-testlibconf-file
.PHONY:remove-config-files

generate-testlibconf-file: $(srcdir)$(MAINCONFIG)
.PHONY:generate-testlibconf-file

generate-libdependancy-config-files: $(LIBCONFS)
.PHONY:generate-libdependancy-config-files

ifneq ($(strip $(filter generate% remove%,$(MAKECMDGOALS))),)
$(srcdir)$(MAINCONFIG):
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\noverride CXXLIBS += -L./$(buildir) $(addprefix -l,$(subst /,,$(subst $(buildir),,$(DIRS))))"\
	"\noverride INCLUDES +=" >  $@

$(srcdir)%/$(LIBCONFIGFILE):
	@echo -e "$(hash)!/bin/make -f"\
	"\n$(hash) Make config file for library options, do not rename."\
	"\n$(hash) The name of the variable must be CLIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCXXLIBS_$* ="\
	"\nINCLUDES_$* ="\
	"\n$(hash) Set this variable to true if you want a shared library for this variable"\
	"\nSHARED_$* ="\
	"\n$(hash) DO NOT modify below this line unless you know what you are doing.\n"\
	"\noverride CLIBS_DEP += \$$(filter-out \$$(CXXLIBS),\$$(CXXLIBS_$*))\n"\
	"\nifndef buildir"\
	"\n\$$(error buildir must be defined)"\
	"\nendif"\
	"\nifneq (\$$(strip \$$(SHARED_$*)),)"\
	"\nSHAREDCOSTOM = true"\
	"\nLIBS += \$$(buildir)lib$*.so"\
	"\nelse"\
	"\nLIBS += \$$(buildir)lib$*.a"\
	"\nendif" > $@
endif

remove-testlibconf-file:
	rm -f $(srcdir)$(MAINCONFIG)
.PHONY:generate-testlibconf-file

remove-libdependancy-config-files:
	rm -f $(LIBCONFS)
.PHONY:remove-libdependancy-config-files
