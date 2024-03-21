@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IPPjoin.bat                            *
REM * DESCRIPTION                            * 
REM *   Joining IPF-file data to other file  *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.1.0                         *
REM * MODIFICATIONS                          *
REM *   2022-08-25 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM INPUTPATH:     Path to input IPF-file(s)
REM INPUTFILE:     Filename or filter for input IPF-file(s)
REM ISRECURSIVE:   Specify (with value 1) that input path should be processed recursively
REM JOINFILE:      Path and filename of secondary IPF-file, that is joined to all source IPF-files
REM JOINTYPE:      Join type: 0: Natural (default), 1: Inner 2: Full Outer, 3: Left Outer, 4: Right Outer
REM KEY1:          Key(s) for source IPF-file as (comma-seperated) list of columns (name or number)
REM KEY2:          Key(s) for joined IPF-file as (comma-seperated) list of columns (name or number)
REM                Note: When k1 and k2 are not defined, all columns with equal names are used and a Natural join is forced. 
REM                      When k1 or k2 is not defined, the other key is used if specified columns exist.
REM TSJOINTYPE:    Join type for timeseries: 1: Inner 2: Full Outer (default), 3: Left Outer, 4: Right Outer
REM TSPERIOD:      Period for resulting timeseries defined by start and enddate: ddmmyyyy,ddmmyyyy or leave empty for complete period 
REM TSDECIMALS:    Number of decimals to round values in timeseries, or leave empty to skip rounding
REM TSINTERPOLATE: Specify (with value 1) to interpolate missing dates in timeseries of JOINFILE, or leave empty to use NoData-values
REM TSMAXINTDIST:  If TSINTERPOLATE=1: Maximum distance (days) between interpolated missing date and available date, or leave empty for no maximum constraint
REM TSSKIP:        Specify (with value 1) to skip joining timeseries from JOINFILE
REM TSERRIGNORE:   Specify (with value 1) to ignore date errors when reading timeseries
REM RESULTPATH:    Path to write results. A result filename can be specified for a single source IPF-file.
SET INPUTPATH=input
SET INPUTFILE=*.IPF
SET ISRECURSIVE=0
SET JOINFILE=tmp\IPFFile2.IPF
SET JOINTYPE=0
SET KEY1=15
SET KEY2=1
SET TSJOINTYPE=
SET TSPERIOD=
SET TSDECIMALS=
SET TSINTERPOLATE=
SET TSMAXINTDIST=
SET TSSKIP=
SET TSERRIGNORE=
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SETLOCAL ENABLEDELAYEDEXPANSION
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET SCRIPTNAME=%~n0
SET TEMPPATH=tmp
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-plus: %SCRIPTNAME%

SET MSG=Starting script '%~n0' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET ROPTION=
SET TOPTION=
SET K1OPTION=
SET K2OPTION=
SET TSTOPTION=
SET TSPOPTION=
SET TSDOPTION=
SET TSIOPTION=
SET TSSOPTION=
SET TSERROPTION=
IF "%ISRECURSIVE%"=="1" SET ROPTION=/r
IF DEFINED JOINTYPE SET TOPTION=/t:%JOINTYPE%
IF DEFINED KEY1 SET K1OPTION=/k1:%KEY1%
IF DEFINED KEY2 SET K2OPTION=/k2:%KEY2%
IF DEFINED TSJOINTYPE SET TSTOPTION=/tst:%TSJOINTYPE%
IF DEFINED TSPERIOD SET TSPOPTION=/tsp:%TSPERIOD%
IF DEFINED TSDECIMALS SET TSDOPTION=/tsd:%TSDECIMALS%
IF "%TSINTERPOLATE%"=="1" (
  IF DEFINED TSMAXINTDIST (
    SET TSIOPTION=/tsi:%TSJOINTYPE%
  ) ELSE (
    SET TSIOPTION=/tsi
  )
)
IF "%TSSKIP%"=="1" SET TSSOPTION=/tss
IF "%TSERRIGNORE%"=="1" SET TSERROPTION=/tserr

REM Start join
ECHO   joining '%JOINFILE%' to '%INPUTPATH%\%INPUTFILE%' ...
ECHO   joining '%JOINFILE%' to '%INPUTPATH%\%INPUTFILE%' ... >> %LOGFILE%
ECHO %TOOLSPATH%\IPFjoin.exe %ROPTION% %TOPTION% %K1OPTION% %K2OPTION% %TSTOPTION% %TSPOPTION% %TSDOPTION% %TSIOPTION% %TSSOPTION% %TSERROPTION% "%INPUTPATH%" "%INPUTFILE%" "%JOINFILE%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IPFjoin.exe" %ROPTION% %TOPTION% %K1OPTION% %K2OPTION% %TSTOPTION% %TSPOPTION% %TSDOPTION% %TSIOPTION% %TSSOPTION% %TSERROPTION% "%INPUTPATH%" "%INPUTFILE%" "%JOINFILE%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

ECHO:
ECHO: >> %LOGFILE%

:success
SET MSG=Script '%SCRIPTNAME%' is finished
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:error
ECHO:
SET MSG=AN ERROR HAS OCCURRED^^! Check logfile "%~n0.log"
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
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
