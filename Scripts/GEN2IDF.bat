@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * GEN2IDF.bat                            *
REM * DESCRIPTION                            * 
REM *   Convert GEN-file(s) to IDF-file(s)   *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-09-12 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM GENPATH:        Path to GEN-file(s)
REM GENFILTER:      Filename filter for GEN-file(s), including extension (? and *-characters can be used as wildcards) (use * to avoid using a filter)
REM METHODPARi:      Parameters for conversion method. 
REM                  - for GEN-IDF-conversion of lines:
REM                    METHODPAR1/2: columnnumbers (one-based) in DAT-file, for start- and endpoints (for lines) of each linesegment, or leave empty to use id or feature index
REM                  - METHODPAR3: maximum interpolated distance along line when only start-or endpoint has a valid (non-skipped) value. Or leave empty to skip.
REM                  - for GEN-IDF-conversion of polygons:
REM                    METHODPAR1: columnnumber (one-based) in DAT-file, with value to assign to cell, or leave empty to use id or feature index
REM                    METHODPAR2: defines method for checking overlap with cells: 1) cell center inside polygon; 2) calculate overlap of polygon in cell (slower)
REM                  - METHODPAR3: method for cellvalue/area when multiple polygons intersect cell: 
REM                                1) first (default); 2) min; 3) max; 4) sum; 5) largest cellarea (value/area of polygon with largest area in cell (or first value for equal areas)
REM                                6) weighted average (with weight defined by polygon area in cell); 7: smallest cellarea; 8: largest (polygon)area; 9: smalles (polygon)area; 10: last
REM CELLSIZE:       Cellsize for resulting IDF-grid
REM SKIPPEDVALUES:  Specify commaseperated list of values si, or ranges (s1-s2) to skip in input files
REM ISANGLEADDED:   Specify (with value 1) if a seperate IDF-file with angles for each cel with a GEN-line part should be added
REM ISSIZEADDED:  Specify (with value 1) if an IDF-file with length or area of GEN-feature in cells should be added, or leave empty to skip
REM PROCESSISLANDS: Specify (with value 1) if island polygons (or donut holes) should be processed as an island and removed from outer polygpon; otherwise only polygons with points in clockwise order are converted
REM IGNOREPTORDER:  Specify (with value 1) if point order should be ignored and process polygons with anti-clockwise point order as clock-wise
REM SORTFEATURES:   Specify (with value 1) if features should be ordered on area/length (largest first) before gridding, which may influence the result for overlapping features
REM RESULTPATH:     Result path or filename if GENFILTER is a single filename
SET GENPATH=result
SET GENFILTER=*.GEN
SET METHODPAR1=1
SET METHODPAR2=2
SET METHODPAR3=9
SET CELLSIZE=100
SET SKIPPEDVALUES=-9999
SET ISANGLEADDED=0
SET ISSIZEADDED=1
SET PROCESSISLANDS=
SET IGNOREPTORDER=1
SET SORTFEATURES=1
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF "%CELLSIZE%"=="" (
  ECHO Please specify CELLSIZE-value
  ECHO Please specify CELLSIZE-value > %LOGFILE%
  GOTO error
)

ECHO Converting GEN-file(s^) to IDF ...
ECHO Converting GEN-file(s^) to IDF ... > %LOGFILE%
SETLOCAL EnableDelayedExpansion

SET GRIDOPTION=/g:%CELLSIZE%
IF DEFINED METHODPAR1 (
  SET GRIDOPTION=%GRIDOPTION%,%METHODPAR1%
  IF DEFINED METHODPAR2 (
    SET GRIDOPTION=!GRIDOPTION!,%METHODPAR2%
    IF DEFINED METHODPAR3 (
      SET GRIDOPTION=!GRIDOPTION!,%METHODPAR3%
    )
  )
)
SET SIZEOPTION=
SET ANGLEOPTION=
SET ISLANDOPTION=
SET IGNOREOPTION=
SET SKIPOPTION=
SET SORTOPTION=
IF "%ISSIZEADDED%"=="1" SET SIZEOPTION=/l
IF "%ISANGLEADDED%"=="1" SET ANGLEOPTION=/a
IF "%PROCESSISLANDS%"=="1" SET ISLANDOPTION=/i
IF "%IGNOREPTORDER%"=="1" SET IGNOREOPTION=/n
IF NOT "%SKIPPEDVALUES%"=="" SET SKIPOPTION=/s:%SKIPPEDVALUES%
IF "%SORTFEATURES%"=="1" SET SORTOPTION=/o
SET FILECOUNT=0
FOR %%G IN ("%GENPATH%\%GENFILTER%") DO (
  IF EXIST "%%G" (
    ECHO   processing %%~nxG ...
    ECHO processing %%~nxG ... >> %LOGFILE%
    ECHO "%TOOLSPATH%\IDFGENconvert.exe" %SORTOPTION% %SKIPOPTION% %SIZEOPTION% %ISLANDOPTION% %IGNOREOPTION% %GRIDOPTION% %ANGLEOPTION% "%GENPATH%" "%%~nxG" "%RESULTPATH%" >> %LOGFILE%
    "%TOOLSPATH%\IDFGENconvert.exe" %SORTOPTION% %SKIPOPTION% %SIZEOPTION% %ISLANDOPTION% %IGNOREOPTION% %GRIDOPTION% %ANGLEOPTION% "%GENPATH%" "%%~nxG" "%RESULTPATH%" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
    SET /A FILECOUNT=FILECOUNT+1
  )
)
ECHO:
ECHO: >> %LOGFILE%

:success
SET MSG=Script finished, converted %FILECOUNT% GEN-files. See "%~n0.log"
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
IF NOT DEFINED NOPAUSE PAUSE
