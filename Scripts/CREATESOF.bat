@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * CREATESOF.bat                          *
REM * DESCRIPTION                            *
REM *   Runs iMOD-batchfunction CREATESOF    *
REM * VERSION: 2.0.0                         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2021-11-18 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM LEVELIDF:   Surface level (Digital Terrain Model DTM) IDF-file that need to be processed
REM IFLOW:      Method for creating SOF, which can be one of: 
REM               0 -  compute the “spill”-levels, slopes and aspect angles. Check iMOD-manual for IDF-files that will be saved (e.g. _PITT, _SLOPE, _ASPECT)
REM               1 -  compute the entire “flow path” of the particle flowing over the surface. A GEN-file and ZONE IDF-files will be created.
REM PITTSIZE:   Opional minimal size of a pit to become a natural outlet (default 0)
REM OUTLETIDF:  Optional IDF-fle that describes the outlet locations, e.g. OUTLETIDF=D:\MODEL\RIVERS.IDF. Each location not equal to the NodataValue in the given OUTLETIDF will be used to terminate the further search for a “spill”-level.
REM WINDOW:     Optional window for which the entered LEVELIDF will be clipped and resized whenever the entered CELLSIZE is unequal to the cell size of the given IDF-file at LEVELIDF.
REM CELLSIZE:   Cellsize (when WINDOW is defined) for resulting file(s)
REM IGRAD:      Specify (with value 1) to include the aspect computations. The default value is IGRAD=0 whenever this keyword is absent, which will ignore the computation of the aspects of the DTM as these computations can take significant amount of time, especially the flat areas and the elevation on the core volumes.
REM SLOPEIDF:   Slope IDF file (for IFLOW=1) that need to be processed, it is logical to use the slope IDF from a IFLOW=0 run.
REM ASPECTIDF:  Aspect IDF-file (for IFLOW=1) that contains the aspects for each grid cell. Normally, this is the result of the simulation with IFLOW=0 (*_ASPECT.IDF) 
REM SLOPEIDF:   Resulting slope IDF-file (for IFLOW=1)
REM COUNTIDF:   Resulting count IDF-file (for IFLOW=1)
REM RAIN:       Optional size (for IFLOW=2 or IFLOW=3) of the rainfall used to compute counts as volume and in the end it can be used to compute the dimension of the stream
REM DISZONEIPF: Optional IPF-file (for IFLOW=1) that describes the location of discharge measurement station. The minimal requirement of the data in the IPF-file is that the first three columns 
REM               need to describe the x, y and station number (integer). The resulting {SOFIDF}_ZONE.IDF will present the areas that discharge to the given station numbers. 
REM IWRITE:     Specify (with value 1) to write a GEN-file of all “flow paths” of particles flowing over the DTM (for IFLOW=1), or leave 0 or empty to skip. This will yield the file {ASPECTIDF}.GEN. Writing this file will reduce the performance and it often will yield an enormous file.
REM RESULTPATH: Path of resulting SOF IDF-file
REM RESULTFILE: Filename of resulting SOF IDF-file
SET LEVELIDF=tmp\MV_RIVPEIL.IDF
SET IFLOW=0
SET PITTSIZE=
SET OUTLETIDF=
SET WINDOW=
SET CELLSIZE=25
SET IGRAD=
SET SLOPEIDF=
SET ASPECTIDF=
SET SLOPEIDF=
SET COUNTIDF=
SET RAIN=
SET DISZONEIPF=
SET IWRITE=0
SET RESULTPATH=tmp2
SET RESULTFILE=SOF.IDF

REM METADATA_DESCRIPTION:  Description of resulting file
REM METADATA_SOURCE:       Path or description to source file(s)
SET METADATA_DESCRIPTION=Created by iMOD-batchfunction CREATESOF
SET METADATA_SOURCE=LEVELIDF=%LEVELIDF%
IF DEFINED OUTLETIDF SET METADATA_SOURCE=%METADATA_SOURCE%; OUTLETIDF=%OUTLETIDF%

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET THISPATH=%~dp0
SET TEMPDIR=TMP
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%LEVELIDF%" (
   ECHO The specified LEVELIDF-file does not exist: %LEVELIDF%
   ECHO The specified LEVELIDF-file does not exist: %LEVELIDF% > %LOGFILE%
   GOTO error
)
IF DEFINED OUTLETIDF (
  IF NOT EXIST "%OUTLETIDF%" (
     ECHO The specified OUTLETIDF-file does not exist: %OUTLETIDF%
     ECHO The specified OUTLETIDF-file does not exist: %OUTLETIDF% > %LOGFILE%
     GOTO error
  )
)

IF "%IFLOW%"=="1" (
  IF NOT EXIST "%SLOPEIDF%" (
    ECHO SLOPEIDF-file not found: %SLOPEIDF%
    ECHO SLOPEIDF-file not found: %SLOPEIDF% >> %LOGFILE%
  )
)

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Calculating IDF-files
ECHO   calculating %RESULTFILE% ..
ECHO   calculating %RESULTFILE% ... >> %LOGFILE%
ECHO FUNCTION=CREATESOF > %INIFILE%
ECHO IFLOW=%IFLOW% >> %INIFILE%
ECHO LEVELIDF="%LEVELIDF%" >> %INIFILE%
IF DEFINED PITTSIZE ECHO PITTSIZE=%PITTSIZE% >> %INIFILE%
IF DEFINED OUTLETIDF ECHO OUTLETIDF="%OUTLETIDF%" >> %INIFILE%
IF DEFINED WINDOW (
  ECHO WINDOW=%WINDOW: =,% >> %INIFILE%
  ECHO CELLSIZE=%CELLSIZE% >> %INIFILE%
)
IF DEFINED IWRITE ECHO IWRITE=%IWRITE% >> %INIFILE%
IF DEFINED IGRAD ECHO IGRAD=%IGRAD% >> %INIFILE%
IF "%IFLOW%"=="0" (
  ECHO SOFIDF="%RESULTPATH%\%RESULTFILE%" >> %INIFILE%
) ELSE (
  IF "%IFLOW%"=="1" (
    ECHO LEVEL_OUTIDF="%RESULTPATH%\%RESULTFILE%" >> %INIFILE%
    ECHO SLOPE_OUTIDF="%RESULTPATH%\%SLOPEIDF%"
  ) ELSE (
    ECHO IFLOW value not yet supported in this batchfile: %IFLOW%
    ECHO IFLOW value not yet supported in this batchfile: %IFLOW% >> %LOGFILE%
    GOTO error
  )
)
ECHO "%iMODEXE%" %INIFILE% >> %LOGFILE%
"%iMODEXE%" %INIFILE% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error
IF NOT EXIST "%RESULTPATH%\%RESULTFILE%" (
  ECHO Resultfile %RESULTPATH%\%RESULTFILE% has not been created!
  ECHO Resultfile %RESULTPATH%\%RESULTFILE% has not been created! >> %LOGFILE%
  GOTO error
) 
IF ERRORLEVEL 1 GOTO error
IF EXIST %INIFILE% DEL %INIFILE%

IF DEFINED METADATA_DESCRIPTION (
  ECHO metadata maken voor %RESULTFILE% ...
  IF EXIST "!LEVELIDF:.IDF=.MET!" (
    ECHO COPY "!LEVELIDF:.IDF=.MET!" "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" >> %LOGFILE%
    COPY "!LEVELIDF:.IDF=.MET!" "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" >> %LOGFILE%
  )

  SET OVERWRITEMETADATA=/o
  ECHO "%TOOLSPATH%\iMODmetadata.exe" !OVERWRITEMETADATA! "%RESULTPATH%\%RESULTFILE:.IDF=.MET%" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "" "" ="%METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata.exe" !OVERWRITEMETADATA! "%RESULTPATH%\%RESULTFILE:.IDF=.MET%" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "" "" ="%METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

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
IF "%NOPAUSE%"=="" PAUSE
