{ stdenv, fetchFromGitHub, cmake, ed, pkgconfig
, libunwind, git, rocm-cmake, rocminfo, hcc, hip, rocr
, doCheck ? false
, gtest }:
stdenv.mkDerivation rec {
  name = "rocrand";
  version = "1.8.2";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocRAND";
    rev = "v${version}";
    sha256 = "1593h4pza0hyw11k7rxnpdamc4iinj8xhjgg394c6v0fxki09z7j";
  };
  nativeBuildInputs = [ cmake ed git rocm-cmake pkgconfig ];
  buildInputs = [ hcc hip rocminfo libunwind rocr ]
    ++ stdenv.lib.optionals doCheck [ gtest ];

  # We first move the `project` command to before we `include` another
  # cmake file that looks for libraries. Then, cmake runs into
  # problems if including hcc and hip config files as they have
  # unguarded add_library calls, so we define HSA_HEADER and
  # HSA_LIBRARY ourselves.
#    printf '%s\n' 15m20 20-m15- w q | ed -s CMakeLists.txt
  # preConfigure = ''
  #   sed '/include(cmake\/SetToolchain.cmake)/d' -i CMakeLists.txt
  #   sed 's,project(rocRAND CXX),project(rocRAND CXX)\ninclude(cmake/SetToolchain.cmake),' -i CMakeLists.txt
  #   sed -e '/^[[:space:]]*find_package(hcc REQUIRED CONFIG PATHS .*$/ d' \
  #       -e '/^[[:space:]]*find_package(hip REQUIRED CONFIG PATHS .*$/ d' \
  #       -i cmake/Dependencies.cmake
  # '';
  cmakeFlags = [
    "-DHSA_HEADER=${rocr}/include"
    "-DHSA_LIBRARY=${rocr}/lib/libhsa-runtime64.so"
    "-DHIP_PLATFORM=hcc"
    "-DHIP_PATH=${hip}"
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ (let flag = if doCheck then "ON" else "OFF";
        in [ "-DBUILD_TEST=${flag} -DBUILD_BENCHMARK=${flag}" ]);
  postInstall = ''
    mkdir -p $out/include $out/lib
    cp -rs $out/hiprand/include/* $out/include
    cp -rs $out/rocrand/include/* $out/include
    cp -rs $out/hiprand/lib/* $out/lib
    cp -rs $out/rocrand/lib/* $out/lib
  '';
}