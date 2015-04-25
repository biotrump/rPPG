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

#export DSP_HOME=${HOME}/path/to/dsp
export BLIS_SRC=${DSP_HOME}/blis
export BLISLIB=${BLISLIB:-${BLIS_SRC}/lib/sandybridge/libblis.a}
#x86
export BLISLIB_DIR=${BLISLIB_DIR:-${BLIS_SRC}/lib/sandybridge}
#libblis.a
export BLIS_LIB_NAME=${BLIS_LIB_NAME:-blis}

export FFTS_DIR=${DSP_HOME}/ffts
export FFTS_LIB_DIR=${FFTS_DIR}/lib
#libffts-x86.a
export FFTS_LIB_NAME=ffts-x86

export ATLAS_SRC=${DSP_HOME}/ATLAS
export ATLAS_OUT=${ATLAS_SRC}/build_x86
export LAPACK_SRC=${LAPACK_SRC:-${DSP_HOME}/LAPACK}
export LAPACK_BUILD=${LAPACK_BUILD:-${LAPACK_SRC}/build-x86}
export LAPACK_LIB=${LAPACK_LIB:-${LAPACK_BUILD}/lib}
export LAPACKE_SRC=${LAPACKE_SRC:-${LAPACK_SRC}/LAPACKE}
export CBLAS_SRC=${CBLAS_SRC:-${LAPACK_SRC}/CBLAS}

if [ ! -d build_x86 ]; then
mkdir build_x86
else
	rm -rf build_x86/*
fi
pushd build_x86

cmake -DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DATLAS_SRC:FILEPATH=${ATLAS_SRC} -DATLAS_OUT:FILEPATH=${ATLAS_OUT} \
-DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DFFTS_LIB_NAME=${FFTS_LIB_NAME} -DHAVE_SSE=1 ..

#-DLAPACK_SRC:FILEPATH=${LAPACK_SRC} -DLAPACK_BUILD:FILEPATH=${LAPACK_BUILD} \
#-DLAPACK_LIB:FILEPATH=${LAPACK_LIB} -DLAPACKE_SRC:FILEPATH=${LAPACKE_SRC} \
#-DCBLAS_SRC:FILEPATH=${CBLAS_SRC} ..

make -j${CORE_COUNT}

popd
