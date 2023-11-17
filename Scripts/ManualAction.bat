@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * ManualAction.bat                       *
REM * DESCRIPTION                            * 
REM *   Log manual action                    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2018-09-12 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM MSG: Describe manual action to be executed
SET MSG=Describe a manual action to be executed here

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET CURRENTDATE=%DATE:~-10,2%-%DATE:~-7,2%-%DATE:~-4,4%
SET THISPATH=%~dp0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

REM Note: messages are echoed to the console (via the standard error), to the logfile of this script and if this script is 
REM called from a Runscripts batchfile, also explicitly forced to the console to allow writing message both to a metalogfile and console

REM Write empty line
ECHO: >CON
ECHO: >> %LOGFILE%
IF "%HASTOPLEVELSCRIPT%"=="1" ECHO: 1>&2

REM Write user message 
ECHO %MSG% 1>&2
ECHO %MSG% > %LOGFILE%
IF "%HASTOPLEVELSCRIPT%"=="1" ECHO %MSG% >CON

REM Ask question
SET /P SUCCESS=Is manual step executed succesfully? (j/y;n) >CON
IF "%SUCCESS%"=="" SET SUCCESS=onbekend
ECHO: >CON

REM Write result to logfile
SET MSG=Result for question 'Is manual step executed successfully?' by %USERNAME%, at: %CURRENTDATE%: %SUCCESS%
ECHO %MSG% >> %LOGFILE%
IF "%HASTOPLEVELSCRIPT%"=="1" ECHO %MSG% 1>&2

REM Write empty line
ECHO: >> %LOGFILE%
IF "%HASTOPLEVELSCRIPT%"=="1" ECHO: 1>&2

IF /I "%SUCCESS:~0,1%"=="j" (
  CMD /C "EXIT /B 0"
  GOTO exit
) ELSE (
  IF /I "%SUCCESS:~0,1%"=="y" (
    CMD /C "EXIT /B 0"
    GOTO exit
  ) ELSE (
    GOTO error
  )
)

GOTO exit

:error
ECHO:
ECHO: >> %LOGFILE%

SET MSG=MANUAL ACTION WAS NOT EXECUTED SUCCESSFULLY^! Check logfile "%~n0.log"
ECHO %MSG% 1>&2
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
