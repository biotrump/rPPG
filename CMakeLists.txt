cmake_minimum_required(VERSION 2.8.10)
project(rPPG C CXX)

set(rPPG_VERSION 0.8)

set(CMAKE_VERBOSE_MAKEFILE "ON")

# Configure the warning and code coverage suppression file
#configure_file(
#  "${rPPG_SOURCE_DIR}/CTestCustom.cmake.in"
#  "${rPPG_BINARY_DIR}/CTestCustom.cmake"
#  COPYONLY
#)

message("CMAKE_SOURCE_DIR : ${CMAKE_SOURCE_DIR}")
message("PROJECT_NAME : ${PROJECT_NAME}")
message("rPPG_SOURCE_DIR : ${rPPG_SOURCE_DIR}")
message("rPPG_BINARY_DIR : ${rPPG_BINARY_DIR}")

# --------------------------------------------------
# Organize output files.  On Windows this also keeps .dll files next
# to the .exe files that need them, making tests easy to run.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${rPPG_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${rPPG_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${rPPG_BINARY_DIR}/lib)

#equivalent to "make VERBOSE=1"
set(CMAKE_VERBOSE_MAKEFILE "ON")

#equivalent to  "cmake -DCMAKE_BUILD_TYPE=Release"
#set(CMAKE_BUILD_TYPE "Debug")
#set(CMAKE_BUILD_TYPE "Release")

# --------------------------------------------------
# First, define all the compilation options.
# We default to debugging mode for developers.
option(DEBUG "Compile with debugging information" OFF)

if(DEBUG)
set(CMAKE_BUILD_TYPE "Debug")
endif(DEBUG)

option(PROFILE "Compile with profiling information" OFF)

if(ANDROID_NDK)
	option(HAVE_SSE "Compile with SSE for x86" OFF)
	option(HAVE_NEON "Compile with ARM NEON" OFF)
	set(MACHINE_ARCH	"arm")
else(ANDROID_NDK)
	option(HAVE_SSE "Compile with SSE for x86" ON)
	option(HAVE_NEON "Compile with ARM NEON" OFF)
	set(MACHINE_ARCH	"x86")
endif(ANDROID_NDK)

if(HAVE_SSE)
	add_definitions(-DHAVE_SSE=1)
endif(HAVE_SSE)

if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
  add_definitions(-DDEBUG)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0 -fPIC")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -g -O0 -fPIC -D_POSIX_C_SOURCE=200112L")
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
  add_definitions(-DARMA_NO_DEBUG)
  add_definitions(-DNDEBUG)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -O3 -fPIC -D_POSIX_C_SOURCE=200112L")
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")

# Profiling CFLAGS.  Turn profiling information on.
if(PROFILE)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pg")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg")
endif(PROFILE)

# Add the CMake directory for custon CMake modules
set(CMAKE_MODULE_PATH "${rPPG_SOURCE_DIR}/CMAKE" ${CMAKE_MODULE_PATH})
#PIE depends on android api level???
#LAPACKE to skip default complex.h whichis not found in NDK :
#-DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE
if(ANDROID_NDK)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIE -pie -DADD_ -DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE")
else(ANDROID_NDK)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DADD_ -DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE")
endif(ANDROID_NDK)

# --------------------------------------------------
set(V4L2_LIB_DIR $ENV{V4L2_LIB_DIR})
find_path(V4L2_INC capture-v4l2.h
			HINTS ${V4L2_LIB_DIR} )
message("INC:${V4L2_INC}" )
include_directories("${V4L2_INC}")

#finding libv4l2.a
if(ANDROID_NDK)
	find_library (V4L2-LIB
		NAMES v4l2-arm
		PATHS ${V4L2_LIB_DIR}/build_and/lib
		PATH_SUFFIXES lib
		NO_DEFAULT_PATH)
else(ANDROID_NDK)
	find_library (V4L2-LIB
		NAMES v4l2-x86
		PATHS ${V4L2_LIB_DIR}/build_x86/lib
		PATH_SUFFIXES lib
		NO_DEFAULT_PATH)
endif(ANDROID_NDK)
message("V4L2-LIB=${V4L2-LIB} ")
# --------------------------------------------------
#opencv should be built first!
set(OpenCV_DIR $ENV{OPENCV_OUT})
message("++++OpenCV_DIR:${OpenCV_DIR}")
FIND_PACKAGE( OpenCV REQUIRED)
if(OpenCV_FOUND)
	message("found")
	message( "OpenCV_INCLUDE_DIRS:${OpenCV_INCLUDE_DIRS}" )
	message( "OpenCV_INCLUDES:${OpenCV_INCLUDES}")
	message( "OpenCV_LIBRARIES:${OpenCV_LIBRARIES}")
	message( "OpenCV_LIBS:${OpenCV_LIBS}")
	message( "OpenCV_DEFINITIONS:${OpenCV_DEFINITIONS}")
else()
	message(FATAL_ERROR "openCV not foud")
endif()

message("*** OpenCV_LIBS:${OpenCV_LIBS}")
message("*** OpenCV_LIBRARIES:${OpenCV_LIBRARIES}")

#openMP to avoid link error : omp_xxx error!
# undefined reference to `GOMP_loop_dynamic_start
find_package(OpenMP)
if(OPENMP_FOUND)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

# --------------------------------------------------
# Make a target to generate the documentation.  If Doxygen isn't installed, then
# I guess this option will just be unavailable.
find_package(Doxygen)

if(ANDROID_NDK)
find_host_package(Doxygen)
endif(ANDROID_NDK)

if (DOXYGEN_FOUND)
  # Preprocess the Doxyfile.  This is done before 'make doc'.
  add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/Doxyfile
      PRE_BUILD
      COMMAND ${CMAKE_COMMAND} -D DESTDIR="${CMAKE_BINARY_DIR}" -P
          "${CMAKE_CURRENT_SOURCE_DIR}/CMake/GenerateDoxyfile.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      COMMENT "Creating Doxyfile to generate Doxygen documentation"
  )

  # Generate documentation.
  add_custom_target(doc
      COMMAND "${DOXYGEN_EXECUTABLE}" "${CMAKE_BINARY_DIR}/Doxyfile"
      DEPENDS "${CMAKE_BINARY_DIR}/Doxyfile"
      WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      COMMENT "Generating API documentation with Doxygen"
  )

  install(DIRECTORY ${CMAKE_BINARY_DIR}/doc/html
      DESTINATION share/doc/mlpack
      COMPONENT doc
      OPTIONAL
  )
endif (DOXYGEN_FOUND)

# --------------------------------------------------
find_package (Threads REQUIRED)
#message("CMAKE_THREAD_LIBS_INIT : ""${CMAKE_THREAD_LIBS_INIT}")
#message("Threads_INCLUDES  :" ${Threads_INCLUDES})
#message("Threads_LIBRARIES :" ${Threads_LIBRARIES})
#message("Threads_LIBS :" ${Threads_LIBS})
#if (Threads_FOUND)
#endif (Threads_FOUND)

# --------------------------------------------------
# Testing

enable_testing()
include(CTest)
enable_testing()
# --------------------------------------------------
# searching the header and lib
# --------------------------------------------------
option(USE_BLIS "Whether or not to use BLIS library instead of netlib BLAS" OFF)

message("BLIS_LIB_NAME:${BLIS_LIB_NAME}")
message("USE_BLIS:${USE_BLIS}")
message("BLISLIB_DIR:${BLISLIB_DIR}")

# --------------------------------------------------
# switch searching path to host, not NDK
# --------------------------------------------------
if(ANDROID_NDK)
set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )
endif(ANDROID_NDK)
# --------------------------------------------------

# --------------------------------------------------
if(USE_BLIS)
	message("BLIS_SRC=${BLIS_SRC}" )
	find_path(CBLAS_INC cblas.h
				HINTS ${BLIS_SRC}/frame/compat/cblas/src )
elseif(ATLAS_SRC)
	message("ATLAS_SRC=${ATLAS_SRC}" )
	find_path(CBLAS_INC cblas.h
				HINTS ${ATLAS_SRC}/include )
else(USE_BLIS)
	message("LAPACK_SRC=${LAPACK_SRC}" )
	find_path(CBLAS_INC cblas.h
				HINTS ${LAPACK_SRC}/CBLAS/include )
endif(USE_BLIS)

message("CBLAS_INC=${CBLAS_INC}" )
if(CBLAS_INC)
	include_directories("${CBLAS_INC}")
endif(CBLAS_INC)

# --------------------------------------------------
message("LAPACKE_SRC=${LAPACKE_SRC}" )
if(ATLAS_SRC)
	#lapacke.h
	find_path(LAPACKE_INC lapacke.h
				HINTS ${ATLAS_SRC}/LAPACK/LAPACKE/include )
	message("ATLAS_SRC LAPACKE_INC=${LAPACKE_INC}" )
	if(LAPACKE_INC)
		include_directories("${LAPACKE_INC}")
	endif(LAPACKE_INC)

	#ATLAS and LAPACK : all lapack, atlas libs
	#message(">>> ATLAS_OUT=${ATLAS_OUT}")
	#set(ATLAS_LIB "lapacke;lapack;ptlapack;ptf77blas;f77blas;f77refblas;ptcblas;tstatlas;cblas;f77blas;atlas")
	#!!!The lib order is quite important, Don't Change the order!!!
#	set(ATLAS_LIB "lapacke;lapack;f77refblas;cblas;f77blas;ptlapack;ptf77blas;ptcblas;tstatlas;atlas")
	set(ATLAS_LIB "lapacke;lapack;cblas;f77blas;ptlapack;ptcblas;atlas")
	foreach(alib ${ATLAS_LIB})
		UNSET(ATLASLIB CACHE)
		find_library (ATLASLIB
					NAMES ${alib}
					PATHS ${ATLAS_OUT}
					PATH_SUFFIXES lib
					NO_DEFAULT_PATH)
		message("ATLASLIB=${ATLASLIB} ")
		if(ATLASLIB)
			#link static lib
		#	ADD_LIBRARY(atlas-lib STATIC IMPORTED)
		#	SET_PROPERTY(TARGET atlas-lib PROPERTY IMPORTED_LOCATION ${ATLASLIB})
		#	UNSET(atlas-lib)
			#if(ATLASLIBS)
			#	set(ATLASLIBS "${ATLASLIBS}\n${ATLASLIB}")
			#else()
			#	set(ATLASLIBS ${ATLASLIB})
			#endif(ATLASLIBS)
			set(ATLASLIBS ${ATLASLIBS} ${ATLASLIB})
	#		message("ATLASLIBS=${ATLASLIBS}")
		endif(ATLASLIB)
	endforeach(alib)
	set(BLASLIBS ${ATLASLIBS})
else(ATLAS_SRC)
#Using LAPACK's headers instead of ATLAS
	find_path(LAPACKE_INC lapacke.h
				HINTS ${LAPACKE_SRC}/include )
	message("LAPACKE_INC=${LAPACKE_INC}" )
	if(LAPACKE_INC)
		include_directories("${LAPACKE_INC}")
	endif(LAPACKE_INC)

	#!!!the lib order is quite important!!!
	if(USE_BLIS)
		set(BLAS_LIBS "lapacke;lapack;tmglib")
	else(USE_BLIS)
		set(BLAS_LIBS "lapacke;lapack;cblas;blas;tmglib")
	endif(USE_BLIS)
	foreach(alib ${BLAS_LIBS})
		UNSET(BLASLIB CACHE)
		find_library (BLASLIB
					NAMES ${alib}
					PATHS ${LAPACK_LIB}
					PATH_SUFFIXES lib
					NO_DEFAULT_PATH)
		#message("BLASLIB=${BLASLIB} ")
		if(BLASLIB)
			set(BLASLIBS ${BLASLIBS} ${BLASLIB})
			#message("BLASLIBS=${BLASLIBS}")
		endif(BLASLIB)
	endforeach(alib)

	if(USE_BLIS)
		UNSET(BLASLIBS CACHE)
		find_library (BLISLIBS
					NAMES ${BLIS_LIB_NAME}
					PATHS ${BLISLIB_DIR}
					PATH_SUFFIXES lib
					NO_DEFAULT_PATH)
		#message("BLISLIBS=${BLISLIBS} ")
		set(BLASLIBS ${BLASLIBS} ${BLISLIBS})
	endif(USE_BLIS)
endif(ATLAS_SRC)
message("BLASLIBS=${BLASLIBS}")
# --------------------------------------------------
#find ffts
message("FFTS_DIR=${FFTS_DIR}" )

find_path(FFTS_INC ffts.h
			HINTS ${FFTS_DIR}/include )
message("**FFTS_INC=${FFTS_INC}" )
if(FFTS_INC)
	include_directories("${FFTS_INC}")
endif(FFTS_INC)

message("FFTS_LIB_DIR=${FFTS_LIB_DIR} ")
message("**FFTS_LIB_NAME=${FFTS_LIB_NAME}")
message("**FFTS_LIB_DIR=${FFTS_LIB_DIR}")
UNSET(FFTSLIB CACHE)
find_library (FFTSLIB
			NAMES ${FFTS_LIB_NAME}
			PATHS ${FFTS_LIB_DIR}
			PATH_SUFFIXES lib
			NO_DEFAULT_PATH)
message("**FFTSLIB=${FFTSLIB} ")
if(FFTSLIB)
	#link static lib
#	message("FFTSLIB=${FFTSLIB}")
endif(FFTSLIB)

# --------------------------------------------------
#find libdsp
message("DSPLIB_SRC=${DSPLIB_SRC}" )

find_path(DSP_INC dsp-lib.h
			HINTS ${DSPLIB_SRC} )
message("**DSP_INC=${DSP_INC}" )
if(DSP_INC)
	include_directories("${DSP_INC}")
endif(DSP_INC)

message("**DSPLIB_BIN=${DSPLIB_BIN} ")
message("**DSPLIB_NAME=${DSPLIB_NAME}")

#libbcv-dsp_x86
find_library (DSPLIB
			NAMES ${DSPLIB_NAME}
			PATHS ${DSPLIB_BIN}
			PATH_SUFFIXES lib
			NO_DEFAULT_PATH)
message("**DSPLIB=${DSPLIB} ")
if(DSPLIB)
	#link static lib
	message("DSPLIB=${DSPLIB}")
endif(DSPLIB)

# --------------------------------------------------
# switch searching path to NDK
# --------------------------------------------------
if(ANDROID_NDK)
set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
endif(ANDROID_NDK)

#the order is very important for atlas and lapack
# --------------------------------------------------
add_executable(v4l2-play
	v4l2-play.c
)

if(1)
#.so
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(v4l2-play
			${DSPLIB}
			${OpenCV_LIBS}
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(v4l2-play
			${DSPLIB}
			${OpenCV_LIBS}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
else(1)
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(v4l2-play
			${DSPLIB}.d
			${DSP_DEP_STATICS}
			${OpenCV_LIBS}
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(v4l2-play
			${DSPLIB}
			${DSP_DEP_STATICS}
			${OpenCV_LIBS}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
endif(1)
# --------------------------------------------------
add_executable(pulse-v4l2
	pulse-v4l2.c
#	cam-play.c
#  v4l2-cap.c
)

if(1)
#.so
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(pulse-v4l2
			${DSPLIB}
			${OpenCV_LIBS}
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(pulse-v4l2
			${DSPLIB}
			${OpenCV_LIBS}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
else(1)
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(pulse-v4l2
			${DSPLIB}.d
			${DSP_DEP_STATICS}
			${OpenCV_LIBS}
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(pulse-v4l2
			${DSPLIB}
			${DSP_DEP_STATICS}
			${OpenCV_LIBS}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
endif(1)
