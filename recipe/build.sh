#!/bin/bash
set -x
set -e

# Use newer C++ features with old SDK (https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk)
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

export CONFIGURE_ARGS=""

if [[ -n "$dagmc" && "$dagmc" != "nodagmc" ]]; then
  export CONFIGURE_ARGS="-DOPENMC_USE_DAGMC=ON ${CONFIGURE_ARGS}"
fi

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DOPENMC_USE_MPI=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DHDF5_PREFER_PARALLEL=ON ${CONFIGURE_ARGS}"
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
fi

# Workaround for newer llvm versions, based on https://github.com/exasmr/openmc/pull/52
# TODO: Remove when not needed anymore
if [[ "$(uname -s)" == "Darwin" ]]; then
  export CXXFLAGS="${CXXFLAGS} -fno-relaxed-template-template-args"
fi

# for cross compilation on arm64
if [[ "$target_platform" == "oxs-arm64" ]]; then
  export CONDA_BUILD_CROSS_COMPILATION=1
fi

# Build and install executable
export root_dir=`pwd`
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
cd $root_dir

# Install Python API
$PYTHON -m pip install . --no-deps -vv
