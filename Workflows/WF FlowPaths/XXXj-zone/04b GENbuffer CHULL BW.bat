@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * GENbuffer.bat                           *
REM * DESCRIPTION                             * 
REM *   Creates buffer around GEN-features    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2018-09-01 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM GENPATH:    Input path for GEN-file(s)
REM GENFILTER:  Filter (using wildcards) or single filename to input GEN-file(s) 
REM BUFFER:     Buffersize, or leave empty or 0 to just copy
REM JOINMETHOD: Specify method for joining edges at the points. Valid methods are: 1) round, 2) miter or 3) square; or leave empty for default (1)
REM RESULTPATH: Result path or GEN-filename. In case of a foldername, the output filename is equal to the input filename with postfix _bufferX%BUFFER%
SET GENPATH=tmp
SET GENFILTER=%MODELREF%_BW_%SOURCEABBR%_9c%FPBW_ISD_N1:.0=%m%FPBW_ISD_VIN%x_EP_CHULL.GEN
SET BUFFER=2500
SET JOINMETHOD=1
SET RESULTPATH=tmp

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT DEFINED BUFFER SET BUFFER=0

SET MSG=  buffering GEN-file with %BUFFER% ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

IF NOT "%BUFFER%"=="0" (
  IF DEFINED JOINMETHOD SET OPTIONE=/e:%JOINMETHOD%

  ECHO "%TOOLSPATH%\GENbuffer.exe" /b:%BUFFER% !OPTIONE! "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
  "%TOOLSPATH%\GENbuffer.exe" /b:%BUFFER% !OPTIONE! "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
) ELSE (
  IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%" >> %LOGFILE%
  ECHO COPY /Y "%GENPATH%\%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
  COPY /Y "%GENPATH%\%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

ECHO: 
ECHO: >> %LOGFILE%

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
IF NOT DEFINED NOPAUSE PAUSE
