@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * iMOD-batchfunction.bat                  *
REM * DESCRIPTION                             *
REM *   Runs iMOD with specified INI-file     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.1                          *
REM * MODIFICATIONS                           *
REM *   2019-02-08 Initial version            *
REM *******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM INIFILE: INI-file for iMOD batchfunction, see iMOD-manual for available batchfunctions and description of INI-file
REM IMODEXE: Path to iMOD executable that should be used with this INI-file, use %iMODEXE% for default or for example %EXEPATH%\iMOD\iMOD_V4_4_X64R.EXE
SET INIFILE=%~n0.INI
SET IMODEXE=%IMODEXE%

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Processing INI-file %INIFILE% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%INIFILE%" (
  ECHO INI-file not found: %INIFILE%
  ECHO INI-file not found: %INIFILE% >> %LOGFILE%
  GOTO error
)

IF NOT EXIST "%IMODEXE%" (
   ECHO IMODEXE could not be found: %IMODEXE%
   ECHO IMODEXE could not be found: %IMODEXE% > %LOGFILE%
   GOTO error
)

REM Start iMOD with specified INI-file
ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

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
