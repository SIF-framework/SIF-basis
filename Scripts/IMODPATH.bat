@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * IMODPATH.bat                            *
REM * DESCRIPTION                             *
REM *   Creates RUN-file for iMODPATH based   *
REM *   based on an input ISD-file with       *
REM *   startpoints and runs IMODPATH.        *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2016-07-01 Initial version            *
REM *******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM MODELNAME:      Modelname, used for naming of resultfolders and -files
REM RUNID:          Short ID-string for this run, that is a postfix in the ISD, defines the output subdir and is a postfix in the output filenames
REM ISDPATH:        Subdirectory with startpoints
REM ISDFILE:        Startpoints file inside the subdirectory specified by the ISDPATH parameter below
REM NLAY:           Number of modellayers
REM NPER:           Number of periods
REM SAVE_FLOWLINES: Use value 1 to save flowlines (IFF)
REM SAVE_ENDPOINTS: Use value 1 to save start- and endpoints of flowlines (IPF)
REM IFWBW:          Specify forwards or backwards flow: 0=forwards, 1=backwards
REM ISNK:           Specify how to handle weak-sinks: particles will continue (1) or stop (2) at weak sinks. If stopped a fraction can be used (3)
REM FRACTION:       Fraction in case of ISNK=3, see iMOD-manual for details
REM STOPCRIT:       Stop criteria. STOPCRIT is only applicable whenever NPER>1
REM                   1=stop particle when age is MAXT, 
REM                   2=repeat transient period in time window as specified by keywords SWINDOW and EWINDOW age if MAXT or stopped in a sink, 
REM                   3=continue with last results at end of time window until the particle terminates. 
REM MAXT:           Maximum tracing time (days): 25 jaar (9130)
REM STARTDATE:      Start date for particle tracing (yyyymmdd). Only necessary whenever NPER>1
REM SWINDOW:        Start date for time window in which particle tracing will operate (yyyymmdd). Only necessary whenever NPER > 1
REM EWINDOW:        End date for time window in which particle tracing will operate (yyyymmdd). Only necessary whenever NPER > 1
REM RESULTPATH:     Result path for IFF and IPF-files and other iMODPATH-files
REM OUTPUTFILE:     Filename for outputfile(s) (excluding extension)
SET MODELNAME=REF1_BAS
SET RUNID=BW_L2-4_9c5m5x
SET ISDPATH=startpoints
SET ISDFILE=XXX_%RUNID%.ISD
SET NLAY=19
SET NPER=1
SET SAVE_FLOWLINES=1
SET SAVE_ENDPOINTS=1
SET IFWBW=1
SET ISNK=2
SET FRACTION=0.5
SET STOPCRIT=1
SET MAXT=365.0E10
SET STARTDATE=19940101
SET SWINDOW=19940101
SET EWINDOW=20111231
SET RESULTPATH=result\%RUNID%
SET OUTPUTFILE=%MODELNAME%_%RUNID%

REM Specify model-files that define layermodel and porosity
REM BNDIDFFILENAMEBASE: Base filename or BND-files, including path and prefix except modellayernumber and IDF-extension. E.g. '%DBASEPATH%\ORG\BND\BND_L'. For a single BND-file, just leave out layerpostfix _L.
REM TOPIDFFILENAMEBASE: Base filename file or TOP-files, including path and prefix except modellayernumber
REM BOTIDFFILENAMEBASE: Base filename or BOT-files, including path and prefix except modellayernumber
REM PORAQT:             Porosity (constant value or IDF-file) for aquitards (use english decimal seperator for constant value)
REM PORAQF1:            Porosity (constant value or IDF-file) for aquifers (use english decimal seperator for constant value)
REM PORAQF2:            Optional alternative porosity (constant value or IDF-file) for aquifer of specified modellayers
REM PORAQF2LAYERS:      Commaseperated list of modellayers with alternative aquifer porosity, or leave empty to skip alternative porosity
SET BNDIDFFILENAMEBASE=%DBASEPATH%\ORG\BND\BND  
SET TOPIDFFILENAMEBASE=%DBASEPATH%\REF1\TOP\TOP_L
SET BOTIDFFILENAMEBASE=%DBASEPATH%\REF1\BOT\BOT_L
SET PORAQT=0.1
SET PORAQF1=0.3
SET PORAQF2=
SET PORAQF2LAYERS=

REM *********************
REM * Derived variables *
REM *********************
REM NSDF specfies the number of SDF files (.ISD) to be computed. In this batchfile this should be 1
SET NSDF=1
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET MSG=Copying van startpoints ISD-file to %RESULTPATH% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO COPY "%ISDPATH%\%ISDFILE%" "%RESULTPATH%" >> %LOGFILE%
COPY "%ISDPATH%\%ISDFILE%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

ECHO:
ECHO: >> %LOGFILE%

SET MSG=Creating RUN-file for iMODPATH flowpath calculation ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Start writing IMODPATH RUN-file parameters and values
ECHO %NLAY%, 					!## NLAY > %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %NPER%, 					!## NPER >> %RESULTPATH%\%OUTPUTFILE%.RUN
IF NOT "%NSDF%"=="1" (
  ECHO %NSDF% 					!## NSDF >> %RESULTPATH%\%OUTPUTFILE%.RUN
)
REM %RESULTPATH%\
ECHO "%RESULTPATH%\%ISDFILE%"  			!## ISDFILE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO "%RESULTPATH%\%OUTPUTFILE%.IFF" 		!## OUTPUTFILE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %SAVE_FLOWLINES%,%SAVE_ENDPOINTS% 		!## IMODE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %IFWBW%, 			                !## IFWBW: forwards=0; backwards=1 >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %ISNK%, 			                !## ISNK >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %FRACTION%, 				!## FRACTION >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %STOPCRIT%, 				!## STOPCRIT >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %MAXT%,  					!## MAXT >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %STARTDATE%, 				!## STARTDATE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %SWINDOW%, 				!## startwindow >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %EWINDOW%, 				!## endwindow >> %RESULTPATH%\%OUTPUTFILE%.RUN

FOR /L %%a IN (1,1,%NLAY%) DO (
  IF "%BNDIDFFILENAMEBASE:~2,2%"=="_L" (
    SET BNDIDFFILENAME=%BNDIDFFILENAMEBASE%%%a.IDF
  ) ELSE (
    SET BNDIDFFILENAME=%BNDIDFFILENAMEBASE%.IDF
  )
  ECHO "!BNDIDFFILENAME!" 		        !## IBOUND >> %RESULTPATH%\%OUTPUTFILE%.RUN
  ECHO "%TOPIDFFILENAMEBASE%%%a.IDF" 		!## TOP >> %RESULTPATH%\%OUTPUTFILE%.RUN
  ECHO "%BOTIDFFILENAMEBASE%%%a.IDF" 		!## BOT >> %RESULTPATH%\%OUTPUTFILE%.RUN
  SET ISPORAQF2LAYER=0
  FOR %%D IN (%PORAQF2LAYERS%) DO (
    IF "%%a"=="%%D" SET ISPORAQF2LAYER=1
  )
  IF "!ISPORAQF2LAYER!"=="0" (
    ECHO %PORAQF1%, 				!## PORAQF >> %RESULTPATH%\%OUTPUTFILE%.RUN
  ) ELSE (
    ECHO %PORAQF2%, 				!## PORAQF >> %RESULTPATH%\%OUTPUTFILE%.RUN
  )
  IF %%a NEQ %NLAY% (
    ECHO %PORAQT%, 				!## PORAQT >> %RESULTPATH%\%OUTPUTFILE%.RUN
  )
)

FOR /L %%a IN (1,1,%NLAY%) DO (
  FOR %%b IN (bdgfrf,bdgfff,bdgflf) DO (
    IF %%b==bdgflf (
      IF %%a neq %NLAY% (
        ECHO "%RESULTSPATH%\%MODELNAME:_=\%\%%b\%%b_STEADY-STATE_l%%a.IDF" >> %RESULTPATH%\%OUTPUTFILE%.RUN
      )
    )
    IF %%b neq bdgflf (
      ECHO "%RESULTSPATH%\%MODELNAME:_=\%\%%b\%%b_STEADY-STATE_l%%a.IDF" >> %RESULTPATH%\%OUTPUTFILE%.RUN
    )
  )
)
SET MSG=  Finished creating IMODPATH RUN-file
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO:
ECHO: >> %LOGFILE%

ECHO FUNCTION=IMODPATH > %RESULTPATH%\%OUTPUTFILE%.INI
ECHO RUNFILE=%RESULTPATH%\%OUTPUTFILE%.RUN >> %RESULTPATH%\%OUTPUTFILE%.INI

REM Remove previous results
IF "%SAVE_ENDPOINTS%"=="1" (
  IF EXIST "%RESULTPATH%\%OUTPUTFILE%.IPF" DEL "%RESULTPATH%\%OUTPUTFILE%.IPF"
)
IF "%SAVE_FLOWLINES%"=="1" (
  IF EXIST "%RESULTPATH%\%OUTPUTFILE%.IFF" DEL "%RESULTPATH%\%OUTPUTFILE%.IFF"
)

SET MSG=Starting iMOD with IMODPATH RUN-file %RESULTPATH%\%OUTPUTFILE%.RUN ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%iMODEXE%" "%RESULTPATH%\%OUTPUTFILE%.INI" >> %LOGFILE%
"%iMODEXE%" "%RESULTPATH%\%OUTPUTFILE%.INI" >> %LOGFILE%
IF EXIST TMP RMDIR TMP >NUL 2>&1

IF NOT EXIST "%RESULTPATH%\%OUTPUTFILE%.IPF" (
  IF NOT EXIST "%RESULTPATH%\%OUTPUTFILE%.IFF" (
    ECHO No result, some error occurred!
    ECHO No result, some error occurred! >> %LOGFILE%
    GOTO error
  )
)

SET MSG=  Finished IMODPATH run %OUTPUTFILE%.RUN
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

IF "%SAVE_ENDPOINTS%"=="1" (
  SET MSG=Rounding values in IPF-files ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "NumberRounder.exe" "%RESULTPATH%" "%OUTPUTFILE%.ipf" 3 . " " >> %LOGFILE%
  "%TOOLSPATH%\NumberRounder.exe" "%RESULTPATH%" "%OUTPUTFILE%.ipf" 3 . " " >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error

  REM Create a copy of the result
  ECHO COPY "%RESULTPATH%\%OUTPUTFILE%.IPF" "%RESULTPATH%\%OUTPUTFILE%_EP.IPF" >> %LOGFILE%
  COPY "%RESULTPATH%\%OUTPUTFILE%.IPF" "%RESULTPATH%\%OUTPUTFILE%_EP.IPF" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

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
IF "%NOPAUSE%"=="" PAUSE
