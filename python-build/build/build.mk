#
# This is a makefile replacement for Py4A/python-build/build.sh, for including Py4A into an Android build
#

LOCAL_PATH := $(call my-dir)

python_version  := 2.6.2
python_tarball  := $(HOST_COMMON_OUT_ROOT)/Python-$(python_version).tar.bz2
python_patch    := $(LOCAL_PATH)/../Python-${python_version}-android.patch
python_url      := http://www.python.org/ftp/python/$(python_version)/Python-$(python_version).tar.bz2

#
# TODO: This kind of external download is not what we should do...
# TODO: Add python source as a separate repo...
#

$(python_tarball):
	wget -O $(python_tarball) $(python_url)

#
# Build the host python and host pgen so we can
# generate the correct grammar and some other stuff
#

# Adopted from build/core/host_executable.mk

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS    := optional
LOCAL_MODULE         := host_pgen

LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE_CLASS   := EXECUTABLES
LOCAL_MODULE_SUFFIX  := $(HOST_EXECUTABLE_SUFFIX)

include $(BUILD_SYSTEM)/binary.mk

host_python_work_dir        := $(intermediates)
host_python_build_dir       := $(host_python_work_dir)/Python-$(python_version)

# Must be an absolute path
host_python_install_dir     := $(CURDIR)/$(intermediates)/python

host_python_built_marker    := $(host_python_build_dir)/python
host_python_install_marker  := $(host_python_install_dir)/bin/python
host_pgen_install_marker    := $(LOCAL_BUILT_MODULE)

host_python_pgen := $(CURDIR)/$(LOCAL_BUILT_MODULE)


# Explicit rule for actually copying host_pgen to the place.  Hackish.  Consider replacing.
$(LOCAL_BUILT_MODULE): $(host_python_install_marker)
	$(hide) (cd $(host_python_build_dir); cp Parser/pgen $(CURDIR)/$@ )

# Install the host python from host_python_build_dir to host_python_intall_dir
$(host_python_install_marker): $(host_python_built_marker)
	$(hide) mkdir -p $(host_python_install_dir)
	$(hide) (cd $(host_python_build_dir); make install )

# Unpack and build the host python into host_python_build_dir
# TODO: Replace with a proper git repo instead of downloading and patching
$(host_python_built_marker): $(python_tarball)
	@echo "Decompressing Python-$(python_version)"
	$(hide) mkdir -p $(host_python_work_dir)
	$(hide) (cd $(host_python_work_dir);  tar -xjf $(CURDIR)/$(python_tarball)            )
	$(hide) (cd $(host_python_build_dir); ./configure --prefix=$(host_python_install_dir) )
	$(hide) (cd $(host_python_build_dir); make                                            )


#
# Build the environment for compiling the Android version of python
#
# This is just the environment; the rule to actually build python is below
# This is somewhat hackish, for a number of reasons:
# - We are using Python from a tarball, not from a git repo as is usually done
# - We need to do some patching etc from Py4A
# - We need to use the host python (built above) to generate the grammar etc.
#
# This target installs python files compiled with the host python.
#

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS    := optional
LOCAL_MODULE         := python-build

LOCAL_MODULE_CLASS := INTERMEDIATES
LOCAL_UNINSTALLABLE_MODULE := true

LOCAL_PRELINK_MODULE := false

include $(BUILD_SYSTEM)/base_rules.mk

python_intermediate_libraries := site-packages encodings compiler hotshot \
    email email/mime \
    json \
    sqlite3 \
    logging bsddb wsgiref \
    ctypes ctypes/macholib idlelib idlelib/Icons \
    distutils distutils/command \
    multiprocessing multiprocessing/dummy \
    lib-old \
    plat-linux2 \
    xml xml/dom xml/etree xml/parsers xml/sax \

python_work_dir     := $(intermediates)
python_src_dir      := $(python_work_dir)/Python-$(python_version)

python_intermediate_install_dir    := $(intermediates)/usr

python_library_dir        := $(python_intermediate_install_dir)/lib/python2.6

python_install_marker     := $(TARGET_OUT_SHARED_LIBRARIES)/python2.6/compileall.pyc
python_library_obj_marker := $(python_library_dir)/compileall.pyc
python_library_src_marker := $(python_library_dir)/compileall.py
python_grammar_marker     := $(python_src_dir)/Include/graminit.h
python_src_marker         := $(python_src_dir)/Modules/config.c

# Install the Python packages, compiled by the host Python
# TODO: The following rule is currently an ugly hack.  Fix.
$(python_install_marker): $(python_library_obj_marker)
	@echo "Install: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) $(ACP) -fptr $(dir $<)/* $(dir $@)

# Use the host python to compile the Python packages at the intermediate installation
$(python_library_obj_marker): $(python_library_src_marker) $(python_grammar_marker)
	$(hide) $(host_python_install_dir)/bin/python \
		$(python_library_dir)/compileall.py $(python_library_dir)

# Copy the python source code from the source distribution into the intermediate installation
$(python_library_src_marker): $(python_src_marker)
	$(hide) mkdir -p $(python_intermediate_install_dir)
	$(hide) for lib in $(python_intermediate_libraries); do \
	    if [ -n "$$(find ${python_src_dir}/Lib/$${lib} -maxdepth 1 -type f)" ]; then \
		mkdir -p ${python_intermediate_install_dir}/lib/python2.6/$${lib}; \
		cp $$(find ${python_src_dir}/Lib/$${lib} -maxdepth 1 -type f) \
			${python_intermediate_install_dir}/lib/python2.6/$${lib}; \
	    fi; \
	done
	$(hide) cp $$(find ${python_src_dir}/Lib/ -maxdepth 1 -type f) \
		${python_intermediate_install_dir}/lib/python2.6/

# Generate the Python grammar
# Building the Android python depends on the host python
$(python_grammar_marker): $(python_src_marker) $(host_pgen_install_marker)
	$(hide) $(host_python_pgen) \
	     $(CURDIR)/$(python_src_dir)/Grammar/Grammar \
	     $(CURDIR)/$(python_src_dir)/Include/graminit.h \
	     $(CURDIR)/$(python_src_dir)/Python/graminit.c

# Unpack and patch the Python grammar for Android
# TODO: Replace with a proper git repo instead of downloading and patching
$(python_src_marker): $(python_tarball) $(python_patch)
	$(hide) rm -rf $(python_work_dir)
	$(hide) mkdir -p $(python_work_dir)
	$(hide) (cd $(python_work_dir);  tar -xjf $(CURDIR)/$(python_tarball) )
	$(hide) (cd $(python_src_dir); patch -p1 -i $(CURDIR)/$(python_patch) )

#
# Real Python target
#
# Builds the Android python from the patched sources.
#
# Note also that we make this target to depend on python-build
# through the python_install_marker
#

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(python_src_dir) $(python_src_dir)/Include
LOCAL_MODULE := python
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := Modules/python.c
LOCAL_PATH := $(python_src_dir)
LOCAL_SHARED_LIBRARIES := libpython2.6
include $(BUILD_EXECUTABLE)

$(python_src_dir)/Modules/python.c: $(python_src_marker)
$(python_src_dir)/Parser/acceler.c: $(python_src_marker)

$(LOCAL_INSTALLED_MODULE): $(python_install_marker)

