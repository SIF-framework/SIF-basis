@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDFresample.bat                        *
REM * DESCRIPTION                            * 
REM *   Resamples specified zone cells with  *
REM *   value from neighbor cells.           *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2021-05-10 Initial version           *
REM ******************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM Resamples values in IDF-files with nearest neighbor or inverse distance weighted (IDW) for NoData-values in a region.
REM or with a statistic (min/max/avg/percentile) over all Data-values, assigned to all cells in each zone.
REM A zone is group of one or more cells with the zame zone value. A region is a group of connected cells in a specific zone.
REM A zone IDF-file can be specified to define cells to be resampled per zone (cells with the same zone value).
REM Resulting IDF-file(s) will get the extent of the zone IDF-file and the cellsize and NoData-value of the value IDF-file.

REM ********************
REM * Script variables *
REM ********************
REM VALUEIDFPATH :  Path to diectory with IDF-file(s) with known values
REM VALUEIDFFILTER: Filter for IDF-file(s) in VALUEIDFPATH with known values to process
REM ZONEIDFFILE:    Zone IDF-file to define cells to be resampled as all data-cells (values different from NoData or zero). Each different zone value is resampled individually.
REM RESAMPLEMETHOD: Use one of the following values for a corresponding resample method:
REM                 1: nearest neighbor (default): resamples NoData-values per region with value from nearest neighbor
REM                    in input IDF-file; optionally define method (RESAMPLEPAR1) to handle multiple cells at same distance:
REM                    1: arithmetic average (default); 2: harmonic average; 3: minimum value; 4: maximum value
REM                 2: Inverse Distance Weighted (IDW) interpolation with power (RESAMPLEPAR1), smooting factor (RESAMPLEPAR2) and max.
REM                    distance (RESAMPLEPAR3) (m); without a max. distance all Data-points in/around region are used to interpolate.
REM                    IDW resamples NoData-values per region with IDW-interpolated value from non-NoData-cells in region.
REM                    If smoothing is 0 and power is high, interpolation changes a lot around points to give them their exact value.
REM                    If smoothing is high and power is 1, results are much smoother, but pointvalues are not maintained.
REM                 3: minimum zone value (RESAMPLEPARi is ignored);
REM                 4: maximum zone value (RESAMPLEPARi is ignored);
REM                 5: average zone value (RESAMPLEPARi is ignored);
REM                 6: percentile in zone values, with RESAMPLEPAR1 an integer (value 0-100) to define the percentile;
REM                    with methods 2-5 all cells in each zone are overwritten with the calculated statistic.
REM                 Note: it is advised to specify a zone IDF-file via option z to define resampled cells; when no zone is 
REM                       defined, a single zone is created with NoData-cells for method 1-2 and with Data-cells for methods 3-6
REM RESAMPLEPARi:   Parameters that define resampling, based on specifc method. RESAMPLEPAR1
REM SKIPDIAGONALS:  Specify (with value 1) if neighbors should not be searched diagonally (only horizontally and vertically)
REM RESULTPATH:     Path for resulting IDF-file(s) or filename of resulting IDF-file when a single value IDF-file was specified
SET VALUEIDFPATH=tmp
SET VALUEIDFFILTER=BGTWTR_LEVEL_plassen1.IDF
SET ZONEIDFFILE=tmp\BGTWTR_ZONE_plassen.IDF
SET RESAMPLEMETHOD=6
SET RESAMPLEPAR1=5
SET RESAMPLEPAR2=
SET RESAMPLEPAR3=
SET SKIPDIAGONALS=
SET RESULTPATH=tmp\BGTWTR_LEVEL_plassen1_resampled.IDF

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

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET MOPTION=
SET ZOPTION=
SET DOPTION=
IF DEFINED RESAMPLEMETHOD (
  SET MOPTION=/m:%RESAMPLEMETHOD%
  IF DEFINED RESAMPLEPAR1 SET MOPTION=!MOPTION!,%RESAMPLEPAR1%
  IF DEFINED RESAMPLEPAR2 SET MOPTION=!MOPTION!,%RESAMPLEPAR2%
  IF DEFINED RESAMPLEPAR3 SET MOPTION=!MOPTION!,%RESAMPLEPAR3%
)
IF DEFINED ZONEIDFFILE SET ZOPTION=/z:"%ZONEIDFFILE%"
IF DEFINED SKIPDIAGONALS SET DOPTION=/d

ECHO "%TOOLSPATH%\IDFresample.exe" %MOPTION% %ZOPTION% %DOPTION% "%VALUEIDFPATH%" "%VALUEIDFFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IDFresample.exe" %MOPTION% %ZOPTION% %DOPTION% "%VALUEIDFPATH%" "%VALUEIDFFILTER%" "%RESULTPATH%" >> %LOGFILE%
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
IF "%NOPAUSE%"=="" PAUSE
