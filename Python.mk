#
# Include this file into your device description to compile Python into your Android#
#

# Python
PRODUCT_PACKAGES += \
     host_pgen python \
     libbz libcrypt libffi libpython2.6 \
     _struct _ctypes_test _weakref array cmath math strop time datetime itertools \
     future_builtins _random _collections _bisect _heapq operator \
     _fileio _bytesio _functools _json _testcapi _hotsot _lsprof unicodedata \
     _local fcntl select parser cStringIO cPcikle mmap syslog audioop imageop \
     _csv _socket _sha _md5 _sha256 _sha512 termios resource binascii \
     _bultibytecode _codecs_kr _codecs_jp _codecs_cn _codecs_tw _codecs_hk \
     _codecs_iso2022 _multiprocessing \
     bz2 zlib crypt pyexpat _elementtree _ssl _ctypes _sqlite3
