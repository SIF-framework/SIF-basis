@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * ISGGRID.bat                            *
REM * DESCRIPTION                            *
REM *   Converts ISG-file to IDF-files with  *
REM *   iMOD-batchfunction ISGGRID.          *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2017-05-16 Initial version           *
REM ******************************************
CALL :Initialization
CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM ISGFILES: Path to ISG-file
REM CELLSIZE: Cellsize of resulting IDF-files
REM IAVERAGE: Specify statistic to use for time dependent data: 1 for average, 2 for median
REM POSTFIX:  Postfix after generated IDF-file (note: ISGGRID doesn't added any extra characters itsef)
REM NODATA:   NoData-value to use. Note: check NoData-value of resulting conductance and inffactor files, which may be 0, depending on iMOD-version
REM WINDOW:   Extent (commaseperated xll, yll, xur, yur) or leave empty to use entire ISG. 
REM MINDEPTH: Specify minimum width for determination of conductance (check iMOD-manual for details)
REM MAXWIDTH: Maximal width of a stream (meter) used for the calculation of the conductance of the stream bed (or leave empty for default)
REM ISAVE:    Specify the output IDF-files to generate (see iMOD manual, 12 entries). Use 1,1,1,1,0,0,0,0,0,0,0,0 for bottom, stage, conductance and infiltration factor.
REM IPERIOD:  Period to calculate statistics for (1 to average over the entire ISG period, 2 for a specific period, or leave empty for default (1))
REM S/EDATE:  Specify in case of IPERIOD=2: period by a start- and enddate (yyyymmdd), and a date-difference (to be used to compute more rasters for different periods, see iMOD-manual)
REM DDATE:    Date-difference to be used to compute more rasters for different periods, e.g. DDATE=14 means that a sequence between SDATE and EDATE will be computed with length of 14 days. 
REM             By default DDATE=0 which will ignore any time steps in-between the SDATE and EDATE variables. The names of the IDF-file will be extended to include a date notification, e.g. STAGE{POSTFIX}_19910101.IDF
REM RESULTPATH: Path to write results
SET ISGFILES=input\TEST.ISG
SET CELLSIZE=5
SET IAVERAGE=2
SET POSTFIX=_WTR5
SET NODATA=-9999
SET WINDOW=%BUFFEREXTENT%
SET MINDEPTH=
SET MAXWIDTH=
SET ISAVE=1,1,1,1,0,0,0,0,0,0,0,0
SET IPERIOD=2
SET SDATE=20210305
SET EDATE=20210305
SET DDATE=0
SET RESULTPATH=result\winter\IDF5

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET INIFILENAME="%THISPATH%%SCRIPTNAME%.INI"
REM Specify alternative path to iMOD executable
REM SET IMODEXE=%EXEPATH%\iMOD\iMOD_V4_4_X64R.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO !MSG!
ECHO !MSG! > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF EXIST "%RESULTPATH%\*%POSTFIX%*" DEL /F "%RESULTPATH%\*%POSTFIX%*" 

REM Start writing RUNFILE batchfunction INI-file parameters and values
SETLOCAL EnableDelayedExpansion
FOR %%G IN (%ISGFILES%) DO (
  SET ISGFILE=%%G
  IF NOT EXIST !ISGFILE! ( 
    ECHO ISG-file does not exist: !ISGFILE!
    ECHO ISG-file does not exist: !ISGFILE! > %LOGFILE%
    GOTO error
  )

  SET MSG=Creating INI-file for %%~nxG...
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%

  ECHO FUNCTION=ISGGRID > %INIFILENAME%
  ECHO ISGFILE_IN="!ISGFILE!" >> %INIFILENAME%
  ECHO CELL_SIZE=%CELLSIZE% >> %INIFILENAME%
  ECHO IAVERAGE=%IAVERAGE% >> %INIFILENAME%
  ECHO OUTPUTFOLDER="%RESULTPATH%" >> %INIFILENAME%
  ECHO POSTFIX=%POSTFIX% >> %INIFILENAME%
  ECHO NODATA=%NODATA% >> %INIFILENAME%
  ECHO ICDIST=0 >> %INIFILENAME%
  IF NOT "%WINDOW%"=="" (
    ECHO WINDOW=%WINDOW% >> %INIFILENAME%   
  )
  IF NOT "%MINDEPTH%"=="" (
    ECHO MINDEPTH=%MINDEPTH% >> %INIFILENAME%
  )
  IF NOT "%MAXWIDTH%"=="" (
    ECHO MAXWIDTH=%MAXWIDTH% >> %INIFILENAME%
  )
  IF NOT "%ISAVE%"=="" (
    ECHO ISAVE=%ISAVE% >> %INIFILENAME%  
  ) ELSE (
    ECHO ISAVE=1,1,1,1,1,1,1,1,1,1,1,1 >> %INIFILENAME%  
  )
  IF NOT "%IPERIOD%"=="" (
    ECHO IPERIOD=%IPERIOD% >> %INIFILENAME%  
    IF NOT "%SDATE%"=="" (
      ECHO SDATE=%SDATE% >> %INIFILENAME%  
    )
    IF NOT "%EDATE%"=="" (
      ECHO EDATE=%EDATE% >> %INIFILENAME%  
    )
    IF NOT "%DDATE%"=="" (
      ECHO DDATE=%DDATE% >> %INIFILENAME%  
    )
  )
  
  REM Start iMOD-batchfunction ISGGRID
  SET MSG=Starting ISG-to-IDF conversion for %%~nxG ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO "%IMODEXE%" %INIFILENAME% >> %LOGFILE%
  "%IMODEXE%" %INIFILENAME% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
  IF NOT EXIST "%RESULTPATH%\*.IDF" (
    SET MSG=iMOD did not complete succesfully, IDF-files not found
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )

  ECHO:
)
IF EXIST %INIFILENAME% DEL %INIFILENAME%


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
