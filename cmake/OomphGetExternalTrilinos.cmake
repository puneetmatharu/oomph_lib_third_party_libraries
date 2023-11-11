# cmake-format: off
# =============================================================================
# DESCRIPTION:
# ------------
#
# NOTE: The OpenBLAS installation automatically runs self-tests but it's hard
# to extract stats from them (partly because I don't know how a failed test
# would be reported; there's no executive summary.
#
# USAGE:
# ------
#
# ...to be filled in...
#
# EXAMPLE:
# --------
#
# ...to be filled in...
#
# =============================================================================
# cmake-format: on
include_guard()

set(TRILINOS_TARBALL_URL
    https://github.com/trilinos/Trilinos/archive/refs/tags/trilinos-release-14-4-0.tar.gz
)
set(TRILINOS_INSTALL_DIR "${OOMPH_THIRD_PARTY_INSTALL_DIR}/trilinos")

set(TRILINOS_OPTION_ARGS
    -DTrilinos_ENABLE_TESTS=OFF
    -DTrilinos_ENABLE_EXAMPLES=OFF
    -DTrilinos_ENABLE_ALL_PACKAGES=OFF
    -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF
    -DTrilinos_ENABLE_Amesos=ON
    -DTrilinos_ENABLE_Anasazi=ON
    -DTrilinos_ENABLE_AztecOO=ON
    -DTrilinos_ENABLE_Epetra=ON
    -DTrilinos_ENABLE_EpetraExt=ON
    -DTrilinos_ENABLE_Ifpack=ON
    -DTrilinos_ENABLE_ML=ON
    -DTrilinos_ENABLE_Teuchos=ON
    -DTrilinos_ENABLE_Triutils=ON
    -DTrilinos_INSTALL_LIBRARIES_AND_HEADERS=ON
    -DTrilinos_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
    -DTPL_ENABLE_BLAS=ON
    -DTPL_ENABLE_LAPACK=ON
    -DTPL_BLAS_LIBRARIES=${OpenBLAS_LIBRARIES}
    -DTPL_LAPACK_LIBRARIES=${OpenBLAS_LIBRARIES}
    -DTPL_ENABLE_MPI=${OOMPH_ENABLE_MPI})

if(OOMPH_ENABLE_MPI)
  if(NOT MPI_CXX_INCLUDE_DIRS)
    message(FATAL_ERROR "Requested MPI but MPI_CXX_INCLUDE_DIRS is not set!")
  endif()

  # ARGH this doesn't work. Can't seem to pass multiple include paths. Will just
  # take the first path Have to be careful to concatenate multi-path arguments
  # into a semicolon separated string before passing it to ExternalProject
  # string(JOIN $<SEMICOLON> MPI_BASE_DIR ${MPI_CXX_INCLUDE_DIRS})

  # Default to first entry of MPI_CXX_INCLUDE_DIRS as base directory
  list(GET MPI_CXX_INCLUDE_DIRS 0 MPI_BASE_DIR)

  # Loop over the include directories, look at its parent directory to see
  # whether it has the required bin/, include/, and lib/ dirs. Would prefer to
  # just pass MPI_CXX_INCLUDE_DIRS but there appear to be issues with making
  # sure multiple path values are interpreted correctly.
  foreach(MPI_INCLUDE_DIR IN LISTS MPI_CXX_INCLUDE_DIRS)
    cmake_path(GET MPI_INCLUDE_DIR PARENT_PATH MPI_DIR)
    message(STATUS "Checking if ${MPI_DIR} is the root MPI directory")

    # See if it has an include/ and lib/ directory (and optionally a bin/
    # directory)
    if((EXISTS "${MPI_DIR}/include") AND (EXISTS "${MPI_DIR}/lib"))
      set(MPI_BASE_DIR ${MPI_DIR})
      message(STATUS "Found base MPI directory: ${MPI_BASE_DIR}")
      if(EXISTS "${MPI_DIR}/bin")
        message(STATUS "Yay! It also contains a bin/ directory!")
      endif()
      break()
    else()
      message(
        STATUS "Couldn't find root MPI directory from MPI_CXX_INCLUDE_DIRS.")
      message(
        STATUS "For Trilinos I will default to: -DMPI_BASE_DIR=${MPI_BASE_DIR}")
    endif()
  endforeach()

  # Now append to the full list of arguments
  list(APPEND TRILINOS_OPTION_ARGS -DMPI_BASE_DIR=${MPI_BASE_DIR})
endif()

# Define how to configure/build/install the project
oomph_get_external_project_helper(
  PROJECT_NAME trilinos
  URL "${TRILINOS_TARBALL_URL}"
  INSTALL_DIR "${TRILINOS_INSTALL_DIR}"
  CONFIGURE_COMMAND ${CMAKE_COMMAND} --install-prefix=<INSTALL_DIR>
                    -G=${CMAKE_GENERATOR} ${TRILINOS_OPTION_ARGS} -B=build
  BUILD_COMMAND ${CMAKE_COMMAND} --build build -j ${NUM_JOBS}
  INSTALL_COMMAND ${CMAKE_COMMAND} --install build
  TEST_COMMAND ${CMAKE_CTEST_COMMAND} --test-dir build -j ${NUM_JOBS}
  INSTALL_BYPRODUCTS "")

# ---------------------------------------------------------------------------------
