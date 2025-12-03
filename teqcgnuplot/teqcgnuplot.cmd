@echo off
setlocal enabledelayedexpansion

REM Author: Ira.Sellars at noaa.gov
REM Created Date: 2025-12-01 13:11:46

echo Usage: 
echo     teqcplot.cmd [ssss] [yyyy] [ddd]
echo Search in folder [ssss] for rinex2 files of [yyyy]:[ddd]
echo and generates TEQC plots using Gnuplot library.
echo BRDC files will be downloaded if not found in [ssss] folder.
echo This script only works with daily ssssddd0.yyo files.
echo For example:
echo     teqcplot.cmd gode 2025 001
echo 

set "ssss=%1"
set "yyyy=%2"
set "ddd=%3"
set "yy=%yyyy:~2,2%"

REM --- Main script ---
set "frnx2=%ssss%%ddd%0.%yy%o"
set "fnavn=brdc%ddd%0.%yy%n"
set "fnavg=brdc%ddd%0.%yy%g"

if not exist "%ssss%\" (
    mkdir "%ssss%"
)

cd "%ssss%"

if not exist "%fnavn%" (
    echo Missing [%ssss%\%fnavn%]. Initiating download..
    set "fsite=brdc"
    set "ftype=n"
    call :downloadFromNGS
)

if not exist "%fnavg%" (
    echo Missing [%ssss%\%fnavg%]. Initiating download..
    set "fsite=brdc"
    set "ftype=g"    
    call :downloadFromNGS
)

if not exist "%frnx2%" (
    echo Missing [%ssss%\%frnx2%]. Initiating download..
    set "fsite=%ssss%"
    set "ftype=o"
    call :downloadFromNGS
)

if not exist "..\%ssss%\" goto check_fail
if not exist "..\%ssss%\%frnx2%" goto check_fail
if not exist "..\%ssss%\%fnavn%" goto check_fail
if not exist "..\%ssss%\%fnavg%" goto check_fail

REM TEQC-generate meta file
..\teqcgnuplot\bin\teqc.exe +meta "%frnx2%" > "%frnx2%.meta"

REM --- Get Sample Interval. Example: sample interval:         30.0000---
for /f "tokens=3" %%a in ('findstr /c:"sample interval:" "%frnx2%.meta"') do (
    set "sampint=%%a"
)
echo Sample Interval: %sampint%

REM --- Get observation date as YYYYMMDD. Example: start date & time:       2025-10-15 00:00:00.000 ---
set "stdate="
for /f "tokens=5 delims= " %%b in ('findstr /c:"start date & time:" "%frnx2%.meta"') do (
    set "tempstdate=%%b"
)
set "stdate=%tempstdate:-=%"
echo Observation Date: %stdate%

REM --- Multi-path moving window size ---
for /f "tokens=1 delims=." %%I in ("%sampint%") do set "sampint_int=%%I"
if "%sampint_int%" == "1" (
    set "mp_win=1500"
) else if "%sampint_int%" == "5" (
    set "mp_win=300"
) else if "%sampint_int%" == "15" (
    set "mp_win=100"
) else if "%sampint_int%" == "30" (
    set "mp_win=50"
) else (
    echo Warning: Unknown sample interval [%sampint_int%]. Setting default window.
    set "mp_win=50"
)

REM TEQC-generate slip file, summary file at 5deg elevation cut-off 
set "elecutoff=5"
..\teqcgnuplot\bin\teqc.exe -n_GLONASS 29 +doy +qc -plot -st "%stdate%000000.00" +ds 86400 -mp_win "%mp_win%" -set_mask "%elecutoff%" +slips "%frnx2%.slip" -nav "%fnavn%","%fnavg%" "%frnx2%"
REM Example: G13  11.68  -40.76: m21 slip @ 2025 288 01:01:30.000
REM          R16  10.11  116.66: m12 slip @ 2025 288 01:23:30.000

REM Remove any existing .tmp files generated from .slip file
del "%frnx2%.slip_*" >nul 2>&1

REM Create slip_* files
for /f "tokens=1-4 delims=: " %%a in ('findstr /r /v "^#" "%frnx2%.slip"') do (
    REM %%a is the PRN (G13, R16)
    REM %%b is the elevation
    REM %%c is the azimuth
    REM %%d is the slip type (i12, m12, m21, etc.)    
    REM Get constellations and slip types       
    set "flagslip=flagslip_%%d"
    if not defined !flagslip! (
        echo %%d >> %frnx2%.slip_tyu
        set "!flagslip!=1"
    )
    set "satsys=%%a"
    set "satsys=!satsys:~0,1!"
    set "flagsat=flagsat_!satsys!"
    if not defined !flagsat! (
        echo !satsys! >> %frnx2%.slip_ssu
        set "!flagsat!=1"
    )
    REM Append data (PRN, Elev, Azimuth, Constellation) to a tmp file named by slip type
    echo %%a %%b %%c !satsys! >> %frnx2%.slip_%%d    
)

for /f "usebackq" %%S in ("%frnx2%.slip_tyu") do (
    REM Call Gnuplot script to generate slip plots for each slip type
    ..\teqcgnuplot\bin\gnuplot.exe -c ..\teqcgnuplot\bin\gnuplot_teqcslip.gp "%frnx2%.slip_%%S" "%%S"
)

echo --- Process Complete ---
goto :eof

:downloadFromNGS
REM --- Function to Download and Extract a Specific File Type ---

set "fname=%fsite%%ddd%0.%yy%%ftype%"
if "%fsite%"=="brdc" (
    set "URL=https://geodesy.noaa.gov/corsdata/rinex/%yyyy%/%ddd%/%fname%.gz"
) else (
    set "URL=https://geodesy.noaa.gov/corsdata/rinex/%yyyy%/%ddd%/%fsite%/%fname%.gz"
)

if exist "%fname%" (
    echo File already exists locally: %fname%
    echo Skipping download.
) else (
    echo Attempting download of %fname%...
    curl -O "%URL%"

    if %ERRORLEVEL% == 0 (
        echo Download successful.
        echo Extracting %fname%.gz...
        gzip -d "%fname%.gz"
        if %ERRORLEVEL% == 0 (
            echo Extraction successful: %fname%
            rem del "%fname%"
        ) else (
            echo ERROR: Extraction failed for %fname%.
        )
    ) else (
        echo ERROR: Download failed for %fname%.gz. Check URL or connection.
    )
)
set "ftype="
set "fname="
set "URL="
goto :eof

:check_fail
    echo ERROR: Missing one or all of these files: 
    echo        %ssss%/%frnx2% 
    echo        %ssss%/%fnavn% 
    echo        %ssss%/%fnavg%
    echo   Global broadcast ephemeris files (brdc) can be downloaded at:
    echo        https://geodesy.noaa.gov/corsdata/rinex/yyyy/ddd/
    echo   Observation RINEX 2 files can be downloaded at:
    echo        https://geodesy.noaa.gov/corsdata/rinex/yyyy/ddd/ssss/
    echo   Unable to generate TEQC plots.
    exit /b 1
goto :eof



:eof
endlocal
goto :eof

