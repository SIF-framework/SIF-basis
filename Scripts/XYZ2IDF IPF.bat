@ECHO OFF
REM ******************************************************
REM * SIF-basis v2.1.0 (Sweco)                           *
REM *                                                    *
REM * XYZ2IDF - IPF                                      *
REM * DESCRIPTION                                        *
REM *   Interpolates IPF-file with PCG/Kriging method in *
REM *   iMOD. PCG = Preconditioned Conjugate Gradient    *
REM *   interpolation                                    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)               *
REM * VERSION: 2.0.1                                     *
REM * MODIFICATIONS                                      *
REM *   2017-09-26 Initial version                       *
REM ******************************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH: Path with source IPF-file
REM SOURCEFILE: Filename for source IPF-file
REM X/Y/Z: Specify X, Y and Z-column indices (one based), or leave empty to use default of 0 and 1 (and 2 if levelselection is specified)
REM WINDOW: Extent (comma seperated xll, yll, xur, yur) or leave empty to use entire IPF
REM GRIDFUNC: Function for interpolation/gridding: MEAN, MIN, MAX, PERC, PCG or SKRIGING/OKRIGING. See iMOD-manual for details
REM CELLSIZE:Cellsize of resulting IDF-file
REM IDFNODATA: NoData-value for resulting IDF-file
REM RESULTPATH: Path to resulting IDF-file
REM RESULTFILE: Filename for resulting IDF-file
REM METADATA_DESCRIPTION: Metadata description of result/process
REM METADATA_SOURCE:      Location of source data
SET SOURCEPATH=postprocessing
SET SOURCEFILE=REF1_BAS_FW_L3-12_EPsel.IPF
SET IXCOL=
SET IYCOL=
SET IZCOL=13
SET WINDOW=
SET GRIDFUNC=MIN
SET CELLSIZE=25
SET IDFNODATA=-9999
SET RESULTPATH=result
SET RESULTFILE=%SOURCEFILE:.IPF=%_%GRIDFUNC%.IDF
SET METADATA_DESCRIPTION=Vergriddden van IPF-punten via iMOD-batchfunctie %GRIDFUNC%
SET METADATA_SOURCE=%SOURCEPATH%\%SOURCEFILE%;

REM For PERC (percentile) gridding: specify percentile between 0.0 and 100.0
SET PERCENTILE=50.0

REM For PCG gridfunction, specify HCLOSE, RCLOSE and NINNER (see iMOD-manual)
REM HCLOSE: Value (head) closure criterion for PCG solver to terminate interpolation (default is 0.001)
REM RCLOSE: Residual closure criterion for PCG solver to terminate the interpolation (default is 1000.0)
REM         When the maximum absolute value of value change from all nodes during an iteration is less than or equal to HCLOSE, and the criterion for RCLOSE is also satisfied, iteration stops.
REM NINNER: Number of inner iterations. Use large values for NINNER to speed up the interpolation since the problem to be solved is linear (default is 50)
SET HCLOSE=0.001
SET RCLOSE=1000.0
SET NINNER=100

REM For SKRIGING gridfunction, specify RANGE, SILL, NUGGET, KTYPE and STDEVIDF (see iMOD-manual)
REM KTYPE:    Kriging type: 1 is lineair model; 2 is spherical model; 3 is exponential model
REM RANGE:    Range (m) that defines a neighbourhood within which all data points are related to one another
REM SILL:     Distance (m) at which the semivariance approaches a region
REM NUGGET:   Offset of the semivariogram
REM STDEVIDF: Name for the standard deviation computed
SET KTYPE=1
SET RANGE=10000
SET SILL=10000
SET NUGGET=0.0
SET STDEVIDF=tmp\SKRIGING_VAR.IDF

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Start writing batchfunction INI-file parameters and values
SET MSG=Creating INI-file ...
ECHO   !MSG!
ECHO !MSG! >> %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

ECHO FUNCTION=XYZTOIDF > %INIFILE%
ECHO IPFFILE="%SOURCEPATH%\%SOURCEFILE%" >> %INIFILE%
IF NOT "%IXCOL%"=="" (
  ECHO IXCOL=%IXCOL% >> %INIFILE%
)
IF NOT "%IYCOL%"=="" (
  ECHO IYCOL=%IYCOL% >> %INIFILE%
)
IF NOT "%IZCOL%"=="" (
  ECHO IZCOL=%IZCOL% >> %INIFILE%
)
IF NOT "%CELLSIZE%"=="" (
  ECHO CS=%CELLSIZE% >> %INIFILE%
)
IF NOT "%WINDOW%"=="" (
  ECHO WINDOW=%WINDOW% >> %INIFILE%   
)
IF NOT "%IDFNODATA%"=="" (
  ECHO NODATA=%IDFNODATA% >> %INIFILE%
)
ECHO IDFFILE=%RESULTPATH%\%RESULTFILE% >> %INIFILE%
ECHO GRIDFUNC=%GRIDFUNC% >> %INIFILE%
IF "%GRIDFUNC%"=="PERC" (
  ECHO PERCENTILE=%PERCENTILE% >> %INIFILE%
)
IF "%GRIDFUNC%"=="PCG" (
  ECHO HCLOSE=%HCLOSE% >> %INIFILE%
  ECHO RCLOSE=%RCLOSE% >> %INIFILE%
  ECHO NINNER=%NINNER% >> %INIFILE%
)
IF "%GRIDFUNC%"=="SKRIGING" (
  ECHO RANGE=%RANGE% >> %INIFILE%
  ECHO SILL=%SILL% >> %INIFILE%
  ECHO NUGGET=%NUGGET% >> %INIFILE%
  ECHO KTYPE=%KTYPE% >> %INIFILE%
  ECHO STDEVIDF=%STDEVIDF% >> %INIFILE% 
)
IF "%GRIDFUNC%"=="OKRIGING" (
  ECHO RANGE=%RANGE% >> %INIFILE%
  ECHO SILL=%SILL% >> %INIFILE%
  ECHO NUGGET=%NUGGET% >> %INIFILE%
  ECHO KTYPE=%KTYPE% >> %INIFILE%
  ECHO STDEVIDF="%STDEVIDF%" >> %INIFILE% 
)

REM Remove old output file
IF EXIST "%RESULTPATH%\%RESULTFILE%" (
  ECHO "%TOOLSPATH%\Del2Bin.exe" /F /E "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
  "%TOOLSPATH%\Del2Bin.exe" /F /E "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
)

SET MSG=Running XYZTOIDF ...
ECHO   !MSG!
ECHO !MSG! >> %LOGFILE%

ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error
IF NOT EXIST "%RESULTPATH%\%RESULTFILE%" GOTO error
IF EXIST TMP RMDIR TMP >NUL 2>&1

IF EXIST "%INIFILE%" DEL "%INIFILE%"

IF EXIST "%SOURCEPATH%\%SOURCEFILE:.IPF=.MET%" (
  IF NOT "%SOURCEPATH%\%SOURCEFILE:.IPF=.MET%"=="%RESULTPATH%\%RESULTFILE:.IDF=.MET%" (
    COPY "%SOURCEPATH%\%SOURCEFILE:.IPF=.MET%" "%RESULTPATH%\%RESULTFILE:.IDF=.MET%" >> %LOGFILE%
  )
)

REM Create metadata
FOR %%G IN (%RESULTPATH%\%RESULTFILE%) DO (
  ECHO   Creating metadata for %%~nG ...
  ECHO Creating metadata for %%~nG ... >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata" "%%~dpnG.MET" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" Sweco IDF "" "" "%METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "Sweco" www.sweco.nl "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)
ECHO:

:success
SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel 0 for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:error
ECHO:
SET MSG=AN ERROR HAS OCCURRED^^! Check logfile "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel for higher level scripts
CMD /C "EXIT /B 1"
GOTO exit

REM FUNCTION: Intialize script and search/call SETTINGS\SIF.Settings.Project.bat and "00 settings.bat'. To use: "CALL :Initialization", without arguments
:Initialization
  COLOR 70
  IF EXIST "%~dp0..\SETTINGS\SIF.Settings.Project.bat" (
    CALL "%~dp0..\SETTINGS\SIF.Settings.Project.bat"
  ) ELSE (
    IF EXIST "%~dp0..\..\SETTINGS\SIF.Settings.Project.bat" (
      CALL "%~dp0..\..\SETTINGS\SIF.Settings.Project.bat"
    ) ELSE (
      IF EXIST "%~dp0..\..\..\SETTINGS\SIF.Settings.Project.bat" (
        CALL "%~dp0..\..\..\SETTINGS\SIF.Settings.Project.bat"
      ) ELSE (
        IF EXIST "%~dp0..\..\..\..\SETTINGS\SIF.Settings.Project.bat" (
          CALL "%~dp0..\..\..\..\SETTINGS\SIF.Settings.Project.bat"
        ) ELSE (
          IF EXIST "%~dp0..\..\..\..\..\SETTINGS\SIF.Settings.Project.bat" (
            CALL "%~dp0..\..\..\..\..\SETTINGS\SIF.Settings.Project.bat"
          ) ELSE (
            IF EXIST "%~dp0..\..\..\..\..\..\SETTINGS\SIF.Settings.Project.bat" (
              CALL "%~dp0..\..\..\..\..\..\SETTINGS\SIF.Settings.Project.bat"
            ) ELSE (
              ECHO SETTINGS\SIF.Settings.Project.bat could not be found in the six parent directories!
              REM Set errorlevel for higher level scripts
              CMD /C "EXIT /B 1"
            )
          )
        )
      )
    )
  )
  IF EXIST "%~dp000 Settings.bat" (
    CALL "%~dp000 Settings.bat"
  ) ELSE (
    IF EXIST "%~dp0..\00 Settings.bat" (
      CALL "%~dp0..\00 Settings.bat"
    ) ELSE (
      IF EXIST "%~dp0..\..\00 Settings.bat" (
        CALL "%~dp0..\..\00 Settings.bat"
      ) ELSE (
        IF EXIST "%~dp0..\..\..\00 Settings.bat" (
          CALL "%~dp0..\..\..\00 Settings.bat"
        ) ELSE (
          IF EXIST "%~dp0..\..\..\..\00 Settings.bat" (
            CALL "%~dp0..\..\..\..\00 Settings.bat"
          ) ELSE (
            IF EXIST "%~dp0..\..\..\..\..\00 Settings.bat" (
              CALL "%~dp0..\..\..\..\..\00 Settings.bat"
            ) ELSE (
              IF EXIST "%~dp0..\..\..\..\..\..\00 Settings.bat" (
                CALL "%~dp0..\..\..\..\..\..\00 Settings.bat"
              ) ELSE (
                REM Higher level settings file not found, ignore
              )
            )
          )
        )
      )
    )
  )
  GOTO:EOF

:exit
ECHO:
IF NOT DEFINED NOPAUSE PAUSE
