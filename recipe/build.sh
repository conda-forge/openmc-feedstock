#!/bin/bash
set -x
set -e

# Use newer C++ features with old SDK (https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk)
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

export CONFIGURE_ARGS=""

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DOPENMC_USE_MPI=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DHDF5_PREFER_PARALLEL=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
fi

# Build and install executable
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DHDF5_ROOT="${PREFIX}" \
      ${CONFIGURE_ARGS} \
      ..
make -j "${CPU_COUNT}"
make install
cd ..

# Install Python API
$PYTHON -m pip install . --no-deps -vv
