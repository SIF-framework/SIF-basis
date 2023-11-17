@ECHO OFF
REM ******************************************************
REM * SIF-basis v2.1.0 (Sweco)                           *
REM *                                                    *
REM * XYZ2IDF - IDF                                      *
REM * DESCRIPTION                                        *
REM *   Interpolates NoData-cells in IDF-file(s) with    *
REM *   BIVAR/PCG method in iMOD XYZTOIDF batchfunction. *
REM * VERSION: 2.0.0                                     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)               *
REM *   2017-09-26 Initial version                       *
REM ******************************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM SOURCEIDFPATH:   Path to input IDF-files to interpolate
REM SOURCEIDFFILTER: Filter for source IDF file(s)
REM CELLSIZE:        Target IDF cellsize
REM WINDOW:          Extent (commaseperated xll, yll, xur, yur) or leave empty to use entire ISG.
REM GRIDFUNC:        Method for interpolation: PCG or BIVAR. For GRIDFUNC PCG, specify solver settings HLOSE, RCLOSE and NINNER
REM HCLOSE:          Value (head) closure criterion for PCG solver to terminate interpolation (default is 0.001)
REM RCLOSE:          Residual closure criterion for PCG solver to terminate the interpolation (default is 1000.0)
REM                  When the maximum absolute value of value change from all nodes during an iteration is less than or equal to HCLOSE, and the criterion for RCLOSE is also satisfied, iteration stops.
REM NINNER:          Number of inner iterations. Use large values for NINNER to speed up the interpolation since the problem to be solved is linear (default is 50)
REM POINTERIDFFILE:  Pointer file with non-NoData cells marking the area for which NoData-cells are interpolated
REM MAXPROCCOUNT:    Number of processors to use for parallel processing, use 1 to use a single processor
REM RESULTPATH:      Specify path to target IDF directory
REM TARGETIDFFILE:   If input was a single IDF-file, a filename can be specified here which will be used for input IDF-file(s), or leave empty otherwise
REM ISADDMETADATA:   Specify with value 1 to copy metadata from source and add to it, or leave empty to skip metadata files
SET SOURCEIDFPATH=tmp
SET SOURCEIDFFILTER=strekkingslijnen_angle.IDF
SET CELLSIZE=250
SET WINDOW=
SET GRIDFUNC=PCG
SET HCLOSE=0.01
SET RCLOSE=1000
SET NINNER=500
SET POINTERIDFFILE=tmp\strekkingslijn_zones.IDF
SET RESULTPATH=tmp
SET TARGETIDFFILE=strekkingslijnen_angle.IDF
SET ISADDMETADATA=1

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET LOGFILE="%SCRIPTNAME%.log"
SET TMPPATH=%RESULTPATH%\tmp
SET IMODEXE=%IMODEXE%

REM METADATA_DESCRIPTION: Metadata description
REM METADATA_SOURCE: Metadata source path(s) and/or file(s). The path to the source IDF-file and directory with this script will be added automatically
SET METADATA_DESCRIPTION=Interpolatie NoData-cellen met iMOD-batchfunctie %GRIDFUNC%
SET METADATA_SOURCE=

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF "%GRIDFUNC%"=="PCG" (
  SET METADATA_DESCRIPTION=%METADATA_DESCRIPTION%; HCLOSE=%HCLOSE%, RCLOSE=%RCLOSE%, NINNER=%NINNER%
)

IF NOT EXIST "%IMODEXE%" (
  SET MSG=iMOD-executable not found: %IMODEXE%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT EXIST "%SOURCEIDFPATH%" (
  SET MSG=SOURCEIDFPATH not found: %SOURCEIDFPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT "%POINTERIDFFILE%"=="" (
  IF NOT EXIST "%POINTERIDFFILE%" (
    SET MSG=POINTERIDFFILE not found: %POINTERIDFFILE%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)

IF "%MAXPROCCOUNT%"=="" SET MAXPROCCOUNT=1

SET MSG=Starting %SCRIPTNAME% ...
ECHO !MSG!
ECHO !MSG! > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%" >> %LOGFILE%
IF NOT EXIST "%TMPPATH%" MKDIR "%TMPPATH%" >> %LOGFILE%
SET PROCSUBIDX=0
SET PROCIDX=0
FOR %%D IN ("!SOURCEIDFPATH!\!SOURCEIDFFILTER!") DO (
  SET SOURCEIDFFILE=%%~nxD
  SET /A PROCIDX=PROCIDX + 1
  SET /A PROCSUBIDX=PROCSUBIDX+ 1
  IF NOT "!PROCSUBIDX!"=="!MAXPROCCOUNT!" (
    ECHO   processing !SOURCEIDFFILE! (parallel^) ...
    ECHO   processing !SOURCEIDFFILE! (!PROCIDX! parallel^) ... >> %LOGFILE%
  ) ELSE (
    ECHO   processing !SOURCEIDFFILE! ...
    ECHO   processing !SOURCEIDFFILE! (!PROCIDX!^) ... >> %LOGFILE%
  )

  REM Start writing batchfunction INI-file parameters and values
  SET INIFILENAME=%TMPPATH%\XYZTOIDF_%%~nD.INI
  ECHO FUNCTION=XYZTOIDF > !INIFILENAME!
  ECHO IDFFILE_IN="%SOURCEIDFPATH%\!SOURCEIDFFILE!" >> !INIFILENAME!
  IF NOT "%POINTERIDFFILE%"=="" (
    IF NOT "%IMODEXE:V5_=%"=="%IMODEXE%" (
      ECHO MASKIDF="%POINTERIDFFILE%" >> !INIFILENAME!
    ) ELSE (
      ECHO IDFFILE_POINTER="%POINTERIDFFILE%" >> !INIFILENAME!
    )
  )
  IF NOT "%CELLSIZE%"=="" (
    ECHO CS=%CELLSIZE% >> !INIFILENAME!
  )
  IF NOT "%WINDOW%"=="" (
    ECHO WINDOW=%WINDOW% >> !INIFILENAME!
  )
  IF "!TARGETIDFFILE!"=="" SET TARGETIDFFILE=!SOURCEIDFFILE!
  ECHO IDFFILE="%RESULTPATH%\!TARGETIDFFILE!" >> !INIFILENAME!
  ECHO GRIDFUNC=PCG >> !INIFILENAME!
  ECHO HCLOSE=%HCLOSE% >> !INIFILENAME!
  ECHO RCLOSE=%RCLOSE% >> !INIFILENAME!
  ECHO NINNER=%NINNER% >> !INIFILENAME!

  REM Remove old output file
  IF NOT "%RESULTPATH%\!TARGETIDFFILE!"=="!SOURCEIDFPATH!\!SOURCEIDFFILE!" (
    IF EXIST "%RESULTPATH%\!TARGETIDFFILE!" DEL /F /Q "%RESULTPATH%\!TARGETIDFFILE!" >> %LOGFILE%
  )

  ECHO Starting iMOD-batchfunction with INI-file: >> %LOGFILE%
  TYPE !INIFILENAME! >> %LOGFILE%

  IF NOT "!PROCSUBIDX!"=="!MAXPROCCOUNT!" (
    REM Start process asychronously
    ECHO START "Running XYZTOIDF" /B "%IMODEXE%" !INIFILENAME! >> %LOGFILE%
    START "Running XYZTOIDF" /B "%IMODEXE%" !INIFILENAME! >NUL
    IF ERRORLEVEL 1 GOTO error
  ) ELSE (
    REM Max processcount has been reached, wait for this process to finish
    ECHO "%IMODEXE%" !INIFILENAME! >> %LOGFILE%
    "%IMODEXE%" !INIFILENAME! >NUL
    IF ERRORLEVEL 1 GOTO error
    SET PROCSUBIDX=0
  )

  IF "%ISADDMETADATA%"=="1" (
    IF EXIST "!SOURCEIDFPATH!\!SOURCEIDFFILE:.IDF=.MET!" COPY "!SOURCEIDFPATH!\!SOURCEIDFFILE:.IDF=.MET!" "%RESULTPATH%\!TARGETIDFFILE:.IDF=.MET!" >> %LOGFILE%
    FOR %%G IN ("%RESULTPATH%\!TARGETIDFFILE!") DO (
      ECHO     adding metadata for !TARGETIDFFILE! ...
      ECHO "iMODmetadata" "%%~dpnG.MET" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" Sweco IDF "" "" "!SOURCEIDFPATH!\!SOURCEIDFFILE!; %METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!" ="%MODELREF0%" "Sweco" www.sweco.nl "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
      "%TOOLSPATH%\iMODmetadata" "%%~dpnG.MET" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" Sweco IDF "" "" "!SOURCEIDFPATH!\!SOURCEIDFFILE!; %METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!" ="%MODELREF0%" "Sweco" www.sweco.nl "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  )
  SET TARGETIDFFILE=
)
RMDIR %TMPPATH% >> %LOGFILE%

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
IF "%NOPAUSE%"=="" PAUSE
