@ECHO OFF
REM ************************************************
REM * SIF-basis v2.1.0 (Sweco)                     *
REM *                                              *
REM * GENcreate.bat                                *
REM * DESCRIPTION                                  *
REM *   Creates GEN-file(s) for extent coordinates *
REM * AUTHOR(S): Koen van der Hauw (Sweco)         *
REM * VERSION: 2.0.0                               *
REM * MODIFICATIONS                                *
REM *   2019-04-16 Initial version                 *
REM ************************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM EXTENT:        Comma seperated base extent: xll,yll,xur,yur (to use the defined bufferextent copy the following expression: %MODELEXTENT%
REM BUFFERDIST:    Bufferdistance outside base extent for a second GEN-file (an integer value), or leave empty to skip. Note: use negative value to create extent inside base extent
REM RESULTPATH:    Output path
REM GENFILE:       GEN-filename for base extent
REM BUFFERGENFILE: GEN-filename for buffer extent if BUFFERDIST is defined
SET EXTENT=%MODELEXTENT%
SET BUFFERDIST=
SET RESULTPATH=%SHAPESPATH%
SET GENFILE=MODELEXTENT.GEN
SET BUFFERGENFILE=

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

ECHO Started script '%SCRIPTNAME%'...
ECHO Started script '%SCRIPTNAME%'... > %LOGFILE%

ECHO Base extent: %EXTENT%
ECHO EXTENT=%EXTENT% >> %LOGFILE%
IF NOT "%BUFFERDIST%" == "" (
  ECHO Buffer distance: %BUFFERDIST% 
  ECHO BUFFERDIST=%BUFFERDIST% >> %LOGFILE%
)

IF "%RESULTPATH%" == "" SET RESULTPATH=.
REM Check that the RESULTPATH is not a rootfolder, to prevent accidental deletion of folders in the root
IF "%RESULTPATH%" == "%RESULTPATH:~0,1%:\" (
  SET MSG=Please specify a valid RESULTPATH, a root folder is not allowed: %RESULTPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

IF NOT "%GENFILE%"=="" (
  SET MSG=  creating GEN-file for extent ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%TOOLSPATH%\GENcreate.exe" /e:%EXTENT% "%RESULTPATH%\%GENFILE%" >> %LOGFILE%
  "%TOOLSPATH%\GENcreate.exe" /e:%EXTENT% "%RESULTPATH%\%GENFILE%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
) ELSE (
  SET MSG=  skipping GEN-file for extent ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
)

REM Calculate bufferextents
IF NOT "%BUFFERDIST%" == "" (
  IF "%BUFFERGENFILE%"=="" (
   SET MSG=BUFFERDIST has been defined, please specify a valid BUFFERGENFILE-name
   ECHO !MSG!
   ECHO !MSG! >> %LOGFILE%
   GOTO error
  )

  FOR /F "tokens=1,2,3* delims=," %%a IN ("%EXTENT%") DO (
    SET /A BUFFERXLL=%%a-%BUFFERDIST%
    SET /A BUFFERYLL=%%b-%BUFFERDIST%
    SET /A BUFFERXUR=%%c+%BUFFERDIST%
    SET /A BUFFERYUR=%%d+%BUFFERDIST%
  ) 
  SET MODELEXTENT=!BUFFERXLL!,!BUFFERYLL!,!BUFFERXUR!,!BUFFERYUR!

  SET MSG=  creating GEN-file for buffer extent: !MODELEXTENT! ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%TOOLSPATH%\GENcreate.exe" /e:!MODELEXTENT! "%RESULTPATH%\%BUFFERGENFILE%" >> %LOGFILE%
  "%TOOLSPATH%\GENcreate.exe" /e:!MODELEXTENT! "%RESULTPATH%\%BUFFERGENFILE%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

ECHO:
ECHO: >> %LOGFILE%

SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
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
