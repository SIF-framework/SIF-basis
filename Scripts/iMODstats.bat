@ECHO OFF
REM ***********************************************
REM * SIF-basis v2.1.0 (Sweco)                    *
REM *                                             *
REM * iMODstats.bat                               *
REM * DESCRIPTION                                 * 
REM *   Calculates statistics for IDF/IPF-file(s) *
REM *   and specified values                      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)        *
REM * VERSION: 2.2.0                              *
REM * MODIFICATIONS                               *
REM *   2017-08-20 Initial version                *
REM ***********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:     Path with input iMOD-files (IDF, ASC or IPF) to calculate statistics for
REM SOURCEFILTER:   Filter for input iMOD-file(s) (IDF, ASC or IPF), wildcards are allowed
REM EXTENT:         Extent (xll,yll,urx,ury), or leave empty to use file extent
REM PCTCLASSCOUNT:  Number of percentile classen, i.e. 4 will give 25th, 50th, 75th and 100th percentiles; 100% is skipped since it is reported as max; leave empty for default (10 classes)
REM ISRECURSIVE:    Specify (with value 1) if subdirectories in input path are checked recursively for input files, or leave empty not to use recursion
REM ISOVERWRITE:    Specify (with value 1) if an existing outputfile should be overwritten or that results should be added to it, or leave empty otherwise
REM IPFVALCOLNR:    Column name or number (one-based) of column in source IPF-file(s) with values to calculate statistics for; or leave empty to calculate timeseries statistics
REM IPFIDCOLNR:     Column name or number (one-based) of column in source IPF-file(s) that is copied to resulting IPF-file when timeseries statistics are calculated (via TS* options)
REM IPFSELCOLNRS:   Comma-seperated list with column names or numbers of other columns that should be copied to the resulting IPF-file when timeseries statistics are calculated (via TS* options)
REM TSVALCOLNR:     Column number (one-based) v1 of column in associated file(s) to create TS-statistics for (default: 1)
REM TSRESCOLNR:     Column number (one-based) v2 of column in associated file(s) to use for creating TS-residuals (v2-v1)
REM TSRESMETHOD:    Specify method for TS-residuals : 1) calculate residual between each timestamp of v2-v1 and calculate statistics over resulting residuals; 2) calculate average and defined percentiles over timestamps of v1 and v2 and calculate difference
REM TSPERIODSTART:  Start date (dd-mm-yyyy or ddmmyyyy) of period to select IPF TS-values for; note: TSPERIODSTART and/or TSPERIODEND can be empty
REM TSPERIODEND:    End date (dd-mm-yyyy or ddmmyyyy) of period to select IPF TS-values for; note: TSPERIODSTART and/or TSPERIODEND can be empty
REM DECIMALCOUNT:   Numbser of decimals that floating point values should be rounded to, or leave empty not to round
REM RESULTPATH:     Path to write results
REM RESULTFILE:     Result filename of Excel file and base name for resulting IPF-files when source IPF-files were selected; zone postfix will be added if zones are specified
SET SOURCEPATH=%DBASEPATH%\ORG\KHV\100
SET SOURCEFILTER=*.IDF
SET EXTENT=
SET PCTCLASSCOUNT=4
SET ISRECURSIVE=0
SET ISOVERWRITE=1
SET IPFVALCOLNR=
SET IPFIDCOLNR=
SET IPFSELCOLNRS=
SET TSVALCOLNR=
SET TSRESCOLNR=
SET TSRESMETHOD=
SET TSPERIODSTART=
SET TSPERIODEND=
SET DECIMALCOUNT=
SET RESULTPATH=result
SET RESULTFILE=iMODstats KHV_L1-19.xlsx

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET IMODSTATSEXE=%TOOLSPATH%\iMODstats.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-plus: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% > %LOGFILE%
   GOTO error
)

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO:

SET ROPTION=
SET EOPTION=
SET OOPTION=
SET TSCOPTION=
SET TOPTION=
SET IPFOPTION=
SET TSROPTION=
SET TSGOPTION=
SET DOPTION=/d
IF "%ISRECURSIVE%"=="1" SET ROPTION=/r
IF NOT "%EXTENT%"=="" SET EOPTION=/e:%EXTENT% 
IF "%ISOVERWRITE%"=="1" (
  REM specify option o to overwrite
  SET OOPTION=/o
) ELSE (
  REM specify option a to add to existing output
  SET OOPTION=/a
)
IF DEFINED IPFVALCOLNR SET IPFOPTION=/ipf:1,2,%IPFVALCOLNR%
IF DEFINED TSVALCOLNR (
  SET TSCOPTION=/tsc:%TSVALCOLNR%
  IF DEFINED IPFIDCOLNR SET TSCOPTION=!TSCOPTION!,%IPFIDCOLNR%
  IF DEFINED IPFSELCOLNRS SET TSCOPTION=!TSCOPTION!,%IPFSELCOLNRS%
)
IF DEFINED TSRESCOLNR (
  SET TSROPTION=/tsr:%TSRESCOLNR%
  IF DEFINED TSRESMETHOD SET TSROPTION=!TSROPTION!,%TSRESMETHOD%
)
IF DEFINED PCTCLASSCOUNT SET TOPTION=/t:%PCTCLASSCOUNT%
IF DEFINED DECIMALCOUNT SET DOPTION=/d:%DECIMALCOUNT%
IF NOT "%TSPERIODSTART%%TSPERIODEND%"=="" SET TSPOPTION=/tsp:%TSPERIODSTART%,%TSPERIODEND%

ECHO "%IMODSTATSEXE%" %OOPTION% %ROPTION% %EOPTION% %TOPTION% %DOPTION% %TSPOPTION% %IPFOPTION% %TSCOPTION% %TSROPTION% "%SOURCEPATH%" "%SOURCEFILTER%" "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE% 
"%IMODSTATSEXE%" %OOPTION% %ROPTION% %EOPTION% %TOPTION% %DOPTION% %TSPOPTION% %IPFOPTION% %TSCOPTION% %TSROPTION% "%SOURCEPATH%" "%SOURCEFILTER%" "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE% 
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
IF NOT DEFINED NOPAUSE PAUSE
