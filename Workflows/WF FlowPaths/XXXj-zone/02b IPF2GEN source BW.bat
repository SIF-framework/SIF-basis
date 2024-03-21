@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * IPF2GEN.bat                            *
REM * DESCRIPTION                            *
REM *   Converts IPF-GEN or GEN-IPF          *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.1.0                         *
REM * MODIFICATIONS                          *
REM *   2017-05-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH:       Input path for IPF-files 
REM IPFFILTER:     Filter for IPF-files (use wildcards or a complete filename)
REM X/YCOLNR:      Specify X and Y-column numbers (one-based), or leave empty to use default of 1 and 2
REM CONVERTMETHOD: Method for conversion, 1: each point is converted to a rectangle; 2: all points are used to create a convex hull
REM RECTANGLESIZE:   For conversion method 1 define: size of rectangles around IPF-points; otherwise leave empty
REM SNAPMETHOD:    Optional method for snapping input XY-coordinates to cells; 1: snaps to edge of cells, 2: snaps to center of cells, or leave empty to skip snapping
REM SNAPSIZE:        Size of cells that is snapped to (if SNAPMETHOD is defined, otherwise leave empty)
REM EXTENT:        Extent (xll,yll,xur,yur) to clip input/ouput IPF-files, or leave empty
REM RESULTPATH:    Path for resulting GEN-files
REM POSTFIX:       Postfix for converted GEN-files (or leave empty)
SET IPFPATH=tmp
SET IPFFILTER=%SOURCE_IPFFILE%
SET XCOLNR=
SET YCOLNR=
SET CONVERTMETHOD=1
SET RECTANGLESIZE=%FPBW_ISD_RECTSIZE%
SET SNAPMETHOD=2
SET SNAPSIZE=%FPFW_ISDP_N1%
SET EXTENT=
SET RESULTPATH=tmp
SET POSTFIX=_RECT%RECTANGLESIZE%

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

SET OPTIONM=
SET OPTIONS=
SET OPTIONY=
SET OPTIONE=
SET OPTIONP=
IF "%CONVERTMETHOD%"=="1" (
  SET OPTIONM=/m:1,%RECTANGLESIZE%
) ELSE (
  IF "%CONVERTMETHOD%"=="2" (
    SET OPTIONM=/m:2
  ) ELSE (
    ECHO Invalid method value for conversion, use 1, 2 or 3: %CONVERTMETHOD%
    GOTO error
  )
)
IF DEFINED XCOLNR (
  IF DEFINED YCOLNR (
    SET OPTIONY=/y:%XCOLNR%,%YCOLNR%
  ) ELSE (
    ECHO YCOLNR should also be defined if XCOLNR is defined
    GOTO error
  )
)
IF DEFINED SNAPMETHOD SET OPTIONS=/s:%SNAPMETHOD%,%SNAPSIZE%
IF DEFINED EXTENT SET OPTIONE=/e:%EXTENT%
IF DEFINED POSTFIX SET OPTIONP=/p:%POSTFIX%

SET MSG=Converting IPF-file(s^) to GEN-file(s^) ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%TOOLSPATH%\IPFGENconvert.exe" %OPTIONM% %OPTIONS% %OPTIONY% %OPTIONE% %OPTIONP% "%IPFPATH%" "%IPFFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IPFGENconvert.exe" %OPTIONM% %OPTIONS% %OPTIONY% %OPTIONE% %OPTIONP% "%IPFPATH%" "%IPFFILTER%" "%RESULTPATH%" >> %LOGFILE%
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
