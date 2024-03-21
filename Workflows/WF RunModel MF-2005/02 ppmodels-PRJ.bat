@ECHO OFF
REM *****************************************
REM * SIF-basis v2.2.0 (Sweco)              *
REM *                                       *
REM * runmodels.bat                         *
REM * DESCRIPTION                           *
REM *   Starts modelrun postprocessing      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)  *
REM * VERSION: 2.1.0                         *
REM * MODIFICATIONS                         *
REM *   2016-06-15 Initial version          *
REM *****************************************
CALL :Initialization

REM ***************************
REM * RUN/PRJ-file definition *
REM ***************************

REM Specify one or more RUN/PRJ-files that will be searched in this directory, wildcards are allowed (e.g. *_STAT_K?Vx*.RUN)
SET RUNFILEFILTER=*.PRJ
REM The name of the RUN/PRJ-file should be build up in one of the formats:
REM <RUNFILEPREFIX>_<MODELNAME>.[RUN|PRJ]
REM <RUNFILEPREFIX>_<MODELNAME>_<SUBMODELNAME>.[RUN|PRJ] or
REM <RUNFILEPREFIX>_<MODELNAME>_<SUBMODELNAME>_<MODELPOSTFIX>.[RUN|PRJ]
REM With:
REM RUNFILEPREFIX: Unique projectspecific name or abbreviation ('_'-symbols are allowed), e.g. 'AW_STAT'. This prefix is defined with the variable 'RUNFILEPREFIX' in "SETTINGS\SIF.Settings.ModelRuns.bat".
REM MODELNAME:     Base name or abbreviation of the model or modelgroup, e.g. ORG, BASIS0, BASIS1, KAL1, etc.
REM SUBMODELNAME;  Optional: a postfix to further define a submodel/modelvariant, e.g. ORG_BAS voor initial basic version, BASIS1_02KHVL1-4 for the second modification in group BASIS1 with changes in KHV-values of L1-4
REM MODELPOSTFIX:  Optional: an extra postfix to futher define a submodel/modelvariant, e.g. BASIS0_07GV_KHVx2

REM ********************
REM * Script variables *
REM ********************

REM Define processing for each RUN/PRJ-file (use 1 to execute, 0 to skip)
REM -----------------------------------------------------------------
REM DORUN:              1 - Start modelrun with defined iMODFLOW version
REM DORUNRES:           1 - Determine modelresiduals for calibration IPF-files as defined below by CALSETPATH and CALSETi and CALVALCOL
REM DORUNPOST:          1 - Perforn postprocessing: seepage for L1 in millimeters, HEAD relative to surfacelevel
REM DOMAPHEAD:          1 - Create maps with heads per modellayer
REM DOMAPBDG:           1 - Create maps with BDG-fluxes (FRF, FFF, FLF) per modellayer
REM DOMAPRES:           1 - Create residuals-maps per modellayer
REM DOEFFECT:           1 - Create effect-maps and IDF-files for in relation to a defined base model ( EFFECTMODELNAME-variable) 
REM DODELETEFFECTIDFS:  1 - Delete effect IDF-files after maps have been created
REM DOPAUSE:            1 - Pause after individual modelruns; use 0 to not pause after each individual modelrun
REM DOOVERWRITELOGFILE: 1 - Delete existing logfile before starting; use 0 to append to currently existing logfile with same name as this batchfile
SET DORUN=0
SET DORUNRES=1
SET DORUNPOST=0
SET DOMAPHEAD=0
SET DOMAPBDG=0
SET DOMAPRES=0
SET DOEFFECT=0
SET DODELETEFFECTIDFS=0
SET DOPAUSE=0
SET DOOVERWRITELOGFILE=1

REM Effect model settings
REM -----------------------
REM EFFECTMODELNAME: Effects will be calculated relative to this model for each of the RUN/PRJ-files as defined by the RUNFILEFILTER variable
SET EFFECTMODELNAME=BASIS1_STAT-PRJ

REM Residual settings
REM -------------------
REM CALSETPATH: Path to all calibrationset IPF-files
REM CALSETi:    Calibration set(s). Four seperate sets of IPF-files can be defined. Give the filename without the postfix with the layer number "_Li", so write "kalibratieset" for files "kalibratiset_L1.IPF", "kalibratieset_L2.IPF', etc, of leave empty if not used
REM CALVALCOL:  Columnnumber (one-based) in the calibrationset IPF-file(s) with the calibration value (e.g. an average measured head) for creating reaiduals files and residual statistics (if DORUNRES=1)
REM WCOLIDX:    Columnnumber (one-based) in the calibrationset IPF-file(s) with a weight to create weighted statistics, or leave empty otherwise
REM             Note: Plotting residualmaps with weights will give unexpected results. Run again with empty WCOLIDX-variable.
SET CALSETPATH=%DBASEPATH%\BASIS1\MEASUREMENTS\STAT
SET CALSET1=PeilbuisDataIBR30-KalSet
SET CALSET2=PeilbuisDataIBR30-ValSet
SET CALSET3=
SET CALSET4=
set CALVALCOL=9
SET WCOLIDX=

REM Local settings
REM --------------
REM Here default settings from "SETTINGS\SIF.Settings.*.bat" can be overruled; e.g. the name of the surfacelevel file, or leave empty to avoid using a surfacelevel file
REM SET SURFACELEVELIDF=%DBASEPATH%\ORG\MAAIVELD\25\AHN25m.IDF
REM SET MODELEXTENT=%MODELEXTENT0%
REM SET MAPEXTENT=179000,437000,246000,490000
REM SET iMODFLOWEXE=%EXEPATH%\iMODFLOW\iMODFLOW_X64_Vxxx.exe
REM SET RESIDULEGEND=residuenXXX.leg
REM SET PKSPROCESSCOUNT=1

REM *********************
REM * Derived variables *
REM *********************
REM SCRIPTNAME: name of this batchfile wihout path and extension
SET SCRIPTNAME=%~n0

REM *******************
REM * Script commands *
REM *******************
IF "%DOOVERWRITELOGFILE%" == "1" (
  IF EXIST "%SCRIPTNAME%.log" DEL "%SCRIPTNAME%.log"
)

REM Start batchprocedures for all RUN/PRJ-files
CALL "%TOOLSPATH%\SIF.iMOD.runbatch.bat"
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
  CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
  CALL "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat"
  CALL "%SETTINGSPATH%\SIF.Settings.Model.bat"
  CALL "%SETTINGSPATH%\SIF.Settings.Maps.bat"
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
