LOCAL_PATH := $(call my-dir)
PYTHON_SRC_PATH := $(python_src_dir)

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(PYTHON_SRC_PATH) $(PYTHON_SRC_PATH)/Include
LOCAL_MODULE := python
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := Modules/python.c
LOCAL_PATH := $(PYTHON_SRC_PATH)
LOCAL_SHARED_LIBRARIES := libpython2.6
include $(BUILD_EXECUTABLE)

$(PYTHON_SRC_PATH)/Modules/python.c: $(python_src_marker)
