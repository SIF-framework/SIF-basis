@ECHO OFF
REM *********************************************
REM * SIF-basis (Sweco)                         *
REM * Version 1.1.0 December 2020               *
REM *                                           *
REM * XCopyToDBASE.bat                          *
REM * DESCRIPTION                               *
REM *   Copies complete structures of files and *
REM *   subdirs to specified DBASE modelpath    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)      *
REM * MODIFICATIONS                             *
REM *   2018-09-12 Initial version              *
REM *********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:      Name of subdirectory where (script)results were stored that should be copied to DBASE-subdirectory
REM TARGETPATH:      Targetpath excluding "MODELREF1[\MODELREF2[\MODELSUBDIR]]", or leave empty to use %DBASEPATH% as target
REM MODELNAME:       Full model version string as MODELREF1[_MODELREF2[_MODELREF3]]), which is added to TARGETPATH, or leave empty place SOURCEPATH directly under TARGETPATH
REM MODELSUBDIR:     Specify subdirectory name where files should be copied to (may be left empty). This could be the package directory name if PACKAGEDIRS is used to specify one or more other sublevels.
REM ISTARGETCLEANED: Use 1 if complete targetpath DBASE\MODELREF1[\MODELREF2[\MODELSUBDIR]] should be deleted before copy (1=delete contents including subdirectories, 0=do not delete contents)
REM ISMOVED:         Use 1 if files should be moved instead of copied (1=move, empty/non-1=copy). When moving ensure contents to do not exist in targetpath
SET SOURCEPATH=result\BASIS1
SET TARGETPATH=
SET MODELNAME=ORG-test
SET MODELSUBDIR=
SET ISMOVED=1
SET ISTARGETCLEANED=1

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Check DBASEPATH is defined, before continuing with copying data to some unexpected place
IF NOT DEFINED DBASEPATH (
  SET MSG=variable DBASEPATH not defined, ensure path to set_project.bat is correctly defined ...
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF NOT EXIST "%SOURCEPATH%" (
  SET MSG=SOURCEPATH not found: %SOURCEPATH%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

REM Retrieve full targetpath
IF DEFINED MODELNAME (
  SET FULLMODELNAME=%MODELNAME:_=\%
  IF DEFINED MODELSUBDIR SET FULLMODELNAME=%FULLMODELNAME%\%MODELSUBDIR%
)
IF NOT DEFINED TARGETPATH SET TARGETPATH=%DBASEPATH%
IF DEFINED FULLMODELNAME SET TARGETPATH=%TARGETPATH%\%FULLMODELNAME%

IF NOT EXIST "%TARGETPATH%" MKDIR "%TARGETPATH%" >> %LOGFILE%

REM Retrieve absolute path for RESULTPATH
PUSHD %TARGETPATH%
SET TARGETPATH=%CD%
POPD

ECHO Script '%SCRIPTNAME%' started in:  %THISPATH% > %LOGFILE%
SET MSG=Copying data from '%SOURCEPATH%' to '!TARGETPATH:%ROOTPATH%\=!' ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Delete target subdirectory (under model DBASE-path) if specified and name was not empty 
IF "%ISTARGETCLEANED%"=="1" (
  IF EXIST "%TARGETPATH%" (
    IF NOT "%TARGETPATH%"=="" (
      IF EXIST "%TARGETPATH%" (
        ECHO   removing old files from %TARGETPATH% ... 
        ECHO   removing following files/subdirectories from %TARGETPATH% ... >> %LOGFILE%
        ECHO DIR /B "%TARGETPATH%" >> %LOGFILE%
        ECHO "%TOOLSPATH%\Del2Bin.exe" /E /S "%TARGETPATH%" >> %LOGFILE%
        "%TOOLSPATH%\Del2Bin.exe" /E /S "%TARGETPATH%" >> %LOGFILE% 2>&1
        IF ERRORLEVEL 1 GOTO error
      )
    )
  )
)
IF NOT "%ISMOVED%"=="1" (
  ECHO   copying files from %SOURCEPATH% ...
  ECHO XCOPY /S /Y "%SOURCEPATH%" "%TARGETPATH%"\ >> %LOGFILE%
  XCOPY /S /Y "%SOURCEPATH%" "%TARGETPATH%"\ >> %LOGFILE%
) ELSE (
  ECHO   moving files from %SOURCEPATH% ...
  ECHO ROBOCOPY /MOVE /E "%SOURCEPATH%" "%TARGETPATH%" >> %LOGFILE% 
  ROBOCOPY /MOVE /E "%SOURCEPATH%" "%TARGETPATH%" >> %LOGFILE% 
  IF ERRORLEVEL 8 GOTO error
)

ECHO   creating shortcut to DBASE directory ...
ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%SCRIPTNAME%.lnk.lnk" "%TARGETPATH%" >> %LOGFILE%
CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%SCRIPTNAME%.lnk.lnk" "%TARGETPATH%" >nul
IF "%ISMOVED%"=="1" (
  IF NOT EXIST "%SOURCEPATH%" MKDIR "%SOURCEPATH%"
  ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%MovedPath - snelkoppeling.lnk" "%TARGETPATH%" >> %LOGFILE%
  CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "MovedPath - snelkoppeling.lnk" "%TARGETPATH%" >nul
)

:success
ECHO:
ECHO: >> %LOGFILE%
SET MSG=Script finished, see '%~n0.log'
ECHO %MSG%
ECHO %MSG% >> !LOGFILE!
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
