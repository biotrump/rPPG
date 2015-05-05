#!/bin/bash
#Thomas Tsai <thomas@biotrump.com>
#temp for my workspace
if [ -z "$BIOTRUMP_DIR" ]; then
	echo "no shell ENV exported!"
	echo ". setup.sh to export .config"
	pushd ../..
	. setup.sh
	popd

	#libblis.a
	export BLIS_LIB_NAME=${BLIS_LIB_NAME:-blis}
	#libffts-x86_64.a
	export FFTS_LIB_NAME=ffts-${TARGET_ARCH}

	export LAPACK_LIB=${LAPACK_LIB:-${LAPACK_OUT}/lib}
	export LAPACKE_SRC=${LAPACKE_SRC:-${LAPACK_SRC}/LAPACKE}
	export CBLAS_SRC=${CBLAS_SRC:-${LAPACK_SRC}/CBLAS}
fi
export DSPLIB_NAME="bcv-dsp"
echo "****$rPPG_DIR"
echo "****$rPPG_OUT"

if [ ! -d ${rPPG_OUT} ]; then
	mkdir -p ${rPPG_OUT}
else
	rm -rf ${rPPG_OUT}/*
fi
pushd ${rPPG_OUT}
pwd

cmake -DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_OUT:FILEPATH=${FFTS_OUT} \
-DFFTS_LIB_NAME=${FFTS_LIB_NAME} \
-DDSPLIB_OUT:FILEPATH=${DSPLIB_OUT} \
-DV4L2_LIB_DIR:FILEPATH=${V4L2_LIB_DIR} -DV4L2_LIB_OUT:FILEPATH=${V4L2_LIB_OUT} \
-DDSPLIB_DIR:FILEPATH=${DSPLIB_DIR} -DDSPLIB_NAME:FILEPATH=${DSPLIB_NAME} \
-DATLAS_SRC:FILEPATH=${ATLAS_SRC} -DATLAS_OUT:FILEPATH=${ATLAS_OUT} \
-DPICO_DIR=${PICO_DIR} -DPICO_OUT=${PICO_OUT} \
-DTARGET_ARCH=${TARGET_ARCH} \
${rPPG_DIR}

#-DLAPACK_SRC:FILEPATH=${LAPACK_SRC} -DLAPACK_BUILD:FILEPATH=${LAPACK_BUILD} \
#-DLAPACK_LIB:FILEPATH=${LAPACK_LIB} -DLAPACKE_SRC:FILEPATH=${LAPACKE_SRC} \
#-DCBLAS_SRC:FILEPATH=${CBLAS_SRC} ..

make ${MAKE_FLAGS}

popd
