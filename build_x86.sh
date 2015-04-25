#!/bin/bash
#Thomas Tsai <thomas@biotrump.com>
#temp for my workspace

case $(uname -s) in
  Darwin)
    CONFBUILD=i386-apple-darwin`uname -r`
    HOSTPLAT=darwin-x86
    CORE_COUNT=`sysctl -n hw.ncpu`
  ;;
  Linux)
    CONFBUILD=x86-unknown-linux
    HOSTPLAT=linux-`uname -m`
    CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
  ;;
CYGWIN*)
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
  *) echo $0: Unknown platform; exit
esac

arm=${arm:-arm}
echo arm=$arm
case arm in
  arm)
    TARGPLAT=arm-linux-androideabi
    ARCHI=arm
    CONFTARG=arm-eabi
  ;;
  x86)
    TARGPLAT=x86
    ARCHI=x86
    CONFTARG=x86
  ;;
  mips)
  ## probably wrong
    TARGPLAT=mipsel-linux-android
    ARCHI=mips
    CONFTARG=mips
  ;;
  *) echo $0: Unknown target; exit
esac

export BLIS_SRC=${HOME}/build/libFLAME/blis
export BLISLIB=${BLISLIB:-${HOME}/build/libFLAME/blis/lib/sandybridge/libblis.a}
#x86
export BLISLIB_DIR=${BLISLIB:-${HOME}/build/libFLAME/blis/lib/sandybridge}
#libblis.a
export BLIS_LIB_NAME=${BLIS_LIB_NAME:-blis}

export FFTS_DIR=${HOME}/build/FFT/FFTS/git
export FFTS_LIB_DIR=${HOME}/build/FFT/FFTS/git/lib
#libffts-x86.a
export FFTS_LIB_NAME=ffts-x86

export ATLAS_SRC=${HOME}/build/BLAS/ATLAS/git
export ATLAS_OUT=${HOME}/build/BLAS/ATLAS/git/build
export LAPACK_SRC=${LAPACK_SRC:-${HOME}/build/LAPACK/svn/github}
export LAPACK_BUILD=${LAPACK_BUILD:-${HOME}/build/LAPACK/svn/github/build-andoid}
export LAPACK_LIB=${LAPACK_LIB:-${LAPACK_BUILD}/lib}
export LAPACKE_SRC=${LAPACKE_SRC:-${LAPACK_SRC}/LAPACKE}
export CBLAS_SRC=${CBLAS_SRC:-${LAPACK_SRC}/CBLAS}

export BUILD_HOME=${BUILD_HOME:-$HOME/build}
export DSP_HOME=${DSP_HOME:-`pwd`}

if [ ! -d $DSP_HOME/build ]; then
mkdir $DSP_HOME/build
else
	rm -rf $DSP_HOME/build/*
fi
pushd $DSP_HOME/build

cmake -DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DATLAS_SRC:FILEPATH=${ATLAS_SRC} -DATLAS_OUT:FILEPATH=${ATLAS_OUT} \
-DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DFFTS_LIB_NAME=${FFTS_LIB_NAME} ..

#-DLAPACK_SRC:FILEPATH=${LAPACK_SRC} -DLAPACK_BUILD:FILEPATH=${LAPACK_BUILD} \
#-DLAPACK_LIB:FILEPATH=${LAPACK_LIB} -DLAPACKE_SRC:FILEPATH=${LAPACKE_SRC} \
#-DCBLAS_SRC:FILEPATH=${CBLAS_SRC} ..

-j${CORE_COUNT}

popd
