cmake_minimum_required(VERSION 2.8.10)
project(BCV-DSPLIB C CXX)

set(BCV-DSPLIB_VERSION 0.8)

# Configure the warning and code coverage suppression file
configure_file(
  "${BCV-DSPLIB_SOURCE_DIR}/CTestCustom.cmake.in"
  "${BCV-DSPLIB_BINARY_DIR}/CTestCustom.cmake"
  COPYONLY
)

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
set(CMAKE_MODULE_PATH "${BCV-DSPLIB_SOURCE_DIR}/CMAKE" ${CMAKE_MODULE_PATH})
#PIE depends on android api level???
#LAPACKE to skip default complex.h whichis not found in NDK :
#-DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE
if(ANDROID_NDK)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIE -pie -DADD_ -DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE")
else(ANDROID_NDK)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DADD_ -DHAVE_LAPACK_CONFIG_H  -DLAPACK_COMPLEX_STRUCTURE")
endif(ANDROID_NDK)
# --------------------------------------------------
if(ANDROID_NDK)
# export FC=/path/to/android-ndk-r9/toolchains/arm-linux-androideabi-4.8.0/prebuilt/linux-x86/bin/arm-linux-androideabi-gfortran
message ("**** CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)
if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  # gfortran
  message ("*** Fortran compiler: " ${Fortran_COMPILER_NAME})
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fPIE -pie -fPIC -fno-f2c -O3")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -fPIE -pie -fPIC -g")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-O0 -g")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")
else(ANDROID_NDK)
if (UNIX)
   if ( "${CMAKE_Fortran_COMPILER}" MATCHES "ifort" )
  set( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fltconsistency -fp_port" )
   endif ()
   if ( "${CMAKE_Fortran_COMPILER}" MATCHES "xlf" )
  set( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -qnosave -qstrict=none" )
   endif ()
# Delete libmtsk in linking sequence for Sun/Oracle Fortran Compiler.
# This library is not present in the Sun package SolarisStudio12.3-linux-x86-bin
   STRING(REPLACE \;mtsk\; \; CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES "${CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES}")
endif ()
endif(ANDROID_NDK)

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
set(BCV-DSPLIB_INSTALL_EXPORT_NAME dsplib-targets)

macro(dsplib_install_library lib)
  install(TARGETS ${lib}
    EXPORT ${BCV-DSPLIB_INSTALL_EXPORT_NAME}
    ARCHIVE DESTINATION lib${LIB_SUFFIX}
    LIBRARY DESTINATION lib${LIB_SUFFIX}
    RUNTIME DESTINATION bin
  )
endmacro()

# --------------------------------------------------
# Testing

enable_testing()
include(CTest)
enable_testing()
# --------------------------------------------------

# Organize output files.  On Windows this also keeps .dll files next
# to the .exe files that need them, making tests easy to run.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BCV-DSPLIB_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${BCV-DSPLIB_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${BCV-DSPLIB_BINARY_DIR}/lib)
# --------------------------------------------------
# Check for any necessary platform specific compiler flags
include( CheckDSPLIBCompilerFlags )
CheckDSPLIBCompilerFlags()

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
# DSPLIB
# User did not provide a DSPLIB Library but specified to search for one
#if( USE_OPTIMIZED_DSPLIB )
#  find_package( DSPLIB )
#endif (USE_OPTIMIZED_DSPLIB)

#message(STATUS "BUILD TESTING : ${BUILD_TESTING}" )
#if(BUILD_TESTING)
#  add_subdirectory(TESTING)
#endif(BUILD_TESTING)

#if(NOT BLAS_FOUND)
#  set(ALL_TARGETS ${ALL_TARGETS} blas)
#endif(NOT BLAS_FOUND)

#if(NOT LATESTDSPLIB_FOUND)
#  set(ALL_TARGETS ${ALL_TARGETS} dsplib)
#endif(NOT LATESTDSPLIB_FOUND)

#if(BUILD_TESTING OR DSPLIBE_WITH_TMG)
#  set(ALL_TARGETS ${ALL_TARGETS} tmglib)
#endif(BUILD_TESTING OR DSPLIBE_WITH_TMG)
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
# switch searching path to NDK
# --------------------------------------------------
if(ANDROID_NDK)
set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
endif(ANDROID_NDK)
# --------------------------------------------------
# CPACK Packaging

#SET(CPACK_PACKAGE_NAME "DSPLIB")
#SET(CPACK_PACKAGE_VENDOR "University of Tennessee, Univ. of California Berkeley, Univ. of Colorado Denver and NAG Ltd")
#SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "DSPLIB- Linear Algebra Package")
#set(CPACK_PACKAGE_VERSION_MAJOR 3)
#set(CPACK_PACKAGE_VERSION_MINOR 5)
#set(CPACK_PACKAGE_VERSION_PATCH 0)
#set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
#SET(CPACK_PACKAGE_INSTALL_DIRECTORY "DSPLIB")
#IF(WIN32 AND NOT UNIX)
## There is a bug in NSI that does not handle full unix paths properly. Make
## sure there is at least one set of four (4) backlasshes.
#SET(CPACK_NSIS_HELP_LINK "http:\\\\\\\\http://icl.cs.utk.edu/dsplib-forum")
#SET(CPACK_NSIS_URL_INFO_ABOUT "http:\\\\\\\\www.netlib.org/dsplib")
#SET(CPACK_NSIS_CONTACT "dsplib@eecs.utk.edu")
#SET(CPACK_NSIS_MODIFY_PATH ON)
#SET(CPACK_NSIS_DISPLAY_NAME "DSPLIB-${DSPLIB_VERSION}")
#set(CPACK_PACKAGE_RELOCATABLE "true")
#ELSE(WIN32 AND NOT UNIX)
#SET(CPACK_GENERATOR "TGZ")
#SET(CPACK_SOURCE_GENERATOR TGZ)
#SET(CPACK_SOURCE_PACKAGE_FILE_NAME "dsplib-${DSPLIB_VERSION}" )
#SET(CPACK_SOURCE_IGNORE_FILES ~$ .svn ${CPACK_SOURCE_IGNORE_FILES} )
#ENDIF(WIN32 AND NOT UNIX)
#INCLUDE(CPack)


# --------------------------------------------------
# By default static library
OPTION(BUILD_SHARED_LIBS "Build shared libraries" OFF )
OPTION(BUILD_STATIC_LIBS "Build static libraries" ON )
#OPTION(BUILD_SHARED_LIBS "Build shared libraries" ON )

# --------------------------------------------------
if(ANDROID_NDK)
set(ADB_LOG log)
set(DSP_DEP_STATICS
	${BLASLIBS}
	gfortran
	${CMAKE_THREAD_LIBS_INIT}
	${FFTSLIB}
	m
	${ADB_LOG}
	)
else(ANDROID_NDK)
set(DSP_DEP_STATICS
	${BLASLIBS}
	gfortran
	${CMAKE_THREAD_LIBS_INIT}
	${FFTSLIB}
	m
	)
endif(ANDROID_NDK)

# --------------------------------------------------
#define the main sources for later build
ADD_LIBRARY(dsp-main OBJECT
	helper.c
	matrix.c
	detrend.c
	radical.c
	queue.c
	spectra.c
	dsp.c
	)

# --------------------------------------------------
#build a shared lib
# --------------------------------------------------
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#libbcv-dsp.d.so
ADD_LIBRARY(bcv-dsp_${MACHINE_ARCH}.d SHARED
	$<TARGET_OBJECTS:dsp-main>
	)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#libbcv-dsp.so
ADD_LIBRARY(bcv-dsp_${MACHINE_ARCH} SHARED
	$<TARGET_OBJECTS:dsp-main>
	)

target_link_libraries(bcv-dsp_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
	)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")

# --------------------------------------------------
#build a static lib
# --------------------------------------------------
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#libbcv-dsp.d.a
ADD_LIBRARY(bcv-dsp_static_${MACHINE_ARCH}.d STATIC
	$<TARGET_OBJECTS:dsp-main>
	)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#libbcv-dsp.d.a
ADD_LIBRARY(bcv-dsp_static_${MACHINE_ARCH} STATIC
	$<TARGET_OBJECTS:dsp-main>
	)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")

# --------------------------------------------------
# unit test
# --------------------------------------------------
add_executable(mat_test
  mat_test.c
)

#the order is very important for atlas and lapack
if(1)
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(mat_test
			bcv-dsp_${MACHINE_ARCH}.d
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(mat_test
			bcv-dsp_${MACHINE_ARCH}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
else(1)
	if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(mat_test
			bcv-dsp_static_${MACHINE_ARCH}.d
			${DSP_DEP_STATICS}
		)
	else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
		target_link_libraries(mat_test
			bcv-dsp_static_${MACHINE_ARCH}
			${DSP_DEP_STATICS}
		)
	endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
endif(1)

# --------------------------------------------------
#gcc testblasc.c -o testblasc -I ../include/ -L ../build/lib -lcblas -latlas
add_executable(cblas_test
  cblas_test.c
)

#!!!the linking order of libs are quite important!!!
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(cblas_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
	)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(cblas_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
	)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
# --------------------------------------------------
add_executable(lapacke_test
  lapacke_test.c
)

#!!!the linking order of libs are quite important!!!
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(lapacke_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
	)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(lapacke_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
	)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
# --------------------------------------------------
add_executable(lapack_test
  lapack_test.c
)

#!!!the linking order of libs are quite important!!!
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(lapack_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
	)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(lapack_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
	)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#install(TARGETS test RUNTIME DESTINATION bin)

# --------------------------------------------------
add_executable(cq_test
  cq_test.c
)

#the order is very important for atlas and lapack
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(cq_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(cq_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")

# --------------------------------------------------
add_executable(spec_test
  spec_test.c
)

if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
#the order is very important for atlas and lapack
target_link_libraries(spec_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(spec_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
# --------------------------------------------------
add_executable(dsp_test
  dsp_test.c
)

#the order is very important for atlas and lapack
if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(dsp_test
	bcv-dsp_static_${MACHINE_ARCH}.d
	${DSP_DEP_STATICS}
)
else("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
target_link_libraries(dsp_test
	bcv-dsp_static_${MACHINE_ARCH}
	${DSP_DEP_STATICS}
)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
# --------------------------------------------------

# Export dsplib targets from the install tree, if any.
#set(_dsplib_config_install_guard_target "")
#if(ALL_TARGETS)
#  install(EXPORT dsplib-targets
#    DESTINATION lib/cmake/dsplib-${DSPLIB_VERSION})

  # Choose one of the dsplib targets to use as a guard for
  # dsplib-config.cmake to load targets from the install tree.
#  list(GET ALL_TARGETS 0 _dsplib_config_install_guard_target)
#endif()

# Export dsplib targets from the build tree, if any.
#set(_dsplib_config_build_guard_target "")
#if(ALL_TARGETS)
#  export(TARGETS ${ALL_TARGETS} FILE dsplib-targets.cmake)

#  # Choose one of the dsplib targets to use as a guard
#  # for lapack-config.cmake to load targets from the build tree.
#  list(GET ALL_TARGETS 0 _dsplib_config_build_guard_target)
#endif()

configure_file(${BCV-DSPLIB_SOURCE_DIR}/CMAKE/dsplib-config-version.cmake.in
  ${BCV-DSPLIB_BINARY_DIR}/dsplib-config-version.cmake @ONLY)
configure_file(${BCV-DSPLIB_SOURCE_DIR}/CMAKE/dsplib-config-build.cmake.in
  ${BCV-DSPLIB_BINARY_DIR}/dsplib-config.cmake @ONLY)

#configure_file(${CMAKE_CURRENT_SOURCE_DIR}/dsplib.pc.in ${CMAKE_CURRENT_BINARY_DIR}/dsplib.pc)
#  install(FILES
#  ${CMAKE_CURRENT_BINARY_DIR}/dsplib.pc
#  DESTINATION ${PKG_CONFIG_DIR}
#   )

configure_file(${BCV-DSPLIB_SOURCE_DIR}/CMAKE/dsplib-config-install.cmake.in
  ${BCV-DSPLIB_BINARY_DIR}/CMakeFiles/dsplib-config.cmake @ONLY)
install(FILES
  ${BCV-DSPLIB_BINARY_DIR}/CMakeFiles/dsplib-config.cmake
  ${BCV-DSPLIB_BINARY_DIR}/dsplib-config-version.cmake
  DESTINATION lib/cmake/dsplib-${BCV-DSPLIB_VERSION}
  )
