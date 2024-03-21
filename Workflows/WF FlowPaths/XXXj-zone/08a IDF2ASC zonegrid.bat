@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDF2ASC.bat                            *
REM * DESCRIPTION                            *
REM *   converts IDF-files to ASC with       *
REM *   iMOD-batchfunction CREATEASC         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 1.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-10-31 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH: Path to IDF-files
REM IDFFILTER:  Filter for IDF-files
REM RESULTPATH: Path to subdirectory where scriptresults are stored
SET SOURCEPATH=%RESULTPATH_ZONE%
SET IDFFILTER=%TYPESTRING%_FW_%MODELREF%_%SOURCEABBR%.IDF
SET RESULTPATH=%RESULTPATH_GIS%

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% >> %LOGFILE%
   GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

REM Log settings
ECHO   SOURCEPATH=%SOURCEPATH%
ECHO   SOURCEPATH=%SOURCEPATH% >> %LOGFILE%
ECHO   IDFFILTER=%IDFFILTER%
ECHO   IDFFILTER=%IDFFILTER% >> %LOGFILE%

REM Converting IDF-files
SET MSG=Starting IDF-file conversion...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

ECHO FUNCTION=CREATEASC > %INIFILE%
ECHO SOURCEDIR="%SOURCEPATH%\%IDFFILTER%" >> %INIFILE%
ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error
IF EXIST %INIFILE% DEL %INIFILE%
IF EXIST "tmp\*_dir_imod.bat" DEL /F /Q "tmp\*_dir_imod.bat"
IF EXIST "tmp\*_dir_imod.txt" DEL /F /Q "tmp\*_dir_imod.txt"
IF EXIST TMP RMDIR TMP >NUL 2>&1

IF NOT "%RESULTPATH%" == "%SOURCEPATH%" (
  ECHO MOVE /Y "%SOURCEPATH%\%IDFFILTER:.IDF=.ASC%" "%RESULTPATH%" >> %LOGFILE%
  MOVE /Y "%SOURCEPATH%\%IDFFILTER:.IDF=.ASC%" "%RESULTPATH%" >> %LOGFILE% 2>&1
  IF ERRORLEVEL 1 GOTO error
)

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
  IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
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
