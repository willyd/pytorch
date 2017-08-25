

@echo off
cd "%~dp0"
cd "../.."

set BASE_DIR=%cd:\=/%
cd torch/lib

set INSTALL_DIR=%cd:\=/%/tmp_install
set PATH=%INSTALL_DIR%/bin;%PATH%
set BASIC_C_FLAGS= /DTH_INDEX_BASE=0 /I%INSTALL_DIR%/include /I%INSTALL_DIR%/include/TH /I%INSTALL_DIR%/include/THC
set BASIC_CUDA_FLAGS= -DTH_INDEX_BASE=0 -I%INSTALL_DIR%/include -I%INSTALL_DIR%/include/TH -I%INSTALL_DIR%/include/THC
set LDFLAGS=/LIBPATH:%INSTALL_DIR%/lib
set MKL_LIB_ROOT=C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64
set MKL_LIB_ROOT=%MKL_LIB_ROOT:\=/%
set MKL_INC_ROOT=C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\mkl\include
set MKL_INC_ROOT=%MKL_INC_ROOT:\=/%
set MKL_OMP_ROOT=C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\compiler\lib\intel64
set MKL_OMP_ROOT=%MKL_OMP_ROOT:\=/%

:: set TORCH_CUDA_ARCH_LIST=6.1

set C_FLAGS=%BASIC_C_FLAGS% /D_WIN32 /Z7 /EHa /DNOMINMAX
set LINK_FLAGS=/DEBUG:FULL

mkdir tmp_install

IF "%~1"=="--with-cuda" (
  set /a NO_CUDA=0
) ELSE (
  set /a NO_CUDA=1
)

call:build TH
call:build THS
call:build THNN

IF %NO_CUDA% EQU 0 (
  call:build THC
  call:build THCS
  call:build THCUNN
)

call:build THPP
call:build libshm_windows
call:build ATen

copy /Y tmp_install\lib\* .
copy /Y tmp_install\bin\* .
xcopy /Y THNN\generic\THNN.h .
xcopy /Y THCUNN\generic\THCUNN.h .

goto:eof

:build
@setlocal
  call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" amd64
  mkdir build\%~1
  cd build/%~1
  REM cmake ../../%~1 -G "Visual Studio 14 2015 Win64" ^
  cmake ../../%~1 -G "Ninja" ^
                  -DCMAKE_MODULE_PATH=%BASE_DIR%/cmake/FindCUDA ^
                  -DTorch_FOUND="1" ^
                  -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
                  -DCMAKE_C_FLAGS="%C_FLAGS%" ^
                  -DCMAKE_SHARED_LINKER_FLAGS="%LINK_FLAGS%" ^
                  -DCMAKE_CXX_FLAGS="%C_FLAGS% %CPP_FLAGS%" ^
                  -DCUDA_NVCC_FLAGS="%BASIC_CUDA_FLAGS%" ^
                  -DTH_INCLUDE_PATH="%INSTALL_DIR%/include" ^
                  -DTH_LIB_PATH="%INSTALL_DIR%/lib" ^
                  -DTH_LIBRARIES="%INSTALL_DIR%/lib/TH.lib" ^
                  -DTHS_LIBRARIES="%INSTALL_DIR%/lib/THS.lib" ^
                  -DTHC_LIBRARIES="%INSTALL_DIR%/lib/THC.lib" ^
                  -DTHCS_LIBRARIES="%INSTALL_DIR%/lib/THCS.lib" ^
                  -DATEN_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHNN_LIBRARIES="%INSTALL_DIR%/lib/THNN.lib" ^
                  -DTHCUNN_LIBRARIES="%INSTALL_DIR%/lib/THCUNN.lib" ^
                  -DTHPP_LIBRARIES="%INSTALL_DIR%/lib/libTHPP.lib" ^
                  -DTH_SO_VERSION=1 ^
                  -DTHC_SO_VERSION=1 ^
                  -DTHNN_SO_VERSION=1 ^
                  -DTHCUNN_SO_VERSION=1 ^
                  -DNO_CUDA=%NO_CUDA% ^
                  -DCMAKE_BUILD_TYPE=Release ^
                  -DCUDA_HOST_COMPILER:FILEPATH="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe" ^
                  -DWITH_BLAS=mkl ^
                  -DCMAKE_LIBRARY_PATH="%MKL_LIB_ROOT%;%MKL_OMP_ROOT%" ^
                  -DCMAKE_INCLUDE_PATH="%MKL_INC_ROOT%" ^
                  -DLAPACK_LIBRARIES="%MKL_LIB_ROOT%/mkl_rt.lib" -DLAPACK_FOUND=TRUE
                  :: debug/release

  cmake --build . --target install --config Release -- -j10 || exit /b 1
  cd ../..
@endlocal
goto:eof


