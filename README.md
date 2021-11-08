This project contains .config files to build OpenMP-enabled bare-metal GCC compilers for:

-- ARMv8 (64-bit Cortex-A53, A72, etc.)
-- ARMv7 (32-bit Cortex-A9, Cortex-M7, etc.)

Normally bare metal compilers do not have OpenMP support, since it is assumed that considerable
operating system suport is required to make OpemMP work. However, it is actually not that difficult
to get a subset of OpemMP working on a multi-core bare metal system.

To build a bare-metal OpemMP-enabled toolchain you first need a couple simple mods to ct-ng which
are contained in the project at https://github.com/jrengdahl/crosstool-ng-openmp. After downloading
my modified version of crosstool-ng, follow the instructions at
https://crosstool-ng.github.io/docs to build and install ct-ng.



