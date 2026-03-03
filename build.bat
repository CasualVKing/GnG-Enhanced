@echo off
setlocal

echo ============================================
echo  GnG Enhanced — Build Script
echo ============================================

:: Check for clean ROM
if not exist "rom\clean.sfc" (
    echo ERROR: rom\clean.sfc not found.
    echo Place your clean Super Ghouls 'n Ghosts ^(USA^) ROM at rom\clean.sfc
    pause
    exit /b 1
)

:: Check for asar
if not exist "tools\asar.exe" (
    echo ERROR: tools\asar.exe not found.
    echo Download asar from https://github.com/RPGHacker/asar/releases
    echo and place asar.exe in the tools\ folder.
    pause
    exit /b 1
)

:: Copy clean ROM to working copy
echo.
echo [1/2] Copying clean ROM...
copy /Y "rom\clean.sfc" "rom\gng_enhanced.sfc" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy ROM.
    pause
    exit /b 1
)

:: Apply patch
echo [2/2] Applying air control patch...
tools\asar.exe patches\air_control.asm rom\gng_enhanced.sfc
if errorlevel 1 (
    echo.
    echo *** PATCH FAILED ***
    echo Check the error messages above.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  SUCCESS! Patched ROM: rom\gng_enhanced.sfc
echo ============================================
echo.

:: Optional: launch emulator if configured
if defined GNG_EMULATOR (
    echo Launching emulator...
    start "" "%GNG_EMULATOR%" "rom\gng_enhanced.sfc"
) else (
    echo Tip: Set GNG_EMULATOR env var to auto-launch your emulator.
    echo Example: set GNG_EMULATOR=C:\path\to\BizHawk\EmuHawk.exe
)

endlocal
