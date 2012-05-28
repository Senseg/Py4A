#
# This is a makefile replacement for build.sh, for including Py4A into an Android build
#

LOCAL_PATH := $(call my-dir)

python_version  := 2.6.2
python_tarball  := $(HOST_COMMON_OUT_ROOT)/Python-$(python_version).tar.bz2
python_patch    := $(LOCAL_PATH)/../Python-${python_version}-android.patch
python_url      := http://www.python.org/ftp/python/$(python_version)/Python-$(python_version).tar.bz2

include $(CLEAR_VARS)

#
# TODO: This kind of external download is not what we should do...
# TODO: Add python source as a separate repo...
#

$(python_tarball):
	wget -O $(python_tarball) $(python_url)

# Build the host python and host pgen so we can
# generate the correct grammar and some other stuff

# Adopted from build/core/host_executable.mk

LOCAL_MODULE_TAGS    := optional
LOCAL_MODULE         := host_pgen

LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE_CLASS   := EXECUTABLES
LOCAL_MODULE_SUFFIX  := $(HOST_EXECUTABLE_SUFFIX)

include $(BUILD_SYSTEM)/binary.mk

host_python_work_dir  := $(intermediates)
host_python_build_dir := $(host_python_work_dir)/Python-$(python_version)

host_python_install_dir := $(CURDIR)/$(intermediates)/python

host_python_built_marker    := $(host_python_build_dir)/python
host_python_install_marker  := $(host_python_install_dir)/bin/python

host_python_pgen := $(CURDIR)/$(LOCAL_BUILT_MODULE)

$(LOCAL_BUILT_MODULE): $(host_python_install_marker)
	$(hide) (cd $(host_python_build_dir); cp Parser/pgen $(CURDIR)/$@ )

$(host_python_install_marker): $(host_python_built_marker)
	$(hide) mkdir -p $(host_python_install_dir)
	$(hide) (cd $(host_python_build_dir); make install )

$(host_python_built_marker): $(python_tarball)
	@echo "Decompressing Python-$(python_version)"
	$(hide) mkdir -p $(host_python_work_dir)
	$(hide) (cd $(host_python_work_dir);  tar -xjf $(CURDIR)/$(python_tarball)            )
	$(hide) (cd $(host_python_build_dir); ./configure --prefix=$(host_python_install_dir) )
	$(hide) (cd $(host_python_build_dir); make                                            )


#
# Build the Android python
#

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS    := optional
LOCAL_MODULE         := python-build

LOCAL_MODULE_CLASS := INTERMEDIATES
LOCAL_UNINSTALLABLE_MODULE := true

LOCAL_PRELINK_MODULE := false

include $(BUILD_SYSTEM)/base_rules.mk

python_work_dir     := $(intermediates)
python_src_dir      := $(python_work_dir)/Python-$(python_version)
python_intermediate_install_dir    := $(intermediates)/usr
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

python_install_marker  := $(TARGET_OUT_SHARED_LIBRARIES)/python2.6/compileall.pyc
python_library_dir     := $(python_intermediate_install_dir)/lib/python2.6
python_ndk_marker      := $(TARGET_OUT_EXECUTABLES)/python
python_grammar_marker  := $(python_src_dir)/Include/graminit.h
python_src_marker      := $(python_src_dir)/Modules/config.c

# $(hide) (cd $(LOCAL_PATH)/../python-libs; bash -ex setuptools.sh)

$(LOCAL_BUILT_MODULE): $(python_install_marker)

# TBD: The following rule is currently an ugly hack.  Fix.
$(python_install_marker): $(python_library_dir)
	@echo "Install: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) $(ACP) -fptr $</* $(dir $@)

$(python_library_dir): $(python_ndk_marker)
	$(hide) $(host_python_install_dir)/bin/python \
		$(python_library_dir)/compileall.py $(python_library_dir)

$(python_ndk_marker): $(python_grammar_marker)

$(python_grammar_marker): $(python_src_marker)
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
	$(hide) $(host_python_pgen) \
	     $(CURDIR)/$(python_src_dir)/Grammar/Grammar \
	     $(CURDIR)/$(python_src_dir)/Include/graminit.h \
	     $(CURDIR)/$(python_src_dir)/Python/graminit.c 

$(python_src_marker): $(python_tarball) $(python_patch)
	$(hide) mkdir -p $(python_work_dir)
	$(hide) (cd $(python_work_dir);  tar -xjf $(CURDIR)/$(python_tarball) )
	$(hide) (cd $(python_src_dir); patch -p1 -i $(CURDIR)/$(python_patch) )



