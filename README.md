## Introduction

This project contains crosstool-ng .config files to build OpenMP-enabled
bare-metal GCC cross-compilers:

- aarch64-cygwin       --  ARMv8 for Windows 10
- aarch64-linux        -- ARMv8 for Linux
- arm-cortexm7-cygwin  -- ARMv7 Cortex-M7 for Windows 10
- arm-cortexm7-linux   -- ARMv7 Cortex-M7 for Linux
- arm-uboot-linux -- ARMv7 Cortex-A9 with NEON (i.MX6Q) with aapcs-linux

Normally bare metal compilers do not have OpenMP support, since it is
assumed that considerable operating system support is required to make
OpenMP work. However, it is actually not that difficult to get a subset
of OpenMP working on a multi-core bare metal system.

To build a bare-metal OpenMP-enabled toolchain you first need a couple
mods to crosstool-ng which are contained in the project at
https://github.com/jrengdahl/crosstool-ng-openmp. After downloading
my modified version of crosstool-ng, follow the instructions at
https://crosstool-ng.github.io/docs to build and install ct-ng. You can
then use the modified ct-ng and the .config files in this project to
build several GCC toolchains.

The Windows 10 cross-compilers are built from a Cygwin64 bash shell.
The Linux versions are built using Debian running under Windows Subsystem
for Linux (WSL). These should work equally well under any real Linux system.

## Cygwin issues

I built the Windows toolchains on a Windows 10 PC using Cygwin. Following the ct-ng instructions,
I enabled case-sensitive filenames on the build machine.

I want the toolchains to be useable in both Cygwin and non-Cygwin
environments. In order to do this, I need to copy two of the Cygwin DLLs
into the toolchain's bin directory, and move or copy two directories.
See the file SetupOpenMP.txt for detailed instructions.

If you run the toolchains in a Cygwin environment it is necessary that
the versions of the DLLs in the toolchain bin directory match the installed Cygwin
version. I recommend that you update your Cygwin, then update the DLLs
in the toolchain by copying them from C:/Cygwin64/bin. If you do not use
Cygwin you should not need to do this.

In my world I run the toolchain in a Cygwin environment whenever I compile
something by typing commands in a shell window. When I compile using an
Eclipse project, the tools are run in a non-Cygwin environment automatically
created by Eclipse. This is why I need the toolchain to work in both Cygwin
and non-Cygwin environments.

What I really wanted to do was build the toolchains using Cygwin's MSYS
compilers. Applications built with MSYS and statically linked are independent
of any DLLs and are more portable. However, MSYS does not seem to be complete
enough to build GCC.

## Linux issues

For now, you need to copy omp.h from another toolchain into the new toolchain.
TODO -- create a crosstool-ng patch to make this step unnecessary.

You may also need to copy in a gdb executable -- I have not yet tried integrating
the toolchain into Eclipse under Linux.

## .config mods

Here are some of the more significant changes made to the .config file:

- CT_PREFIX_DIR="\$\{PWD}/../../\$\{CT_TARGET}"  
   (Cygwin only) This causes the toolchain to be installed under C:\cross, which is where I keep my cross toolchains.
   There is a possibility that moving the toolchain to another location may not work in some cases
   (such as in a non-Cygwin environment) due to how Cygwin translates path names.
   I suspect it has something to do with cygwin1.dll becoming offended at finding itself in \<toolchain\>/bin
   rather than in C:/cygwin64/bin.
   If moving the install location breaks for you, you may have to adjust this setting and re-build the toolchain for your environment,
   or just keep the toolchains in C:\cross.

- CT_TARGET_CFLAGS="-ffixed-x18" or CT_TARGET_CFLAGS="-ffixed-r9"  
This causes the compiler to build libraries that do not use the platform register as defined in
the ARM or Aarch64 Procedure Call Standards (AAPCS):

  >"The role of register r9 is platform specific. A virtual platform may assign any role to this
register and must document this usage. For example, it may designate it as the static base (SB)
in a position-independent data model, or it may designate it as the thread register (TR) in an
environment with thread-local storage. The usage of this register may require that the value
held is persistent across all calls. A virtual platform that has no need for such a special
register may designate r9 as an additional callee-saved variable register."

    This is only needed if your bare metal thread switching code uses the platform register. 
Doing so enables significant optimization of bare metal thread switching.

- CT_TARGET_VENDOR="\<something useful\>"  
Since bare metal toolchains typically put "none" or "unknown" as the second field of the triplet,
which is uninformative, I decided to put helpful identifiers such as "openmp" or "uboot" here.

- CT_THREADS_NONE=y  
This is set, since the bare metal environment does not support Pthreads or any other known operating
system defined threading system. I am still learning OpenMP, but as far as I can tell at this point,
OpenMP does not explicitly depend on Pthreads, therefore it doesn't make sense that the GCC
build system enforces a dependency between OpenMP and Pthreads. Any Pthreads dependencies are hidden
within libgomp. To use OpenMP under bare metal, the threading mechanism must be provided by an
implementation of libgomp.

- CT_CC_GCC_LIBGOMP=y  
This flag enables OpenMP in the compiler. By default, the GCC config system will override this setting
if CT_THREADS_NONE=y is set. A couple modifications to crosstool-ng were required to overcome this.

- CT_GDB_CROSS is not set  
I was not able to get crosstool-ng to successfully build GDB. It has something to do with the version of
Python found by the configure script. Since I don't use GDB I simply turned this option off rather than
spending time debugging the problem. Since the Eclipse toolchain manger requires the presence of gdb
in the toolchain bin directory (even if it is not used), I copied in a gdb from another similar toolchain
and renamed it to match the triplet. I don't know if this gdb would work.

## Toolchain-specific comments

The ARMv8 toolchains are built for generic ARMv8 and multilib, but the ARMv7 versions
are built for specific processors. I did this to have better control of library generation
and hopefully better optimization for ARMv7. I am not expert at building GCC, so it
remains to be seen if I know what I am doing here.

- arm-uboot-eabi  
This toolchain is built for
    - Cortex-A9
    - NEON
    - aapcs-linux

    This toolchain is optimized for the NXP i.MX6Q. I was looking for a multi-core
ARM platform which is supported by Segger J-link and Ozone, and has an on-chip
trace buffer. The i.MX6Q meets all these requirements, and I found a Sabre Lite
board and several
Karo Electronics TX6Q-1010 SoM modules on e-Bay for a good price. Most other
readily available (and cheap) ARMv7-A implementations, such as Raspberry Pi
or the Rockchip RK3188, have only external trace ports, which requires developers
to purchase very expensive trace probes.

    The aapcs-linux setting causes the use of fixed-length enums rather than
the default variable length, which allows this toolchain to be used to build
u-boot and u-boot standalone apps. This is still experimental.

- arm-cortexm7  
Since the M7 is single-core it may not seem sensical to have an OpenMP-enabled
compiler for it, but I found it useful to debug OpenMP in a single-core,
multi-threaded environment. I will also use this toolchain for non-OpenMP
Cortex-M7 projects.



##Releases:
- v0.0    First experimenetal release.
- v0.0.1  Fixed packaging issue for Windows binaries.

