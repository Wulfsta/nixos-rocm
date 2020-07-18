{stdenv, fetchFromGitHub, cmake, roct, rocr, hip
, python, buildPythonPackage, fetchPypi, ply}:
let
  CppHeaderParser = buildPythonPackage rec {
    pname = "CppHeaderParser";
    version = "2.7.4";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0hncwd9y5ayk8wa6bqhp551mcamcvh84h89ba3labc4mdm0k0arq";
    };

    doCheck = false;
    propagatedBuildInputs = [ ply ];

    meta = with stdenv.lib; {
      homepage = http://senexcanis.com/open-source/cppheaderparser/;
      description = "Parse C++ header files and generate a data structure representing the class";
      license = licenses.bsd3;
      maintainers = [];
    };
  };
  pyenv = python.withPackages (ps: [CppHeaderParser]);
in stdenv.mkDerivation rec {
  name = "roctracer";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "roctracer";
    rev = "rocm-${version}";
    sha256 = "01kbcijdn40pvkdqdvkhznrk9kh4fz95cxh8w32y6ixiazcx2ddi";
  };
  src2 = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hsa-class";
    rev = "48bd99908cd289eea698141834b4509f68c9ac5c";
    sha256 = "09k0dh8dkgjq6kccjrkv2pmjni4bxc02k6fkw32fsvln1g9z9q3w";
  };
  nativeBuildInputs = [ cmake pyenv ];
  buildInputs = [ roct rocr hip ];
  preConfigure = ''
    export HIP_PATH=${hip}
    ln -s ${src2} "test/hsa"
  '';
  patchPhase = ''
    patchShebangs script
    patchShebangs bin
    patchShebangs test
    sed 's|/usr/bin/clang++|clang++|' -i cmake_modules/env.cmake
    sed -e 's|"libhip_hcc.so"|"${hip}/lib/libhip_hcc.so"|' \
        -i src/core/loader.h
  '';
  postFixup = ''
    patchelf --replace-needed libroctracer64.so.1 $out/roctracer/lib/libroctracer64.so.1 $out/roctracer/tool/libtracer_tool.so
    ln -s $out/roctracer/include/* $out/include
  '';

}
