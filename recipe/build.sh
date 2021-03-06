#!/bin/bash


if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

for pkg in dijitso ufl instant fiat ffc; do
    echo "installing ${pkg}-${PKG_VERSION}"
    git clone -q --depth 1 -b ${pkg}-${PKG_VERSION} https://bitbucket.org/fenics-project/${pkg}.git
    pushd $pkg
    pip install --no-deps .
    popd
done

pkg=dolfin
echo "installing ${pkg}-${PKG_VERSION}"
git clone -q --depth 1 -b ${pkg}-${PKG_VERSION} https://bitbucket.org/fenics-project/${pkg}.git
pushd $pkg
# apply patches
git apply "${RECIPE_DIR}/swig-py3.patch"
if [[ "$(uname)" == "Darwin" ]]; then
    git apply "${RECIPE_DIR}/clang6-explicit-in-copy.patch"
fi

# DOLFIN
rm -rf build
mkdir build
cd build

export LIBRARY_PATH=$PREFIX/lib
export INCLUDE_PATH=$PREFIX/include

export BLAS_DIR=$LIBRARY_PATH

cmake .. \
  -DDOLFIN_ENABLE_OPENMP=off \
  -DDOLFIN_ENABLE_MPI=off \
  -DDOLFIN_ENABLE_PETSC=off \
  -DDOLFIN_ENABLE_HDF5=off \
  -DDOLFIN_ENABLE_VTK=off \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INCLUDE_PATH=$INCLUDE_PATH \
  -DCMAKE_LIBRARY_PATH=$LIBRARY_PATH \
  -DPYTHON_EXECUTABLE=$PYTHON || (cat CMakeFiles/CMakeError.log && exit 1)

make VERBOSE=1 -j${CPU_COUNT}
make install
