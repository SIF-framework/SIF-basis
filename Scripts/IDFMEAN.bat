@ECHO OFF
REM **********************************************
REM * SIF-basis v2.1.0 (Sweco)                   *
REM *                                            *
REM * IDFMEAN.bat                                *
REM * DESCRIPTION                                *
REM *   Calculates mean from transient IDF-files *
REM *   with iMOD-batchfunction IDFMEAN.         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)       *
REM * VERSION: 2.1.0                             *
REM * MODIFICATIONS                              *
REM *   2020-03-30 Initial version               *
REM **********************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM The IDFMEAN iMOD-batchfunction can be used to compute a new IDF-file with the mean value (or minimum, maximum, sum) of different IDF-files. 
REM It is not necessary to have exactly similar IDF-files

REM ********************
REM * Script variables *
REM ********************
REM IDFPATH:     Path to IDF-files
REM IDFFILTER:   Specify filter for IDF-files to scale, e.g. HEAD*.IDF; do not include year, month, day or layer before or after the wildcard *. This option is activated whenever ILAYER is speci?ed.
REM CFUNC:       Name of function to apply, MEAN: mean values (equal weighed); MIN: minimum values; MAX: maximum values; SUM: sum of values per grid cell; PERC: percentile value (see PERCVALUE). Default is MEAN.
REM PERCVALUE:   Percentile value, when CFUNC=PERC, e.g. PERCVALUE=50.0 for median values.
REM ILAYER:      One of more (comma separated) layers to be used in the calculation, or leave empty to process all files as specified by IDFFILTER.
REM SDATE:       Start date (yyyymmdd) for which IDF-files are used (optional), e.g. SDATE=19980201. This keyword is obligate whenever ILAYER is specified.
REM EDATE:       End date (yyyymmdd) for which IDF-files are used (optional), e.g. SDATE=19980201. This keyword is obligate whenever ILAYER is specified.
REM IYEAR:       One or more (comma seperated) years (within SDATE and EDATE) to be used exclusively (optional), e.g. 2001,2003,2005
REM PERIODS:     One or more (comma seperated) periods (ddmm-ddmm), e.g. PERIOD1=1503-3110 to express the period 15th of March until the 31th of October.
REM ISEL:        Code for the area to be processed: ISEL=1 will compute the entire region; ISEL=2 will compute within given polygons; ISEL=3 will compute for those cells in the given IDF-file that are not equal to the NoDataValue of that IDF-file.
REM GENFNAME:    Path with GEN-filename for polygon(s) for which mean values need to be computed. This keyword is obliged whenever ISEL=2.
REM IDFNAME:     Path with IDF-filename for which mean values will be computed for those cells in the IDF-file that are not equal to the NoDataValue of that IDF-file. This keyword is compulsory whenever ISEL=3
REM ISDELRESULT: Specify (with value 1) that all old results should be deleted (to recycle bin) from RESULTPATH 
REM RESULTPATH:  Name of subdirectory where the scriptresults are stored; note a subdir [SDATE-year]-[EDATE-year] is always added automatically
REM RESULTFILE:  Name of result IDF-file, or leave empty to use iMOD-default ([IDFFILTER]_[CFUNC]_[SDATE]_TO_[EDATE].IDF
SET IDFPATH=%RESULTSPATH%\BASIS1\head
SET IDFFILTER=HEAD*.IDF
SET CFUNC=MEAN
SET PERCVALUE=50
SET ILAYER=1
SET SDATE=19980101
SET EDATE=20051231
SET IYEAR=
SET PERIODS=0104-3009
SET ISEL=1
SET GENFNAME= 
SET IDFNAME=
SET ISDELRESULT=0
SET RESULTPATH=result
SET RESULTFILE=

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET INIFILE="%SCRIPTNAME%.INI"
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SETLOCAL EnableDelayedExpansion

REM Check that the specified paths exist
IF NOT EXIST "%IDFPATH%" (
  SET MSG=The specified IDFPATH does not exist: %IDFPATH%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF NOT EXIST "%IMODEXE%" (
  SET MSG=The specified IMODEXE does not exist: %IMODEXE%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF "%SDATE"=="" (
  SET MSG=SDATE cannot be empty
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF "%EDATE"=="" (
  SET MSG=EDATE cannot be empty
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF "%ISDELRESULT%"=="1" (
  IF EXIST "%RESULTPATH%\*" (
    IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
      ECHO "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE%
      "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO Del2Bin.exe not found, deleting permanently ... >> %LOGFILE%
      ECHO DEL /Q "%RESULTPATH%\*" >> %LOGFILE%
      DEL /Q "%RESULTPATH%\*" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  ) 
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
SET MSG=IDFPATH: %IDFPATH%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
IF DEFINED RESULTFILE (
  CD /D "%RESULTPATH%"
  SET RESULTPATH=!CD!
  CD /D "%THISPATH%"
)
ECHO RESULTPATH: %RESULTPATH%

ECHO:

IF /I "%CFUNC%"=="PERC" (
  SET MSG=Calculating %CFUNC%%PERCVALUE% for %SDATE% to %EDATE% ...
) ELSE (
  SET MSG=Calculating %CFUNC% for %SDATE% to %EDATE% ...
)
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Create INI-file
ECHO FUNCTION=IDFMEAN > %INIFILE%
ECHO CFUNC=%CFUNC% >> %INIFILE%
ECHO NDIR=1 >> %INIFILE%
ECHO SOURCEDIR1=%IDFPATH%\%IDFFILTER% >> %INIFILE%
IF "%CFUNC%"=="PERC" (
  ECHO PERCVALUE=%PERCVALUE% >> %INIFILE%
)
IF NOT "%SDATE%"=="" (
  ECHO SDATE=%SDATE% >> %INIFILE%
)
IF NOT "%EDATE%"=="" (
  ECHO EDATE=%EDATE% >> %INIFILE%
)
IF NOT "%ILAYER%"=="" (
  ECHO ILAYER=%ILAYER% >> %INIFILE%
)
IF NOT "%IYEAR%"=="" (
  ECHO IYEAR=%IYEAR% >> %INIFILE%
)

REM Retrieve start- and end year for result subdirectory name
SET SYEAR=%SDATE:~0,4%
SET EYEAR=%EDATE:~0,4%
SET YEARSUBDIR=!SYEAR!-!EYEAR!

IF NOT EXIST "%RESULTPATH%\!YEARSUBDIR!" MKDIR "%RESULTPATH%\!YEARSUBDIR!" >> %LOGFILE%

REM Write periods if defined
IF NOT "%PERIODS%"=="" (
  SET NPERIOD=0
  FOR %%A in (%PERIODS%) DO (
    SET /A NPERIOD=NPERIOD+1
  )
  ECHO NPERIOD=!NPERIOD! >> %INIFILE%
  SET NPERIOD=0
  FOR %%A IN (%PERIODS%) DO (
    SET /A NPERIOD=NPERIOD+1
    ECHO PERIOD!NPERIOD!=%%A >> %INIFILE%
  )
)

IF NOT "%ISEL%"=="" (
  ECHO ISEL=%ISEL% >> %INIFILE%
  IF "%ISEL%"=="2" (
    ECHO GENFNAME=%GENFNAME% >> %INIFILE%
  )
  IF "%ISEL%"=="3" (
    ECHO IDFNAME=%IDFNAME% >> %INIFILE%
  )
)
IF DEFINED RESULTFILE ECHO OUTFILE=%RESULTPATH%\%YEARSUBDIR%\%RESULTFILE% >> %INIFILE%

REM Start iMOD
ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%

REM If no RESULTFILE was specified, iMOD leaves result in input path; copy results to result path
IF NOT DEFINED RESULTFILE (  
  SET MSG=Copying results to '%RESULTPATH%\!YEARSUBDIR!' ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  SET YEARFILTER=!SYEAR!*!EYEAR!
  SET RESULTFILTER=!IDFFILTER:.IDF=!%CFUNC%*!YEARFILTER!*.IDF

  IF EXIST "%IDFPATH%\%CFUNC%\!RESULTFILTER!" (
    ECHO COPY "%IDFPATH%\%CFUNC%\%RESULTFILTER%" "%RESULTPATH%\!YEARSUBDIR!" >> %LOGFILE%
    COPY "%IDFPATH%\%CFUNC%\%RESULTFILTER%" "%RESULTPATH%\!YEARSUBDIR!" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
    IF NOT EXIST "%RESULTPATH%\!YEARSUBDIR!\!RESULTFILTER!" GOTO error
  ) ELSE (
    SET MSG=No results found: "%IDFPATH%\!RESULTFILTER!"
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
) ELSE (
  SET RESULTFILTER=%RESULTFILE:.IDF=%*.IDF
)

SET MSG=Listing result files in '%RESULTPATH%\!YEARSUBDIR!\!RESULTFILTER!' ...
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
FOR %%D IN ("%RESULTPATH%\!YEARSUBDIR!\!RESULTFILTER!") DO (
  ECHO   %%~nxD
  ECHO   %%~nxD >> %LOGFILE%
)
IF ERRORLEVEL 1 GOTO error

REM IF EXIST %INIFILE% DEL %INIFILE%

REM Add metadata
ECHO Adding metadata ...
ECHO Adding metadata ... >> %LOGFILE%
FOR %%G IN ("%RESULTPATH%\!YEARSUBDIR!\!RESULTFILTER!") DO (
  ECHO   "iMODmetadata.exe" /o "%RESULTPATH%\!YEARSUBDIR!\%%~nG.MET" "" "" 1 "%MODELREF0%" "%CFUNC% layer(s) %ILAYER%, %SDATE%-%EDATE%/%PERIODS%" "%CONTACTORG%" IDF "" "" ="%IDFPATH%\!IDFFILTER!" "See !THISPATH:%ROOTPATH%\=!%~nx0; iMOD-batchfunction IDFMEAN(CFUNC=%CFUNC%, ILAYER=%ILAYER%, %SDATE%-%EDATE%/%PERIODS%); iMOD: !iMODEXE:%ROOTPATH%\=!" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata.exe" /o "%RESULTPATH%\!YEARSUBDIR!\%%~nG.MET" "" "" 1 "%MODELREF0%" "%CFUNC% layer(s) %ILAYER%, %SDATE%-%EDATE%/%PERIODS%" "%CONTACTORG%" IDF "" "" ="%IDFPATH%\!IDFFILTER!" "See !THISPATH:%ROOTPATH%\=!%~nx0; iMOD-batchfunction IDFMEAN(CFUNC=%CFUNC%, ILAYER=%ILAYER%, %SDATE%-%EDATE%/%PERIODS%); iMOD: !iMODEXE:%ROOTPATH%\=!" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)
ECHO: 

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
