#!bash

# Use crosstool-ng to build the cross toolchain, under control of the .config file.
ct-ng build

# Copy omp.h from the host cygwin install. It might not be the exact matching version for the toolchain that was built,
# but for the subset of OpenMP supported by bare metal it is probably good enough.
cp c:/cygwin64/lib/gcc/x86_64-w64-mingw32/12/include/omp.h c:/cross/arm-cortexm0p-eabi/lib/gcc/arm-cortexm0p-eabi/14.2.0/include

