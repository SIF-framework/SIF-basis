@ECHO OFF
REM ***********************************************************
REM * SIF-basis v2.1.0 (Sweco)                                *
REM *                                                         *
REM * Residuanalyse.bat                                       *
REM * AUTHOR(S): Koen van der Hauw (Sweco)                    *
REM * DESCRIPTION                                             *
REM *   Residual analysis of steady-state model(s) by         *
REM *   creating Excelsheet with residual statistics, incl.   *
REM *   comparison sheet, and IPF-files that compare absolute *
REM *   residuals between first and other models              *
REM * VERSION: 2.0.0                                          *
REM * MODIFICATIONS                                           *
REM *   2016-10-01 Initial version                            *
REM ***********************************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat" CALL "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat"

REM ********************
REM * Script variables *
REM ********************
REM MODELNAMES: Comma-seperated list of one or more modelnames, including submodelname: <MODELNAME>_<SUBMODELNAME>. Residual IPF-files are search in: %RESULTSPATH%\!MODELNAME:_=\!\%RESIDUALDIR%
REM             Note: the same calibration set is used with all models. If overwrite is specified, for the first model, the Excelsheet is overwritten, then merged.
REM CALSETNAME: Name of calibration set, used as a label in result table
REM IPFFILTER:  Specify a filename filter for the files to be processed from the residual subdirectory under the RESULTS directory of the modelSUBDIRS (? and *-characters can be used as wildcards)
REM Specify column numbers in measurement IPF-files (first column has number 1)
REM   IDCOLIDX:  Column with IDs
REM   LAYCOLIDX: Column with modellayers
REM   OBSCOLIDX: Column with measured/observed heads
REM   WCOLIDX:   Column with weights for residual computation, or use 0 if no weight should be used
REM   SIMCOLIDX: Column with simulated heads (this is 1 higher than the number of columns in the measurement IPFs)
REM   RESCOLIDX: Column number of added residuals (this is 2 higher than the number of columns in the measurement IPFs)
REM   EXTRACOLINDICES: Comma seperated list with number(s) of one or more optional columns that should be added in the output tables (or leave empty)
REM   EXTRACOLNAMES:   Comma-seperated list with name(s) of each of the optionally added columns (or leave empty)
REM SKIPPEDVALUES: Comma-seperated list with values that should be skipped in the residual analysis (e.g. NoData-values in simulated heads)
REM MODELLAYERS:   Comma-seperated list of modellayernumber (integer) to process, or leave empty to process all modellayers found in the specified IPF-points
REM PCTCLASSCOUNT: Number of percentile classes in added statistics
REM EXTENT:        Extent for residual analysis as xll,yll,xur,yur (within extent of specified IPF residual files), or leave empty 
REM OVERWRITE:     Specify if outputfile should be overwritten or appended to (use 0 to append, use 1 to overwrite)
REM RESULTPATH:    Path to subdirectory to write results to 
REM RESULTFILE:    Name of ouput Excelsheet (including xslx-extension)
SET MODELNAMES=ORG_BAS,BASIS0_01XXX,BASIS0_02XXX,BASIS0_03XXX
SET CALSETNAME=Kalibratieset
SET IPFFILTER=*stat_L*.IPF
SET IDCOLIDX=3
SET LAYCOLIDX=10
SET OBSCOLIDX=9
SET WCOLIDX=0
SET SIMCOLIDX=12
SET RESCOLIDX=13
SET EXTRACOLINDICES=6,7,8
SET EXTRACOLNAMES=Surfacelevel,FilterTop,FilterBot
SET SKIPPEDVALUES=-999.99,-9999
SET MODELLAYERS=
SET PCTCLASSCOUNT=4
SET EXTENT=
SET OVERWRITE=1
SET RESULTPATH=result
SET RESULTFILE=Residuals ORG-BASIS0.xlsx

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
IF NOT DEFINED RESIDUALDIR SET RESIDUALDIR=residu

REM ******************
REM * Script commands *
REM ******************
SETLOCAL ENABLEDELAYEDEXPANSION

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Rounding residuals
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
FOR %%M IN (%MODELNAMES%) DO (
  SET MODELNAME=%%M
  SET MODELPATH=!MODELNAME:_=\!
  SET MSG=  Rounding residuals for !MODELNAME! ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%TOOLSPATH%\NumberRounder.exe" "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" *.IPF 2 . , >> %LOGFILE%
  "%TOOLSPATH%\NumberRounder.exe" "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" *.IPF 2 . , >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)
ECHO:
ECHO: >> %LOGFILE%

SET EXTENTOPTION=
SET WEIGHTOPTION=
SET SKIPOPTION=
IF DEFINED EXTENT SET EXTENTOPTION=/e:%EXTENT%
IF DEFINED SKIPPEDVALUES SET SKIPOPTION=/s:%SKIPPEDVALUES%
IF NOT "%WCOLIDX%"=="0" SET WEIGHTOPTION=/w:%WCOLIDX%

SET MSG=Creating residual sheet "%RESULTFILE%" for calibration set %CALSETNAME%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
FOR %%M IN (%MODELNAMES%) DO (
  SET MODELNAME=%%M
  SET MODELPATH=!MODELNAME:_=\!

  SET MSG=  Creating residual sheet for model !MODELNAME! ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET OVERWRITEOPTION=
  IF "!OVERWRITE!"=="1" (
    SET OVERWRITEOPTION=/o
  ) ELSE (
    SET OVERWRITEOPTION=
  )
  SET MODELLAYEROPTION=
  IF NOT "%MODELLAYERS%" == "" (
    SET MODELLAYEROPTION=/m:%MODELLAYERS%
  )
  IF "%EXTRACOLINDICES%"=="" (
    ECHO "%TOOLSPATH%\ResidualAnalysis.exe" /b !OVERWRITEOPTION! !MODELLAYEROPTION! %EXTENTOPTION% %WEIGHTOPTION% !SKIPOPTION! /d:!MODELNAME!,"%CALSETNAME%" /p:4 /s:-999.99 "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" "%IPFFILTER%" %IDCOLIDX% %LAYCOLIDX% %OBSCOLIDX% %SIMCOLIDX% %RESCOLIDX% "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
    "%TOOLSPATH%\ResidualAnalysis.exe" /b !OVERWRITEOPTION! !MODELLAYEROPTION! %EXTENTOPTION% %WEIGHTOPTION% !SKIPOPTION! /d:!MODELNAME!,"%CALSETNAME%" /p:4 /s:-999.99 "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" "%IPFFILTER%" %IDCOLIDX% %LAYCOLIDX% %OBSCOLIDX% %SIMCOLIDX% %RESCOLIDX% "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
  ) ELSE (
    ECHO "%TOOLSPATH%\ResidualAnalysis.exe" /b !OVERWRITEOPTION! !MODELLAYEROPTION! %EXTENTOPTION% %WEIGHTOPTION% !SKIPOPTION! /d:!MODELNAME!,"%CALSETNAME%" /c:%EXTRACOLINDICES% /n:"%EXTRACOLNAMES%" /p:4 /s:-999.99 "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" "%IPFFILTER%" %IDCOLIDX% %LAYCOLIDX% %OBSCOLID% %SIMCOLIDX% %RESCOLIDX% "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
    "%TOOLSPATH%\ResidualAnalysis.exe" /b !OVERWRITEOPTION! !MODELLAYEROPTION! %EXTENTOPTION% %WEIGHTOPTION% !SKIPOPTION! /d:!MODELNAME!,"%CALSETNAME%" /c:%EXTRACOLINDICES% /n:"%EXTRACOLNAMES%" /p:4 /s:-999.99 "%RESULTSPATH%\!MODELPATH!\%RESIDUALDIR%" "%IPFFILTER%" %IDCOLIDX% %LAYCOLIDX% %OBSCOLIDX% %SIMCOLIDX% %RESCOLIDX% "%RESULTPATH%\%RESULTFILE%" >> %LOGFILE%
  )
  IF ERRORLEVEL 1 GOTO error

  IF EXIST ResidualAnalysis.log (
    ECHO ResidualAnalysis logfile: >> %LOGFILE%
    TYPE ResidualAnalysis.log >> %LOGFILE%
    DEL ResidualAnalysis.log
    IF ERRORLEVEL 1 GOTO error
  )
  
  SET OVERWRITE=0
)
ECHO:
ECHO: >> %LOGFILE%

SET MSG=Finished residual analysis, see:
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET MSG=-logfile "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET MSG=-Excelsheet "%RESULTFILE%" for statistics
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel 0 for higher level scripts
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
IF "%NOPAUSE%"=="" PAUSE
