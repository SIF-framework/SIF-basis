@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * GENsplit.bat                           *
REM * DESCRIPTION                            * 
REM *   Splits GEN-lines with IPF-points     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.2                         *
REM * MODIFICATIONS                          *
REM *   2017-08-26 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM GENPATH:      Input path to search for GEN-file(s)
REM GENFILTER:    Filter for filename of input GEN-file(s) that will be split
REM IPFFILE:      Input IPF-file that will be used to split GEN-lines
REM MAXSNAPDIST:  Maximum snap distance for IPF-points, points further from GEN-line are not snapped and not used for splitting GEN-lines
REM MINSPLITDIST: Minimum split distance; if snapped points are closer than this distance from an existing node on a line, no extra node is inserted, or leave empty to use default (1m)
REM IPFCOLNR:     Columnindex (one based) or column name in IPF-file for value to add to splitted GEN-line segments at location of IPF-point
REM RESULTPATH:   Output path or outputfilename
SET GENPATH=input
SET GENFILTER=IJssel_lijnen.GEN
SET IPFFILE=tmp\Meetdata_IJsselpeil_GEM2000-2010_sel.IPF
SET MAXSNAPDIST=150
SET MINSPLITDIST=
SET IPFCOLNR=6
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET MSG=  splitting GEN-file(s^) %GENFILTER% ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET IPFCOLOPTION=
IF DEFINED IPFFILE (
  SET IPFCOLOPTION=/i:"%IPFFILE%"
  IF DEFINED IPFCOLNR SET IPFCOLOPTION=!IPFCOLOPTION!,%IPFCOLNR%
)

SET SOPTION=/s:%MAXSNAPDIST%
IF DEFINED MINSPLITDIST SET SOPTION=%SOPTION%,%MINSPLITDIST%
ECHO "%TOOLSPATH%\GENsplit.exe" %IPFCOLOPTION% %SOPTION% "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\GENsplit.exe" %IPFCOLOPTION% %SOPTION% "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

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
