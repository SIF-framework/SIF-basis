@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * GENSnapToGrid.bat                       *
REM * DESCRIPTION                             *
REM *   Create 3D GEN-files from 2D GEN-files *
REM *   with iMOD-batchfunction GENSNAPTOGRID *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2019-08-26 Initial version            *
REM *******************************************
CALL :Initialization
CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM GENPATH:       Path to source GEN-files
REM GENFILTER:     Filename filter to select GEN-files to snap
REM IDFFILE:       Path and filename of IDF-file to snap to, or leave empty and use WINDOW and CELLSIZE to define grid
REM WINDOW:        Extent coordinates (xll,yll,xur,yur) of snap grid, when IDFFILE is empty
REM BASECELLSIZE:  Cellsize of underlying TOP/BOT-files that gridded HFB-lines should correspond with.
REM CELLSIZE:      Minimum cell size of snap grid, when IDFFILE is empty. This is increased to BASECELLSZIE when smaller. 
REM SOURCEPREFIX:  Prefix in source filename to replace with TARGETPREFIX
REM SOURCEPOSTFIX: Postfix in source filename to replace with TARGETPOSTFIX
REM TARGETPREFIX:  Prefix in target filename 
REM TARGETPOSTFIX: Postfix in target filename
REM RESULTPATH:    Path to write results
REM METADATADESCRIPTION: Short desciption to write to metadata file
SET GENPATH=tmp4\single
SET GENFILTER=%HFB_PREFIX%.GEN
SET IDFFILE=%SNAPIDFFILE%
SET WINDOW=%SNAPWINDOW%
SET BASECELLSIZE=%REGISCELLSIZE%
SET CELLSIZE=%MINHFBCELLSIZE%
SET SOURCEPREFIX=
SET SOURCEPOSTFIX=
SET TARGETPREFIX=
SET TARGETPOSTFIX=
SET I3D=1
SET TOPLAYER=%REGISFILL_PATH%\MV_eenheid-T-CK.IDF
SET BOTLAYER=%REGISFILL_PATH%\BASELAYER.IDF
SET RESULTPATH=result\single
SET METADATADESCRIPTION=2D GEN-file snapped to layermodel-grid

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"
SET INIFILE="%THISPATH%%SCRIPTNAME%.INI"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
IF ERRORLEVEL 1 GOTO error

REM Create empty result directories
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%" >> %LOGFILE%

IF NOT EXIST "%GENPATH%\%GENFILTER%" (
  SET MSG=  No GEN-files found to process ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO: 
  GOTO success
)

IF %CELLSIZE% LSS %BASECELLSIZE% (
  ECHO   increased cellsize %CELLSIZE% from to %BASECELLSIZE%
  ECHO   increased cellsize %CELLSIZE% from to %BASECELLSIZE% >> %LOGFILE%
  SET CELLSIZE=%BASECELLSIZE%
)

FOR /R "%GENPATH%" %%G IN (%GENFILTER%) DO (
  SET SOURCEGENFILENAME=%%~nxG
  SET RESULTGENFILENAME=%%~nG
  SET SOURCEGENFILENAME=!SOURCEGENFILENAME:"=!
  IF DEFINED SOURCEPREFIX (
    SET RESULTGENFILENAME=!RESULTGENFILENAME:%SOURCEPREFIX%=%TARGETPREFIX%!
  ) ELSE (
    SET RESULTGENFILENAME=%TARGETPREFIX%!RESULTGENFILENAME!
  )
  IF DEFINED SOURCEPOSTFIX (
    SET RESULTGENFILENAME=!RESULTGENFILENAME:%SOURCEPOSTFIX%=%TARGETPOSTFIX%!
  ) ELSE (
    SET RESULTGENFILENAME=!RESULTGENFILENAME!%TARGETPOSTFIX%
  )
  SET RESULTGENFILENAME=!RESULTGENFILENAME!.GEN
  
  SET MSG=  snapping '%%~nxG' to grid ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  
  ECHO FUNCTION=GENSNAPTOGRID > %INIFILE%
  ECHO GENFILE_IN="%GENPATH%\!SOURCEGENFILENAME!" >> %INIFILE%
  ECHO GENFILE_OUT="%RESULTPATH%\!RESULTGENFILENAME!" >> %INIFILE%
  IF DEFINED IDFFILE (
    ECHO IDFFILE="%IDFFILE%" >> %INIFILE%
  ) ELSE (
    ECHO WINDOW=%WINDOW% >> %INIFILE%
    ECHO CELL_SIZE=%CELLSIZE% >> %INIFILE%
  )
  IF DEFINED I3D ECHO I3D=%I3D% >> %INIFILE%
  IF DEFINED TOPLAYER ECHO IDF_TOP="%TOPLAYER%" >> %INIFILE%
  IF DEFINED BOTLAYER ECHO IDF_BOT="%BOTLAYER%" >> %INIFILE%

  ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
  "%IMODEXE%" %INIFILE% >> %LOGFILE%

  SET MSG=  creating metadata for '!RESULTGENFILENAME!' ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%TOOLSPATH%\iMODmetadata.exe" "%RESULTPATH%\!RESULTGENFILENAME!" "%%~dpG " "" "" ="%MODELREF0% %MODELNAME%" "%METADATADESCRIPTION%" ="%CONTACTORG%" "GEN" "m" "" "Script: %THISPATH%%SCRIPTNAME%.bat; 2D GEN-file: %GENPATH%\%%G; grid: !IDFFILE!;;" "See iMOD-batchfunction GENSNAPTOGRID" ="%MODELREF0%" ="%CONTACTORG%" ="%CONTACTSITE%" ="%CONTACTPERSON%" ="%CONTACTEMAIL%" >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata.exe" "%RESULTPATH%\!RESULTGENFILENAME!" "%%~dpG " "" "" ="%MODELREF0% %MODELNAME%" "%METADATADESCRIPTION%" ="%CONTACTORG%" "GEN" "m" "" "Script: %THISPATH%%SCRIPTNAME%.bat; 2D GEN-file: %GENPATH%\%%G; grid: !IDFFILE!;;" "See iMOD-batchfunction GENSNAPTOGRID" ="%MODELREF0%" ="%CONTACTORG%" ="%CONTACTSITE%" ="%CONTACTPERSON%" ="%CONTACTEMAIL%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error

  ECHO: 
  ECHO: >> %LOGFILE%
)
IF EXIST "%INIFILE%"DEL "%INIFILE%"

:success
SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel for higher level scripts
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
