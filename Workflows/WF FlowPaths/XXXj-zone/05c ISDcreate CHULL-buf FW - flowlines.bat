@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * ISDcreate.bat                           *
REM * DESCRIPTION                             *
REM *   Creates ISD-file for IMODPATH         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2018-08-27 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SRCPATH:    Path to source IPF- or GEN-file(s) 
REM SRCFILTER:  Filter (or filename) to source IPF- or GEN-file(s) with points/features that define zone for startpoints
REM N1:         Shape number 1: an integer or float (english notation). For points: radius of circle around point, for polygons: distance X between points in the polygon, for lines: distance between points along the line
REM N2:         Shape number 2: an integer or float (english notation). For points: dinstance between points on the circle, for polygons: distance Y between points in the polygon, for lines: not used, use any number e.g. 0 
REM TOP:        TOP-level as an IDF-file, numeric value or columnname in IMODFILE for TOP-level
REM BOT:        BOT-level as an IDF-file, numeric value or columnname in IMODFILE for BOT-level
REM VIN:        Vertical interval number, number of points between top and bottom level
REM RESULTPATH: Path for output ISD-file
REM ISDFILE:    Filename for output ISD-file
SET SRCPATH=tmp
SET SRCFILTER=%MODELREF%_BW_%SOURCEABBR%_9c%FPBW_ISD_N1:.0=%m%FPBW_ISD_VIN%x_EP_CHULL_buffer2500.GEN
SET N1=%FPFW_ISDL_N1%
SET N2=%FPFW_ISDL_N2%
SET TOP=%FPFW_ISD_TOP%
SET BOT=%FPFW_ISD_BOT%
SET VIN=%FPFW_ISDL_VIN%
SET RESULTPATH=%RESULTPATH_SP%
SET ISDFILE=FW_CHULLBUFFER-L.ISD

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

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET MSG=Creating startpoints ISD-file %ISDFILE% ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%TOOLSPATH%\ISDcreate.exe" "%SRCPATH%" "%SRCFILTER%" %N1% %N2% "%TOP%" "%BOT%" %VIN% "%RESULTPATH%\%ISDFILE%" >> %LOGFILE%
"%TOOLSPATH%\ISDcreate.exe" "%SRCPATH%" "%SRCFILTER%" %N1% %N2% "%TOP%" "%BOT%" %VIN% "%RESULTPATH%\%ISDFILE%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

ECHO: 
ECHO: >> %LOGFILE%

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
