@echo off
setlocal EnableExtensions DisableDelayedExpansion
title C / C++ to EXE - Automated Builder
color 0B
set "BATDIR=%~dp0"

echo.
echo  ==========================================
echo       C / C++ to EXE - Automated Builder
echo  ==========================================
echo.

rem Stage 1: find an existing compiler. These checks are local and should be quick.
echo [1/4] Detecting GCC/G++ in PATH and known local compiler folders...
echo [INFO] Local checks run first; no package manager or network is queried here.
set "GCC="
set "GXX="
echo [CHECK] gcc.exe on PATH:
where gcc.exe 2>nul
if errorlevel 1 (
    echo [INFO] gcc.exe was not found on PATH.
) else (
    set "GCC=gcc.exe"
)
echo [CHECK] g++.exe on PATH:
where g++.exe 2>nul
if errorlevel 1 (
    echo [INFO] g++.exe was not found on PATH.
) else (
    set "GXX=g++.exe"
)
if defined GCC if defined GXX goto :compiler_ready

rem Search common compiler folders, without querying the network.
echo [2/4] Checking common MSYS2 installation folders...
for %%D in ("C:\msys64\ucrt64\bin" "C:\msys64\mingw64\bin" "C:\msys64\clang64\bin" "%LOCALAPPDATA%\Programs\msys64\ucrt64\bin" "%LOCALAPPDATA%\msys64\ucrt64\bin" "%USERPROFILE%\scoop\apps\msys2\current\ucrt64\bin") do (
    if exist "%%~D\gcc.exe" if not defined GCC set "GCC=%%~D\gcc.exe"
    if exist "%%~D\g++.exe" if not defined GXX set "GXX=%%~D\g++.exe"
)
if defined GCC if defined GXX goto :compiler_ready

rem Find an MSYS2 installation even if GCC has not been installed into it yet.
echo [INFO] Checking whether MSYS2 is installed in common local folders...
set "MSYSROOT="
for %%D in ("C:\msys64" "%LOCALAPPDATA%\Programs\msys64" "%LOCALAPPDATA%\msys64" "%USERPROFILE%\scoop\apps\msys2\current") do (
    if exist "%%~D\usr\bin\bash.exe" if not defined MSYSROOT set "MSYSROOT=%%~D"
)
if defined MSYSROOT goto :msys2_found

echo [INFO] No compiler or MSYS2 installation found in common locations.
echo [CHECK] Looking for winget.exe...
where winget.exe 2>nul
if errorlevel 1 (
    echo [ERROR] Windows Package Manager ^(winget^) was not found.
    echo Install MSYS2 from https://www.msys2.org/ and then rerun this tool.
    pause
    exit /b 1
)

echo.
echo [INFO] MSYS2 is needed because no usable GCC/G++ compiler or MSYS2 install was found.
echo [INFO] winget will download and run the MSYS2 installer. Its output will remain visible.
echo [INFO] This requires internet access and may take several minutes.
choice /c YN /n /m "Install MSYS2 with winget now? [Y/N] "
if errorlevel 2 (
    echo [INFO] Installation cancelled. Install MSYS2 from https://www.msys2.org/ and rerun this BAT.
    pause
    exit /b 1
)
echo.
echo [3/4] Starting the interactive MSYS2 installation through winget...
echo [INFO] Wait for the installer to finish; do not close this window.
echo.
winget install --id MSYS2.MSYS2 --exact --source winget --interactive
set "WINGET_RC=%ERRORLEVEL%"

rem Whether winget installed it now or reported that it was already installed,
rem detect the installation locally before deciding whether to stop.
set "MSYSROOT="
for %%D in ("C:\msys64" "%LOCALAPPDATA%\Programs\msys64" "%LOCALAPPDATA%\msys64" "%USERPROFILE%\scoop\apps\msys2\current") do (
    if exist "%%~D\usr\bin\bash.exe" if not defined MSYSROOT set "MSYSROOT=%%~D"
)
if defined MSYSROOT goto :msys2_found

echo.
echo [ERROR] MSYS2 was not found after the winget step. winget exit code: %WINGET_RC%
echo Check the installer output above. If needed, install MSYS2 manually from https://www.msys2.org/
pause
exit /b 1

:msys2_found
if defined WINGET_RC if not "%WINGET_RC%"=="0" echo [WARN] winget returned code %WINGET_RC%, but an MSYS2 installation was found; validating it now.
echo [OK] MSYS2 installation found at: "%MSYSROOT%"
echo [INFO] Checking its compiler folders and package manager next.

rem Re-check compiler binaries under the detected root before using pacman.
if exist "%MSYSROOT%\ucrt64\bin\gcc.exe" set "GCC=%MSYSROOT%\ucrt64\bin\gcc.exe"
if exist "%MSYSROOT%\ucrt64\bin\g++.exe" set "GXX=%MSYSROOT%\ucrt64\bin\g++.exe"
if exist "%MSYSROOT%\mingw64\bin\gcc.exe" if not defined GCC set "GCC=%MSYSROOT%\mingw64\bin\gcc.exe"
if exist "%MSYSROOT%\mingw64\bin\g++.exe" if not defined GXX set "GXX=%MSYSROOT%\mingw64\bin\g++.exe"
if exist "%MSYSROOT%\clang64\bin\gcc.exe" if not defined GCC set "GCC=%MSYSROOT%\clang64\bin\gcc.exe"
if exist "%MSYSROOT%\clang64\bin\g++.exe" if not defined GXX set "GXX=%MSYSROOT%\clang64\bin\g++.exe"
if defined GCC if defined GXX goto :compiler_ready

if not exist "%MSYSROOT%\usr\bin\bash.exe" (
    echo [ERROR] MSYS2 bash.exe was not found under "%MSYSROOT%".
    pause
    exit /b 1
)

echo [4/4] Checking the local MSYS2 package database...
echo [INFO] The following pacman query is local and does not contact package servers.
echo.
"%MSYSROOT%\usr\bin\bash.exe" -c "/usr/bin/pacman -Q mingw-w64-ucrt-x86_64-gcc"
if errorlevel 1 (
    echo.
    echo [INFO] GCC is not installed. pacman will now synchronize repository databases and resolve downloads.
    echo [INFO] pacman output and its confirmation prompt will be visible. This may take several minutes.
    choice /c YN /n /m "Install the MSYS2 UCRT64 GCC/G++ package now? [Y/N] "
    if errorlevel 2 (
        echo [INFO] Package installation cancelled.
        pause
        exit /b 1
    )
    echo.
    echo [INFO] Starting pacman package installation...
    "%MSYSROOT%\usr\bin\bash.exe" -lc "pacman -S --needed mingw-w64-ucrt-x86_64-gcc"
    if errorlevel 1 (
        echo.
        echo [ERROR] pacman failed to install GCC. Check the visible output above and your network connection.
        echo If MSYS2 reports that core packages need a full system update or terminal restart, follow its instructions and rerun this BAT.
        pause
        exit /b 1
    )
) else (
    echo [INFO] The GCC package is registered locally; no package download is needed unless its compiler files are missing.
)

echo [INFO] Verifying GCC and G++ are available after the package check...
if exist "%MSYSROOT%\ucrt64\bin\gcc.exe" set "GCC=%MSYSROOT%\ucrt64\bin\gcc.exe"
if exist "%MSYSROOT%\ucrt64\bin\g++.exe" set "GXX=%MSYSROOT%\ucrt64\bin\g++.exe"
if not defined GCC (
    echo [ERROR] gcc.exe was not found after pacman completed.
    pause
    exit /b 1
)
if not defined GXX (
    echo [ERROR] g++.exe was not found after the package check/install.
    echo [ERROR] Check that the MSYS2 UCRT64 GCC package installed correctly.
    pause
    exit /b 1
)

:compiler_ready
echo [INFO] Running the GCC version check; output is shown below.
"%GCC%" --version
if errorlevel 1 (
    echo [ERROR] GCC was found but could not run: "%GCC%"
    pause
    exit /b 1
)
echo [INFO] Running the G++ version check; output is shown below.
"%GXX%" --version
if errorlevel 1 (
    echo [ERROR] G++ was found but could not run: "%GXX%"
    pause
    exit /b 1
)
echo [OK] C compiler:   "%GCC%"
echo [OK] C++ compiler: "%GXX%"
echo [INFO] Source filenames without a path are searched beside this BAT first.
echo [INFO] Output filenames without a path are saved beside this BAT.
echo.

:ask_source
set "SRC="
set /p "SRC=Enter C/C++ source file (.c/.cpp/.cc/.cxx; filename or full path): "
if not defined SRC (
    echo [ERROR] Please enter a source file.
    goto :ask_source
)

rem Remove surrounding quotation marks supplied by the user.
set "SRC=%SRC:"=%"
if not defined SRC (
    echo [ERROR] Please enter a valid source file.
    goto :ask_source
)

echo [INFO] Resolving and validating the source path...
rem Prefer files relative to this BAT's directory; absolute paths still work.
if exist "%BATDIR%%SRC%" set "SRC=%BATDIR%%SRC%"
if not exist "%SRC%" (
    echo [ERROR] File not found: "%SRC%"
    echo Enter a filename beside this BAT, a relative path, or a full path.
    goto :ask_source
)

for %%F in ("%SRC%") do (
    set "SRCFULL=%%~fF"
    set "EXT=%%~xF"
    set "SRCDIR=%%~dpF"
    set "SRCBASE=%%~nF"
)

if /i "%EXT%"==".c" goto :c_source
if /i "%EXT%"==".cpp" goto :cpp_source
if /i "%EXT%"==".cc" goto :cpp_source
if /i "%EXT%"==".cxx" goto :cpp_source
echo [ERROR] Unsupported extension "%EXT%". Use .c, .cpp, .cc, or .cxx.
goto :ask_source

:c_source
set "COMPILER=%GCC%"
goto :output_name

:cpp_source
set "COMPILER=%GXX%"

:output_name
echo.
set "OUTNAME="
set /p "OUTNAME=Enter output EXE name or path (e.g. MyApp.exe or C:\Apps\MyApp.exe): "
if not defined OUTNAME (
    echo [ERROR] Output name cannot be empty.
    goto :output_name
)
set "OUTNAME=%OUTNAME:"=%"
if not defined OUTNAME (
    echo [ERROR] Invalid output name.
    goto :output_name
)

rem Reject a path that ends with a directory separator (no filename supplied).
if "%OUTNAME:~-1%"=="\" (
    echo [ERROR] Include an executable filename, not just a directory.
    goto :output_name
)
if "%OUTNAME:~-1%"=="/" (
    echo [ERROR] Include an executable filename, not just a directory.
    goto :output_name
)

rem Remove a trailing .exe so exactly one .exe extension is appended.
if /i "%OUTNAME:~-4%"==".exe" set "OUTNAME=%OUTNAME:~0,-4%"
if not defined OUTNAME (
    echo [ERROR] Invalid output name.
    goto :output_name
)
if "%OUTNAME:~-1%"=="\" (
    echo [ERROR] Include an executable filename, not just a directory.
    goto :output_name
)
if "%OUTNAME:~-1%"=="/" (
    echo [ERROR] Include an executable filename, not just a directory.
    goto :output_name
)

for %%F in ("%OUTNAME%") do set "OUTLEAF=%%~nxF"
if not defined OUTLEAF (
    echo [ERROR] The output path does not contain a filename.
    goto :output_name
)
rem Reject characters Windows cannot use in a filename.
if not "%OUTLEAF%"=="%OUTLEAF:<=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)
if not "%OUTLEAF%"=="%OUTLEAF:>=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)
if not "%OUTLEAF%"=="%OUTLEAF::=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)
if not "%OUTLEAF%"=="%OUTLEAF:|=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)
if not "%OUTLEAF%"=="%OUTLEAF:?=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)
if not "%OUTLEAF%"=="%OUTLEAF:*=%" (
    echo [ERROR] The output filename contains an invalid character.
    goto :output_name
)

echo [INFO] Resolving the output path and checking directory access...
rem A bare filename always goes beside this BAT, regardless of the current directory.
if /i "%OUTNAME%"=="%OUTLEAF%" goto :output_bare

rem For a relative path, prefer resolving it beside this BAT.
set "CANDIDATEFULL="
set "CANDIDATEDIR="
for %%F in ("%BATDIR%%OUTNAME%") do (
    set "CANDIDATEFULL=%%~fF"
    set "CANDIDATEDIR=%%~dpF"
)
if exist "%CANDIDATEDIR%." goto :test_candidate_output

goto :try_original_output

:test_candidate_output
rem Check that the target directory is writable before choosing it.
set "TESTFILE=%CANDIDATEDIR%c_cpp2exe_write_test_%RANDOM%_%RANDOM%.tmp"
> "%TESTFILE%" echo write-test 2>nul
if not exist "%TESTFILE%" goto :try_original_output
del "%TESTFILE%" >nul 2>nul
set "OUTFILE=%CANDIDATEFULL%.exe"
goto :output_ready

:try_original_output
rem Try the path exactly as entered (useful for absolute paths and CWD-relative paths).
set "OUTFULL="
set "OUTDIR="
for %%F in ("%OUTNAME%") do (
    set "OUTFULL=%%~fF"
    set "OUTDIR=%%~dpF"
    set "OUTLEAF=%%~nxF"
)
if not exist "%OUTDIR%." goto :fallback_output
set "TESTFILE=%OUTDIR%c_cpp2exe_write_test_%RANDOM%_%RANDOM%.tmp"
> "%TESTFILE%" echo write-test 2>nul
if not exist "%TESTFILE%" goto :fallback_output
del "%TESTFILE%" >nul 2>nul
set "OUTFILE=%OUTFULL%.exe"
goto :output_ready

:fallback_output
echo [WARN] The requested output directory does not exist or is not writable.
echo [WARN] Falling back to this BAT file's directory.
set "OUTFILE=%BATDIR%%OUTLEAF%.exe"
goto :output_ready

:output_bare
set "OUTFILE=%BATDIR%%OUTLEAF%.exe"

:output_ready
echo.
if exist "%OUTFILE%" (
    echo [WARN] The output file already exists: "%OUTFILE%"
    choice /c YN /n /m "Replace this executable? [Y/N] "
    if errorlevel 2 goto :output_name
)

echo [INFO] Compiling source now. Compilation can take time; compiler output is shown live.
echo Source: "%SRCFULL%"
echo Output: "%OUTFILE%"
echo.

if /i "%EXT%"==".c" (
    "%COMPILER%" -O2 "%SRCFULL%" -o "%OUTFILE%"
) else (
    "%COMPILER%" -O2 -static-libgcc -static-libstdc++ "%SRCFULL%" -o "%OUTFILE%"
)
if errorlevel 1 (
    echo.
    echo [ERROR] Compilation failed. Check the compiler messages above.
    pause
    exit /b 1
)

echo [INFO] Verifying the generated executable...
if not exist "%OUTFILE%" (
    echo [ERROR] Compiler reported success but output was not found.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Executable created:
echo "%OUTFILE%"
echo.
choice /c YN /n /m "Run the EXE now? [Y/N] "
if errorlevel 2 goto :done
echo.
"%OUTFILE%"
echo.
:done
echo Finished.
pause
exit /b 0
