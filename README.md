
Py4A patched to compile Python into an Android ROM (e.g. CyanogenMod)
instead of adding it as an Add-on.

This is essentially a set of *.mk files replacing the manual built
system usually used for building Py4A.  The files have been outline
along the Py4A build system, and are at places somewhat messy.

The main benefit of this approach is that it is more-or-less
compatible with the Py4A work.

Also available as http://code.google.com/r/pekkanikander-py4a/

------------------------------------------

To include into your ROM build, do the following:

1. Add the repo to the manifest.xml

	&gt;remote fetch="git://github.com/" name="github" />
        &gt;project name="senseg/Py4A" path="external/python-for-android" remote="github" revision="master" />

2. Include Python.mk to your device description

	$(call inherit-product, $(TOP_DIR)external/python-for-android/Python.mk)

3. Build your system

	$ make

4. Check that you got the binaries

	$ ls -l out/target/product/*/system/bin/python
	-rwxr-xr-x  1 pnr  admin  5340 May 28 15:59 out/target/product/valimo/system/bin/python
	$ ls -l out/target/product/*/system/lib/libpython*
	-rwxr-xr-x  1 pnr  admin  940076 May 28 15:59 out/target/product/valimo/system/lib/libpython2.6.so
	$ ls -l out/target/product/*/system/lib/python2.6
        lots of files...

You should see the python binary, libpython2.6 shared library,
compiled python modules, and dynamically loadable python libraries.

5. Test that your Python works

	adb shell
	TMPDIR=/data/local/tmp /system/bin/python
