#!/usr/bin/make -f
# Set environment variables

# this makefile follows the below conventions for variables denoting files and directories
# all directory names must end with a terminal '/' character
# file names never end in terminal '/' character


#===================================================
SHELL = /bin/bash

# set this variable to any value to make shared libraries (cleaning existing build files may be necessary)
SHARED =

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
override INSTALLSTAMP  = installstamp.txt
#=======================================================
# DO NOT MODIFY VARIABLES!
#====================================================
# Source and target objects
#====================================================
CXX1SRCS    = $(wildcard $(srcdir)*/*.cpp)
CXX2SRCS    = $(wildcard $(srcdir)*/*.cxx)
SRCS        = $(CXX1SRCS) $(CXX2SRCS)
DIRS        = $(addprefix $(buildir),$(subst $(srcdir),,$(SRCDIRS)))
SRCDIRS     = $(sort $(dir $(SRCS)))
OBJS        = $(patsubst %.cpp,%.cpp.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%.cxx.o,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS))))
MKS         = $(patsubst %.cpp,%cpp.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX1SRCS)))) $(patsubst %.cxx,%cxx.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(CXX2SRCS))))
ifndef SHARED
LIBS      = $(addprefix $(buildir),$(addsuffix .a,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
else
LIBS      = $(addprefix $(buildir),$(addsuffix .so,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
endif
LIBCONFS  = $(addsuffix $(LIBCONFIGFILE),$(SRCDIRS))
CXXLIBS_DEP :=
-include $(LIBCONFS)
#=====================================================

build: build-obj $(LIBS)
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
	rm -f $(buildir)$(INSTALLSTAMP)
.PHONY:installmode

debug:
	@echo -e "\e[35mBuild Directories \e[0m: $(DIRS)"
	@echo -e "\e[35mSource Directories\e[0m: $(SRCDIRS)"
	@echo -e "\e[35mLibdepconf Files  \e[0m: $(LIBCONFS)"
	@echo -e "\e[35mBuild Files       \e[0m: $(LIBS)"
	@echo    "#-------------------------------------------#"
	@echo -e "\e[35mSource Files     \e[0m: $(SRCS)"
	@echo -e "\e[35mMake Files       \e[0m: $(MKS)"
	@echo -e "\e[35mObject Files     \e[0m: $(OBJS)"
.PHONY:debug

help:
	@echo "The follwing targets may be given..."
	@echo -e "\t...install"
	@echo -e "\t...install-bin"
	@echo -e "\t...install-libs"
	@echo -e "\t...build*"
	@echo -e "\t...test"
	@echo -e "\t...uninstall"
	@echo -e "\t...uninstall-bin"
	@echo -e "\t...uninstall-libs"
	@echo -e "\t...clean"
	@echo -e "\t...clean-all"
	@echo "Other options"
	@echo -e "\t...debug"
	@echo -e "\t...help"
	@echo -e "\t...generate-config-file"
	@echo -e "\t...remove-config-file"
.PHONY: help

test: $(buildir)$(prog_name)
.PHONY:test

build-obj: $(OBJS)
.PHONY:build-obj

-include $(srcdir)$(MAINCONFIG)

export CC CXXFLAGS INCLUDES RPATH CXXLIBS
export INSTALL INSTALL_DATA INSTALL_PROGRAM
export buildir srcdir
export prog_name
export SHARED
#=====================================================

ifndef CXXLIBS
ifdef SHARED
CXXLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.so,%,$(LIBS)))
else
CXXLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.a,%,$(LIBS)))
endif
endif
CXXLIBS += $(sort $(CXXLIBS_DEP))

#============
ifneq ($(strip $(filter install install-bin,$(MAKECMDGOALS))),)
export override INSTALLMODE = true
$(buildir)$(prog_name) : $(LIBS) installmode
else
export override INSTALLMODE =
$(buildir)$(prog_name): INSTALLSTAMP_TMP = $(buildir)$(INSTALLSTAMP)
$(buildir)$(prog_name): $(LIBS) $(buildir)$(INSTALLSTAMP)
endif
	$(MAKE) -e -f Makefile2 $(patsubst INSTALLSTAMP=%,,$(MAKEFLAGS)) INSTALLSTAMP="$(INSTALLSTAMP_TMP)"

$(buildir)$(INSTALLSTAMP):
	touch $@
#============

$(buildir)%cpp.mk : $(srcdir)%.cpp
	@mkdir -p $(@D)
ifndef SHARED
	@$(CXX) -M $< -MT $(buildir)$*.cpp.o | awk '{ print $$0 } END { printf("\t$(CXX) $(CXXFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cpp.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
else
	@$(CXX) -M $< -MT $(buildir)$*.cpp.o | awk '{ print $$0 } END { printf("\t$(CXX) $(filter-out -pie -fpie -Fpie,$(CXXFLAGS)) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cpp.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
endif
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

$(buildir)%cxx.mk : $(srcdir)%.cxx
	@mkdir -p $(@D)
ifndef SHARED
	@$(CXX) -M $< -MT $(buildir)$*.cxx.o | awk '{ print $$0 } END { printf("\t$(CXX) $(CXXFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cxx.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
else
	@$(CXX) -M $< -MT $(buildir)$*.cxx.o | awk '{ print $$0 } END { printf("\t$(CXX) $(filter-out -pie -fpie -Fpie,$(CXXFLAGS)) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.cxx.o $<\n\ttouch $(@D)/$(TIMESTAMP)\n") }' > $@
endif
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

ifneq ($(strip $(filter build build-obj test install install-bin install-libs install $(buildir)$(prog_name) $(LIBS) $(OBJS),$(MAKECMDGOALS))),)
include $(MKS)
else ifeq ($(MAKECMDGOALS),)
include $(MKS)
endif

ifndef SHARED
lib%.a: %/$(TIMESTAMP) | $(buildir)
	$(AR) $(ARFLAGS) $@ $(filter $*/%.o,$(OBJS)) $(if $(CXXLIBS_$(notdir $*)),-l"$(strip $(CXXLIBS_$(notdir $*)))")
else
lib%.so: %/$(TIMESTAMP) | $(buildir)
	$(CXX) $(filter-out -pie -fpie -Fpie -pic -fpic -Fpic,$(CXXFLAGS)) --shared $(filter $*/%.o,$(OBJS)) $(strip $(CXXLIBS_$(notdir $*))) -o $@
endif

%/$(TIMESTAMP): $(buildir) ;

.SECONDARY: $(addsuffix $(TIMESTAMP),$(DIRS))

$(buildir): build-obj ;

#=====================================================

hash = \#

create-makes: $(MKS)
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

generate-testlibconf-file:
ifndef SHARED
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCXXLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.a,%,$(LIBS)))"\
	"\nINCLUDES =" > "$(srcdir)$(MAINCONFIG)"
else
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCXXLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.so,%,$(LIBS)))"\
	"\nINCLUDES =" > "$(srcdir)$(MAINCONFIG)"
endif
.PHONY:generate-testlibconf-file

remove-testlibconf-file:
	rm -f $(srcdir)libconfig.mk
.PHONY:generate-testlibconf-file

generate-libdependancy-config-files:
	@for file in $(LIBCONFS); do \
		stem="$${file%/*}" ; \
		stem="$${stem//$(srcdir)/}" ; \
		stem="$${stem//\//}" ; \
		echo -e "$(hash)!/usr/bin/make -f"\
		"\n$(hash) Make config file for linker options, do not rename."\
		"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
		"\nCXXLIBS_$${stem} ="\
		"\nINCLUDES_$${stem} ="\
		"\nCXXLIBS_DEP += \$$(filter-out \$$(CXXLIBS),\$$(CXXLIBS_$${stem}))\n" > "$$file"; \
	done
.PHONY:generate-libdependancy-config-files

remove-libdependancy-config-files:
	rm -f $(LIBCONFS)
.PHONY:remove-libdependancy-config-files
