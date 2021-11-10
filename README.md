## Introduction

This project contains .config files to build OpenMP-enabled bare-metal GCC compilers:

* aarch64/.config  --  ARMv8 (64-bit Cortex-A53, A72, etc.)
* arm/.config      --  ARMv7 (32-bit Cortex-A9, Cortex-M7, etc.)

Normally bare metal compilers do not have OpenMP support, since it is assumed that considerable
operating system support is required to make OpenMP work. However, it is actually not that difficult
to get a subset of OpenMP working on a multi-core bare metal system.

To build a bare-metal OpenMP-enabled toolchain you first need a couple simple mods to ct-ng which
are contained in the project at https://github.com/jrengdahl/crosstool-ng-openmp. After downloading
my modified version of crosstool-ng, follow the instructions at
https://crosstool-ng.github.io/docs to build and install ct-ng.

## Cygwin issues

I built these toolchains on a Windows 10 PC using Cygwin. Following the ct-ng instructions,
I enabled case-sensitive filenames on the build machine.

I want the toolchains to be useable in both
Cygwin and non-Cygwin environments. In order to do this I need to copy two of the Cygwin DLLs
into the toolchain's bin directory, and move or copy two directories (see the file SetupOpenMP.txt).

If you run the toolchains in a Cygwin environment it is necessary that the version of the DLLs in
the toolchain bin directory match the Cygwin version. I recommend that you update your Cygwin,
then update the DLLs in the toolchain by copying them from C:/Cygwin64/bin. If you do not use
Cygwin you do not need to do this.

In my world I run the toolchain in a Cygwin environment whenever I compile something by typing commands
in a shell window. When I compile using an Eclipse project, the tools are run in a non-Cygwin environment
automatically created by Eclipse. This
is why I need the toolchain to work in both Cygwin and non-Cygwin environments.

What I really wanted to do was build the toolchains using Cygwin's msys compilers. Applications built with msys
and statically linked  are independent of any DLLs and are more portable. However, msys does not seem to
be complete enough to build GCC.

## .config mods

Here are some of the more signficant changes made to the .config file:

* CT_PREFIX_DIR="/cygdrive/c/cross/${CT_TARGET}"  
   This causes the toolchain to be installed under C:\cross, which is where I keep my cross toolchains.
   There is a possibility that moving the toolchain to another location may not work in some cases
   (such as in a non-Cygwin environment) due to how Cygwin translates path names.
   I suspect it has something to do with cygwin1.dll becoming offended at finding itself in \<toolchain\>/bin
   rather than in C:/cygwin64/bin.
   If moving the install location breaks for you, you may have to adjust this setting and re-build the toolchain for your environment,
   or just keep the toolchains in C:\cross.

* CT_EXTRA_LDFLAGS_FOR_BUILD="-static"  
   This causes the tools to be statically linked. I had hoped that this would mean that the Cygwin
   DLLs would not need to be included but this is not the case. However, I left the static flag set.

* CT_TARGET_CFLAGS="-ffixed-x18" or CT_TARGET_CFLAGS="-ffixed-r9"  
This causes the compiler to build libraries that do not use the platform register as defined in
the ARM or Aarch64 Procedure Call Standards (AAPCS):

  >"The role of register r9 is platform specific. A virtual platform may assign any role to this
register and must document this usage. For example, it may designate it as the static base (SB)
in a position-independent data model, or it may designate it as the thread register (TR) in an
environment with thread-local storage. The usage of this register may require that the value
held is persistent across all calls. A virtual platform that has no need for such a special
register may designate r9 as an additional callee-saved variable register."

  I recommend that application code compiled for the bare metal OpenMP environment
include the -ffixed-r19 or -ffixed-x18 flag. This enables signficant optimization of bare metal
thread switching.  

* CT_TARGET_VENDOR="openmp"  
Since bare metal toolchains typically put "none" or "unknown" as the second field of the triplet, which is redundant and uninformative,
I decided to put "openmp" here.

* CT_THREADS_NONE=y  
This is set, since the bare metal environment does not support Pthreads or any other known operating
system defined threading system. I am still learning OpenMP, but as far as I can tell at this point,
OpenMP does not explicitly depend on Pthreads, therefore, it doesn't make sense that the GCC
build systems enforces a dependency between OpenMP and Pthreads. Any Pthreads dependencies are hidden
withing libgomp. To use OpenMP under bare metal, the threading mechanism must be provided by an
implementation of libgomp.

* CT_CC_GCC_LIBGOMP=y  
This flag enables OpenMP in the compiler. By default the GCC config system will override this setting
if CT_THREADS_NONE=y is set. A couple modifications to crosstool-ng were required to overcome this.

* CT_GDB_CROSS is not set  
I was not abe to get crosstool-ng to successfully build GDB. It had something to do with the version of
Python found by the configure script. Since I don't use GDB I simply turned this option off rather than
spending time debugging the problem. Since the Eclipse toolchain manger requires the presence of gdb
in the toolchain bin directory (even if it is not used), I copied in a gdb from another similar toolchain
and renamed it to match the triplet. I don't know if this gdb would work.


