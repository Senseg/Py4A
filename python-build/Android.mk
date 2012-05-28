python_local_path := $(call my-dir)

define __ndk_info
endef

include $(call all-named-subdir-makefiles, bzip2  libcrypt  libffi )

include $(python_local_path)/build/build.mk

include $(python_local_path)/libpython/Android.mk
include $(python_local_path)/build/python.mk
include $(python_local_path)/build/modules.mk


