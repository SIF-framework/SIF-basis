@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * runmodel-PRJ MF-2005.bat               *
REM * DESCRIPTION                            *
REM *   Process/run PRJ-file for MF-2005     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2021-04-01 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
IF EXIST "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat" CALL "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat"

REM *********************
REM * Script parameters *
REM *********************
REM PRJFILE:        Filename of PRJ-file to start. If PRJFILE is empty, the last PRJ-file in the directory will be used
REM EXTENT:         Extent (XLL,YLL,XUR,YUR) for this modelrun/conversion
REM CELLSIZE:       Cellsize for modelresults
REM RESULTPATH:     Path to write NAM-file and modelresults to, or leave empty to write to %RESULTSPATH% plus subdirectories seperated by underscore in PRJFILE-name (excluding prefix MODELREF0)
REM SIM_TYPE:       Simulation type for the PRJ-NAM conversion: 1) to export to RUN-file; 2) to export to standard MODFLOW2005 NAM-file; 3) to export to a standard MODFLOW6 NAM-file; 4) to export to iMOD-WQ (Seawat) RUN-file; 5) to export to iMOD-WQ (MT3D) RUN-file
REM ISS:            Type of time configuration to be added to RUNFILE or NAMFILE: for steady state ISS=0, for transient ISS=1
REM ICONSISTENCY:   Method to correct layer thickness of 0 automatically, use one of the following values (see iMOD-manual for details, option 2 is iMOD default)
REM MINTHICKNESS:   Minimal thickness (meters) for model layers as used when ICONSISTENCY=2 (default iMOD value is 0.1 meter).
REM ISCLEANRESULT:  Specify (with value 1) that existing files in RESULTPATH should be removed before starting conversion of PRJ-file
REM ISPRJCONVERTED: Specify (with value 1) if PRJ-file should be converted to NAM-file, or leave empty to use existing, corresponding NAM-file in RESULTPATH
REM ISNAMFILERUN:   Specify (with value 1) if converted NAM-file should be run with MODFLOW, or leave empty to skip modelrun
REM MINKD:          Minimal horizontal conductance kD (m2/d) that is assigned internally to aquifers, e.g. MINKD=0.01; default MINKD=0.0
REM MINC:           Minimal vertical resistance c (d) that is assigned internally to aquitards, e.g. MINC=1.0; default MINC=0.0
REM ICHKCHD:        Specify (with value 1) to convert constant head cells (from the read starting heads) that are not belonging to the layer to which they are assigned. 
REM                 If a value exceeds the top of a model layer to which it is assigned, the boundary value is turned into 99 and is converted to an active node. 
REM ICONCHK:        Specify (with value 1) if drainage levels should be corrected during simulation: higher or equal to existing level from the RIV/ISG-package; or use 0 (default) to prevent automatic corrections.
REM IDEFLAYER:      Method to assign river-elements to model layers. A constant value or an IDF-file is allowed. Leave empty to ignore or use one of the following options: 
REM                 - IDEFLAYER=0 to assign river-elements into layers based upon water level and bottom elevation (default).
REM                 - IDEFLAYER=1 to assign the river-elements to all layers starting from the first active model layer up to the layer in which the bottom elevation exists. 
REM                 - IDEFLAYER=2 to assign the river-elements to the lowest model layer that it intersects.
REM DISTRCOND:      Specify the method to distribute the conductance among (automatically) intersected model layers for river-elements. A constant value or an IDF-file is allowed (scaled with most occuring):
REM                 Allowed values to distribute the conductance: 0) method upto iMOD 5.5; 1)) evenly; 2) weighted by intersection length; 3) weighted by layer thicknes; 4) weighted by transmissivity; 5) weighted by permeability
REM SSYSTEM:        Specify (with value 1) to sum each package system into a single file. For SIM_TYPE 1 or 2, this only affects RIV/DRN-packages; for SIM_TYPE 3 this affects all packages. Ignored for SIM_TYPE > 3.
REM ITT:            Time interval category for transient models (ISS=1), use 3 to denote days. Check iMOD-manual for other values.
REM IDT:            Time interval of time steps corresponding to the chosen time interval category ITT (ISS=1), e.g. IDT=7 to denote the 7 days whenever ITT=3. This keyword is only compulsory whenever TIMFNAME is absent.
REM ISTEADY:        Specify with value 1 to include an initial steady-state time step to model. This will add packages with the time stamp STEADY-STATE to first stress-period of model. By default ISTEADY=0. Or leave empty to skip.
REM NSTEP:          Number of time steps within each stress period (default: 1). For convergence issues, increasing NSTEP might help.
REM DWEL:           Specify with value 1 to overrule any intermediate dates specified for the WEL package in the PRJ-file. In that case and WELLS are updated for each stress period, specify DWEL=0 (or empty) to suppress this.
REM SDATE:          Initial date of the model, as yyyymmdd (e.g. 20121231) to include a date string to the converted files (e.g. HEAD_20121231_L1.IDF), or leave empty to skip. Check iMOD-manual for details.
REM EDATE:          Initial date of the model, as yyyymmdd (e.g. 20121231) to include a date string to the converted files (e.g. HEAD_20121231_L1.IDF), or leave empty to skip. Check iMOD-manual for details.
REM TIMFNAME:       Filename of a TIM-file with timesteps to simulate. Check iMOD-manual for format.
REM IMODEXE:        Path to iMOD-executable
REM IMODFLOWEXE:    Path to iMODFLOW-executable (which has to be defined for SIM_TYPE=2)
REM SAVESHD:        Specify comma-seperated list of modellayers for which HEAD-files should be saved; use SAVESHD=0 if no layers should be saved, use SAVESHD=-1 to save all layers 
REM SAVEFLX:        Specify comma-seperated list of modellayers for which BDGFxF-files should be saved; use SAVESHD=0 if no layers should be saved, use SAVESHD=-1 to save all layers
REM SAVEXXX:        Specify comma-seperated list of modellayers for which BDGXXX-files should be saved, with XXX one of: WEL, DRN, RIV, GHB, RCH. Use -1 to save all layers, use 0 or leave undefined to skip.
REM Note: Check iMOD-manual for other options to convert/run PRJ-file.
SET PRJFILE=
SET EXTENT=%MODELEXTENT%
SET CELLSIZE=100
SET RESULTPATH=
SET SIM_TYPE=2
SET ISS=0
SET ICONSISTENCY=2
SET MINTHICKNESS=0.0001
SET ISCLEANRESULT=1
SET ISPRJCONVERTED=1
SET ISNAMFILERUN=1
SET MINKD=1
SET MINC=0.1
SET ICHKCHD=1
SET ICONCHK=0
SET IDEFLAYER=2
SET DISTRCOND=5
SET SSYSTEM=0
SET ITT=3
SET IDT=1
SET ISTEADY=1
SET NSTEP=
SET DWEL=1
SET SDATE=
SET EDATE=
SET TIMFNAME=
SET IMODEXE=%IMODEXE%
SET IMODFLOWEXE=%IMODFLOWEXE%
SET SAVESHD=-1
SET SAVEFLX=-1
SET SAVEWEL=
SET SAVERIV=
SET SAVEDRN=
SET SAVEGHB=
SET SAVEISG=
SET SAVERCH=

REM *********************
REM * Derived variables *
REM *********************
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET SCRIPTNAME=%~n0
SET LOGFILE="%THISPATH%\%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET ASKCONTINUERUN=%ASKCONTINUERUN%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: Running PRJ-file ...

REM Rename old logfile to bak as a backup
IF EXIST %LOGFILE% ( 
  IF EXIST %LOGFILE:.log=.bak% DEL %LOGFILE:.log=.bak% >NUL
  REN %LOGFILE% "%SCRIPTNAME%.bak"
)

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check that iMOD-executable exists
IF NOT EXIST "%IMODEXE%" (
  ECHO iMOD-executable not found: %IMODEXE% 
  ECHO iMOD-executable not found: %IMODEXE% >> %LOGFILE%
  GOTO error
)

IF "%SIM_TYPE%"=="3" (
  ECHO SIM_TYPE 3 is not allowed in this batchfile. Use MF6-version.
  GOTO error
)

REM Check that iMODFLOW-executable exists
IF NOT EXIST "%IMODFLOWEXE%" (
  ECHO (i^)MODFLOW-executable not found: %IMODFLOWEXE% 
  ECHO (i^)MODFLOW-executable not found: %IMODFLOWEXE% >> %LOGFILE%
  GOTO error
)

IF NOT DEFINED PRJPATH SET PRJPATH=.

REM Check that PRJ-file exists if defined, otherwise retrieve last PRJ-file in specified path
IF DEFINED PRJFILE (
  IF NOT EXIST "%PRJPATH%\%PRJFILE%" ( 
    ECHO PRJ-file does not exist: %PRJPATH%\%PRJFILE%
    ECHO PRJ-file does not exist: %PRJPATH%\%PRJFILE% >> %LOGFILE%
    GOTO error
  )
) ELSE (
  REM If PRJFILE is not defined, select last PRJ-file in current directory
  IF NOT DEFINED PRJFILE (
    FOR %%D IN ("%PRJPATH%\*.PRJ") DO (
      SET PRJFILE=%%~nxD
    )
  )
)

TITLE SIF-basis: Processing PRJ-file '%PRJFILE%' ...

REM Set RESULTPATH if not defined
IF NOT DEFINED RESULTPATH (
  SET MODELNAME=!PRJFILE:%RUNFILEPREFIX%_=!
  SET MODELNAME=!MODELNAME:.PRJ=!
  SET RESULTPATH=%RESULTSPATH%\!MODELNAME:_=\!
)

SET NAMPATH=%RESULTPATH%
SET NAMFILE=!PRJFILE:.PRJ=.NAM!
SET HEADPATH=%RESULTPATH%\HEAD
SET HEADFILTER=HEAD*.IDF

IF "%ISPRJCONVERTED%"=="1" (
  IF EXIST "%RESULTPATH%\*" (
    IF "%ASKCONTINUERUN%"=="1" (
      ECHO:
      ECHO Data is already present in RESULTPATH: !RESULTPATH:%ROOTPATH%\=!
      ECHO Data is already present in RESULTPATH: !RESULTPATH:%ROOTPATH%\=! >> %LOGFILE%
      SET MSG=Do you want to continue (y/n^)^?
      ECHO !MSG! >CON
      SET /P ISCONTINUED=!MSG! >> %LOGFILE%
      IF /I NOT "!ISCONTINUED!"=="y" (
        ECHO !ISCONTINUED! >> %LOGFILE%
        ECHO Script is aborted
        ECHO Script is aborted >> %LOGFILE%
        GOTO exit
      )
    )
   
    REM If specified, remove current files in output path to recycle bin 
    IF "%ISCLEANRESULT%"=="1" (
      IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
        ECHO   Removing existing output from '!RESULTPATH:%ROOTPATH%\=!' ...
        ECHO "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE%
        "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE% 2>&1
        IF ERRORLEVEL 1 GOTO error
        IF EXIST "%RESULTPATH%\*" GOTO error
      ) ELSE (
        ECHO Del2Bin.exe not found, option ISCLEANRESULT cannot be used: %TOOLSPATH%\Del2Bin.exe
        ECHO Del2Bin.exe not found, option ISCLEANRESULT cannot be used: %TOOLSPATH%\Del2Bin.exe >> %LOGFILE%
        GOTO error
      )
    )
  )
  
  REM Create resultpath if not existing
  IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%" 

  REM Create shortcut to result path
  IF EXIST "%TOOLSPATH%\CreateLink.vbs" (
    ECHO   creating shortcut to result path ...
    SET NAME=%PRJFILE:.PRJ=.lnk%.lnk
    ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "!NAME!" "%RESULTPATH%" >> %LOGFILE%
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "!NAME!" "%RESULTPATH%" >NUL
  )
  
  IF EXIST "%RESULTPATH%\%NAMFILE%" (
    ECHO DEL "%RESULTPATH%\%NAMFILE%" >> %LOGFILE%
    DEL "%RESULTPATH%\%NAMFILE%" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  )

  REM *******************************
  REM Start conversion to NAM-file  *
  REM *******************************
  ECHO   start conversion to NAM-file for '%PRJFILE%' ...
  ECHO FUNCTION=RUNFILE > %INIFILE%
  ECHO PRJFILE_IN="%PRJPATH%\%PRJFILE%" >> %INIFILE%
  ECHO NAMFILE_OUT="%RESULTPATH%\%NAMFILE%" >> %INIFILE%
  ECHO SIM_TYPE=!SIM_TYPE! >> %INIFILE%
  IF DEFINED EXTENT ECHO WINDOW=%EXTENT% >> %INIFILE%
  ECHO CELLSIZE=%CELLSIZE% >> %INIFILE%
  ECHO BUFFER=0 >> %INIFILE%
  ECHO ISS=%ISS% >> %INIFILE%
  IF "%ISS%"=="1" (
    IF DEFINED ITT ECHO ITT=%ITT% >> %INIFILE%
    IF DEFINED IDT ECHO IDT=%IDT% >> %INIFILE%
    IF DEFINED ISTEADY ECHO ISTEADY=%ISTEADY% >> %INIFILE%
    IF DEFINED DWEL ECHO DWEL=%DWEL% >> %INIFILE%
    IF DEFINED SDATE ECHO SDATE=%SDATE% >> %INIFILE%
    IF DEFINED EDATE ECHO EDATE=%EDATE% >> %INIFILE%
    IF DEFINED TIMFNAME ECHO TIMFNAME=%TIMFNAME% >> %INIFILE%
  )
  IF DEFINED ICONSISTENCY ECHO ICONSISTENCY=%ICONSISTENCY% >> %INIFILE%
  IF DEFINED MINTHICKNESS ECHO MINTHICKNESS=%MINTHICKNESS% >> %INIFILE%
  IF DEFINED MINKD ECHO MINKD=%MINKD% >> %INIFILE%
  IF DEFINED MINC ECHO MINC=%MINC% >> %INIFILE%
  IF DEFINED ICHKCHD ECHO ICHKCHD=%ICHKCHD% >> %INIFILE%
  IF DEFINED ICONCHK ECHO ICONCHK=%ICONCHK% >> %INIFILE%
  IF DEFINED IDEFLAYER ECHO IDEFLAYER=%IDEFLAYER% >> %INIFILE%
  IF DEFINED DISTRCOND ECHO DISTRCOND=%DISTRCOND% >> %INIFILE%
  IF DEFINED NSTEP ECHO NSPEP=%NSTEP% >> %INIFILE%
  IF DEFINED SSYSTEM ECHO SSYSTEM=%SSYSTEM% >> %INIFILE%
  IF DEFINED SAVESHD ECHO SAVESHD=%SAVESHD% >> %INIFILE%
  IF DEFINED SAVEFLX ECHO SAVEFLX=%SAVEFLX% >> %INIFILE%
  IF DEFINED SAVEWEL ECHO SAVEWEL=%SAVEWEL% >> %INIFILE%
  IF DEFINED SAVEDRN ECHO SAVEDRN=%SAVEDRN% >> %INIFILE%
  IF DEFINED SAVERIV ECHO SAVERIV=%SAVERIV% >> %INIFILE%
  IF DEFINED SAVEGHB ECHO SAVEGHB=%SAVEGHB% >> %INIFILE%
  IF DEFINED SAVERCH ECHO SAVERCH=%SAVERCH% >> %INIFILE%
  IF DEFINED SAVEWEL ECHO SAVEWEL=%SAVEWEL% >> %INIFILE%
  ECHO MODFLOW="%IMODFLOWEXE%" >> %INIFILE%

  IF "%ISS%"=="1" (
    REM Workaround for bug in iMOD that forces ISOLVE=1 for transient modelruns to run succesfully
    ECHO ISOLVE=1 >> %INIFILE%
  ) ELSE (
    ECHO ISOLVE=0 >> %INIFILE%
  )

  REM Start iMOD
  ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
  IF EXIST "%TOOLSPATH%\Tee.exe" (
    "%IMODEXE%" %INIFILE% 2>&1| "%TOOLSPATH%\Tee.exe" /a %LOGFILE%
  ) ELSE (
    "%IMODEXE%" %INIFILE%
  )

  IF NOT EXIST "%NAMPATH%\%NAMFILE%" (
    ECHO Conversion result not found: %RESULTPATH%\%NAMFILE%
    ECHO Conversion result not found: %RESULTPATH%\%NAMFILE% >> %LOGFILE%
    GOTO error
  )
) ELSE (
  ECHO   PRJ2NAM-conversion is skipped
  ECHO   PRJ2NAM-conversion is skipped >> %LOGFILE%
)

IF NOT "%ISS%"=="1" (
  IF "%ISNAMFILERUN%"=="1" (
    IF NOT EXIST "%NAMPATH%\%NAMFILE%" (
      ECHO Main NAM-file not found: %NAMPATH%\%NAMFILE%
      ECHO Main NAM-file not found: %NAMPATH%\%NAMFILE% >> %LOGFILE%
      GOTO error
    )

    IF EXIST "%HEADPATH%\%HEADFILTER%" (
      IF "%ASKCONTINUERUN%"=="1" (
        ECHO:
        ECHO Heads are already present in MF6-resultpath: !HEADPATH:%ROOTPATH%\=!
        ECHO Heads are already present in MF6-resultpath: !HEADPATH:%ROOTPATH%\=! >> %LOGFILE%
        SET MSG=Do you want to continue (y/n^)^?
        ECHO !MSG! >CON
        SET /P ISCONTINUED=!MSG! >> %LOGFILE%
        IF /I NOT "!ISCONTINUED!"=="y" (
          ECHO !ISCONTINUED! >> %LOGFILE%
          ECHO Script is aborted
          ECHO Script is aborted >> %LOGFILE%
          GOTO exit
        )
      )
    )

    REM Start modelrun
    ECHO   start running !PRJFILE:.PRJ=.NAM! ...
    CD /D "%NAMPATH%"
    ECHO "%IMODFLOWEXE%" "%NAMFILE%" >> %LOGFILE%
    IF EXIST "%TOOLSPATH%\Tee.exe" (
      "%IMODFLOWEXE%" "%NAMFILE%" | "%TOOLSPATH%\Tee.exe" /a %LOGFILE%
    ) ELSE (
      "%IMODFLOWEXE%" "%NAMFILE%"
    )
    CD /D "%THISPATH%"
  
    REM Check that results were created
    IF NOT EXIST "%HEADPATH%\%HEADFILTER%" (
      ECHO No modelresults found: %RESULTPATH%\%HEADFILTER%
      ECHO No modelresults found: %RESULTPATH%\%HEADFILTER% >> %LOGFILE%
      GOTO error
    )
  ) ELSE (
    ECHO.
    ECHO   NAM-modelrun is skipped
    ECHO   NAM-modelrun is skipped >> %LOGFILE%
  )
)

IF EXIST IMOD_TMP RMDIR IMOD_TMP >NUL

:success
ECHO:
ECHO: >> %LOGFILE%
SET MSG=Script finished, see %SCRIPTNAME%.log
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
IF NOT DEFINED NOPAUSE PAUSE
