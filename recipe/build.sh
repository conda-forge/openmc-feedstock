#!/bin/bash
set -x
set -e

# Use newer C++ features with old SDK (https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk)
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

export CONFIGURE_ARGS=""

if [[ -n "$dagmc_variant" && "$dagmc_variant" != "nodagmc" ]]; then
  export CONFIGURE_ARGS="-DOPENMC_USE_DAGMC=ON ${CONFIGURE_ARGS}"
fi

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DOPENMC_USE_MPI=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DHDF5_PREFER_PARALLEL=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
fi

# Build and install executable
#
# The C++ unit tests are the only use of Catch2, and they are never run or
# installed by this recipe, so disable them with OPENMC_BUILD_TESTS=OFF instead
# of providing catch2 as a host requirement.
cmake ${CMAKE_ARGS} \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DHDF5_ROOT="${PREFIX}" \
      -DOPENMC_BUILD_TESTS=OFF \
      ${CONFIGURE_ARGS} \
      -S . \
      -B build
cmake build -LH
cmake --build build --parallel "${CPU_COUNT}"
cmake --install build

# Install Python API
"${PYTHON}" -m pip install . -vv --no-deps --no-build-isolation
