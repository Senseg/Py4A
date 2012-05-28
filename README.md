
Py4A patches to compile Python into an Android ROM (e.g. CyanogenMod)
instead of adding it as an Add-on.

This is essentially a set of *.mk files replacing the manual built
system usually used for building Py4A.  The files have been outline
along the Py4A build system, and are at places somewhat messy.

The main benefit of this approach is that it is more-or-less
compatible with the Py4A work.
