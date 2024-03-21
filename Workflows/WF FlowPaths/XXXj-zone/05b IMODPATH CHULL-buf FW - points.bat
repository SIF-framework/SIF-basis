@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * IMODPATH.bat                            *
REM * DESCRIPTION                             *
REM *   Creates RUN-file for iMODPATH based   *
REM *   on an input ISD-file runs IMODPATH    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2016-07-01 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM This batchfiles runs a flowpath calculation using the iMOD-batchfunction IMODPATH for specified model results, layermodel and startpoints
REM Check iMOD-manual for details. Before running this batchfile, create an ISD-file with startpoints using the ISDcreate batchfile. 
REM Currently only a steady-state run is supported, for transient runs check the iMOD-manual for details about the RUN-file format for IMODPATH

REM ********************
REM * Script variables *
REM ********************
REM MODELNAME:      Modelname, used to retrieve BDGFxF-files and naming of resultfolders and -files; name should refer to path under RESULTSPATH and use underscores for subdirectory levels (e.g. ORG_BAS)
REM RUNID:          Short ID-string for this flowpath run which defines the output subdir and is a postfix in the output filenames
REM ISDPATH:        Path to ISD-file with startpoints
REM ISDFILE:        Filename of ISD-file with startpoints. It is also allowed to use an IPF-file; in that case ensure that the first 3 columns contain the X-, Y- and Z-coordinates.
REM SAVE_FLOWLINES: Use value 1 to save flowlines (IFF)
REM SAVE_ENDPOINTS: Use value 1 to save start- and endpoints of flowlines (IPF)
REM IFWBW:          Specify forwards or backwards flow: 0=forwards, 1=backwards
REM ISNK:           Specify how to handle weak-sinks: particles will continue (1) or stop (2) at weak sinks. If stopped a fraction can be used (3)
REM FRACTION:       Fraction in case of ISNK=3; Particels will stop if the outflow in a cell in larger than the defined fraction of the total inflow in that cell. 
REM                 E.g. FRACTION=0.25 will stop particles in a cell if more than 25% of the total inflow does not leave the cell (and is removed from the model).
REM MAXT:           Maximum tracing time (days), e.g. use 9130 for 25 year
REM RESULTPATH:     Result path for IFF and IPF-files and other iMODPATH-files
REM OUTPUTFILE:     Filename for IFF- and/or IPF-outputfile (excluding extension)
SET MODELNAME=%MODELREF%
SET RUNID=FW_CHULLBUFFER
SET ISDPATH=%RESULTPATH_SP%
SET ISDFILE=%RUNID%-P.ISD
SET SAVE_FLOWLINES=0
SET SAVE_ENDPOINTS=1
SET IFWBW=0
SET ISNK=%FPFW_ISNK%
SET FRACTION=%FPFW_FRACTION%
SET MAXT=%FPFW_MAXT%
SET RESULTPATH=%RESULTPATH_RUNS%\%RUNID%
SET OUTPUTFILE=%MODELREF%_%RUNID%

REM Specify model-files that define layermodel and porosity
REM NLAY:               Number of modellayers in input model
REM BNDIDFFILENAMEBASE: Base filename or BND-files, including path and prefix except modellayernumber and IDF-extension. E.g. '%DBASEPATH%\ORG\BND\BND_L'. For a single BND-file, just leave out layerpostfix _L.
REM TOPIDFFILENAMEBASE: Base filename file or TOP-files, including path and prefix except modellayernumber
REM BOTIDFFILENAMEBASE: Base filename or BOT-files, including path and prefix except modellayernumber
REM PORAQT:             Porosity (constant value or IDF-file) for aquitards (use english decimal seperator for constant value)
REM PORAQF1:            Porosity (constant value or IDF-file) for aquifers (use english decimal seperator for constant value)
REM PORAQF2:            Optional alternative porosity (constant value or IDF-file) for aquifer of specified modellayers
REM PORAQF2LAYERS:      Commaseperated list of modellayers with alternative aquifer porosity, or leave empty to skip alternative porosity
SET NLAY=%NLAY%
SET BNDIDFFILENAMEBASE=%BNDIDFFILENAMEBASE%
SET TOPIDFFILENAMEBASE=%TOPIDFFILENAMEBASE%
SET BOTIDFFILENAMEBASE=%BOTIDFFILENAMEBASE%
SET PORAQT=%PORAQT%
SET PORAQF1=%PORAQF1%
SET PORAQF2=%PORAQF2%
SET PORAQF2LAYERS=%PORAQF2LAYERS%

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET MSG=Copying startpoints ISD-file to %RESULTPATH% ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
IF NOT EXIST "%ISDPATH%\%ISDFILE%" (
  ECHO ISD-file not found: %ISDPATH%\%ISDFILE%
  ECHO ISD-file not found: %ISDPATH%\%ISDFILE% >> %LOGFILE%
  GOTO error
)
ECHO COPY "%ISDPATH%\%ISDFILE%" "%RESULTPATH%" >> %LOGFILE%
COPY "%ISDPATH%\%ISDFILE%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

SET MSG=Creating RUN-file for iMODPATH flowpath calculation ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%

REM Start writing IMODPATH RUN-file parameters and values
ECHO %NLAY%, 					!## NLAY > %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO 1, 					!## NPER >> %RESULTPATH%\%OUTPUTFILE%.RUN
REM Currently only a single ISD-file is supported; in that case NISD should be specified
REM  ECHO %NISD% 					!## NISD >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO "%RESULTPATH%\%ISDFILE%"  			!## ISDFILE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO "%RESULTPATH%\%OUTPUTFILE%.IFF" 		!## OUTPUTFILE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %SAVE_FLOWLINES%,%SAVE_ENDPOINTS% 		!## IMODE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %IFWBW%, 			                !## IFWBW forwards=0; backwards=1 >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %ISNK%, 			                !## ISNK >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %FRACTION%, 				!## FRACTION >> %RESULTPATH%\%OUTPUTFILE%.RUN
REM Specify dummy STOPCRIT, which is not used for NPER=1
ECHO 1, 					!## STOPCRIT >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO %MAXT%,  					!## MAXT >> %RESULTPATH%\%OUTPUTFILE%.RUN
REM Specify dummy dates that are not used for NPER=1; this is required by IMODPATH according to the iMOD-manual
ECHO 19900101,	 				!## STARTDATE >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO 19900101,	 				!## startwindow >> %RESULTPATH%\%OUTPUTFILE%.RUN
ECHO 20991231,	 				!## endwindow >> %RESULTPATH%\%OUTPUTFILE%.RUN

FOR /L %%a IN (1,1,%NLAY%) DO (
  IF "%BNDIDFFILENAMEBASE:~-2,2%"=="_L" (
    SET BNDIDFFILENAME=%BNDIDFFILENAMEBASE%%%a.IDF
  ) ELSE (
    SET BNDIDFFILENAME=%BNDIDFFILENAMEBASE%.IDF
  )
  ECHO "!BNDIDFFILENAME!" 		        !## IBOUND >> %RESULTPATH%\%OUTPUTFILE%.RUN
  IF NOT EXIST "!BNDIDFFILENAME!" (
    ECHO BND-file not found, check BNDIDFFILENAMEBASE-definition for errors: !BNDIDFFILENAME!
    ECHO BND-file not found, check BNDIDFFILENAMEBASE-definition for errors: !BNDIDFFILENAME! >> %LOGFILE%
    GOTO error
  )
  
  ECHO "%TOPIDFFILENAMEBASE%%%a.IDF" 		!## TOP >> %RESULTPATH%\%OUTPUTFILE%.RUN
  IF NOT EXIST "%TOPIDFFILENAMEBASE%%%a.IDF" (
    ECHO TOP-file not found, check TOPIDFFILENAMEBASE-definition for errors: %TOPIDFFILENAMEBASE%%%a.IDF
    ECHO TOP-file not found, check TOPIDFFILENAMEBASE-definition for errors: %TOPIDFFILENAMEBASE%%%a.IDF >> %LOGFILE%
    GOTO error
  )

  ECHO "%BOTIDFFILENAMEBASE%%%a.IDF" 		!## BOT >> %RESULTPATH%\%OUTPUTFILE%.RUN
  IF NOT EXIST "%BOTIDFFILENAMEBASE%%%a.IDF" (
    ECHO BOT-file not found, check BOTIDFFILENAMEBASE-definition for errors: %BOTIDFFILENAMEBASE%%%a.IDF
    ECHO BOT-file not found, check BOTIDFFILENAMEBASE-definition for errors: %BOTIDFFILENAMEBASE%%%a.IDF >> %LOGFILE%
    GOTO error
  )

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
      IF %%a NEQ %NLAY% (
        ECHO "%RESULTSPATH%\%MODELNAME:_=\%\%%b\%%b_STEADY-STATE_l%%a.IDF" >> %RESULTPATH%\%OUTPUTFILE%.RUN
      )
    )
    IF %%b NEQ bdgflf (
      ECHO "%RESULTSPATH%\%MODELNAME:_=\%\%%b\%%b_STEADY-STATE_l%%a.IDF" >> %RESULTPATH%\%OUTPUTFILE%.RUN
    )
  )
)

REM Create INI-file to run IMODPATH
ECHO FUNCTION=IMODPATH > %RESULTPATH%\%OUTPUTFILE%.INI
ECHO RUNFILE=%RESULTPATH%\%OUTPUTFILE%.RUN >> %RESULTPATH%\%OUTPUTFILE%.INI

REM Remove previous results
IF "%SAVE_ENDPOINTS%"=="1" (
  IF EXIST "%RESULTPATH%\%OUTPUTFILE%.IPF" DEL "%RESULTPATH%\%OUTPUTFILE%.IPF"
)
IF "%SAVE_FLOWLINES%"=="1" (
  IF EXIST "%RESULTPATH%\%OUTPUTFILE%.IFF" DEL "%RESULTPATH%\%OUTPUTFILE%.IFF"
)

SET MSG=Starting iMOD with IMODPATH RUN-file %OUTPUTFILE%.RUN ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%iMODEXE%" "%RESULTPATH%\%OUTPUTFILE%.INI" >> %LOGFILE%
"%iMODEXE%" "%RESULTPATH%\%OUTPUTFILE%.INI" >> %LOGFILE%
IF EXIST TMP RMDIR TMP >NUL 2>&1

IF NOT EXIST "%RESULTPATH%\%OUTPUTFILE%.IPF" (
  IF NOT EXIST "%RESULTPATH%\%OUTPUTFILE%.IFF" (
    ECHO     no result, some error occurred!
    ECHO     no result, some error occurred! >> %LOGFILE%
    GOTO error
  )
)

SET MSG=finished IMODPATH run successfully
ECHO     %MSG%
ECHO %MSG% >> %LOGFILE%

IF "%SAVE_ENDPOINTS%"=="1" (
  SET MSG=Rounding values in resulting IPF-files ...
  ECHO   !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%TOOLSPATH%\NumberRounder.exe" "%RESULTPATH%" "%OUTPUTFILE%.ipf" 3 . " " >> %LOGFILE%
  "%TOOLSPATH%\NumberRounder.exe" "%RESULTPATH%" "%OUTPUTFILE%.ipf" 3 . " " >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error

  REM Create a copy of the result to analyse start- en endpoints seperately in iMOD
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
  IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
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
