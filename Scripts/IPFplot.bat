@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IPFplot.bat                            *
REM * DESCRIPTION                            *
REM *   Creates PNG-files for IPF-timeseries *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2019-03-06 Initial version           *
REM ******************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM Script allows one or two lines to be plotted in the same plot for one or more combinations of IPF-files. There are basically two options:
REM - seperate IPF-files per modellayer: always define the layernumber postfix with IPFPOSTFIX1 and IPFPOSTFIX2
REM - no distinction for modellayers: IPFPOSTFIX1 and IPFPOSTFIX2 can be left empty
REM When two valuelists from one TXT-file should be shwon in the samen plot, add the same IPF-file(s) and prefix for IPFPATH1/IPFPATH2 and IPFPREFIXES1/IPFPREFIXES2; then add column indices of values lists via TS_COLINDICES.

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH1:        Path for set1 of input IFF-file(s)
REM IPFPATH2:        Path for set2 of input IFF-file(s), or leave empty to skip
REM IPFPREFIXES1:    Comma seperated list of prefixes for set1, i.e. part before IPFPOSTFIX1 of IPF-files to process and retrieve timeseries for, e.g. 'meetreeksen'
REM IPFPREFIXES2:    Comma seperated list of prefixes for set2, i.e. part before IPFPOSTFIX2 of IPF-files to process and retrieve timeseries for, e.g. 'meetreeksen'
REM IPFPOSTFIX1:     Postfix for set1. If MODELLAYERS is defined, this is the substring before the layernumber (e.g. _L). Otherwise all files from set1 are processed that match name '%IPFPREFIXES1%%IPFPOSTFIX1%*.IPF'
REM IPFPOSTFIX2:     Postfix for set2. If MODELLAYERS is defined, this is the substring before the layernumber (e.g. _L). Otherwise this can be any postfix, including wildcards, for which the first match is used.
REM MODELLAYERS:     Comma seperated list of modellayer numbers to process, or leave empty to process all input files that match name '%IPFPREFIXES1%%IPFPOSTFIX1%*.IPF' and select corresponding file(s) from set2 (with '%IPFPREFIX1%%IPFPOSTFIX1%' replaced by '%IPFPREFIX2%%IPFPOSTFIX2%'.
REM IDCOLSTRINGS:    comma-seperated list of ID-strings that define an ID. The first ID is used for plot title and filename. ID's of points in other IPF-files are used to match with points in the first IPF-file.
REM                  ID-strings can be build up as follows: 1) if ID-string is a single integer i, the row value in (zero-based) column i is used; 2) '{i}'-substrings with i an integer are replaced with the row value in (zero-based) column i; 3) other non-value characters are simply copied
REM                  Note: if no ID-strings are specified, points are matched by index if pointcount is equal (files are assumed to sorted), or by XY-coordinates in combination with equality of all other column values.
REM SERIESNAMES:     Comma seperated list of (max two) names for series specified by added IPF-files, or leave empty to use a sequence number
REM COLORS:          Colors for line and markers by a semicolon seperated list of (max two) comma seperated RGB-colors for specified series or, if one series, for series and average line. E.g. /c:200,0,0;0,200,0;0,0,200
REM ISSKIPEMPTYPLOT: Specify (with value 1) to skip plots that have IPF-points missing or only NoData-values
REM TS_COLINDICES:   Comma seperated list of (zero-based) column indices of timeseries (value list) to plot in corresponding plotseries
REM RESULTPATH:      Path or name of subdirectory where the scriptresults are stored
REM ISCLEANRESULT:   Specify (with value 1) if RESULTPATH folder should be emptied before 
SET IPFPATH1=result\ts-IDF
SET IPFPATH2=result\ts-IDF
SET IPFPREFIXES1=%VALSET_STATRESULTFILE%
SET IPFPREFIXES2=%VALSET_STATRESULTFILE%
SET IPFPOSTFIX1=_L
SET IPFPOSTFIX2=_L
SET MODELLAYERS=1,4
SET IDCOLSTRINGS=2
SET SERIESNAMES=meting,simulatie
SET COLORS=93,157,201;255,127,14
SET ISSKIPEMPTYPLOT=1
SET TS_COLINDICES=0,1
SET RESULTPATH=result\plots
SET ISCLEANRESULT=1

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET THISPATH=%~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-plus: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%IPFPATH1%" (
  SET MSG=IPFPATH1 is niet gevonden: %IPFPATH1%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF DEFINED IPFPATH2 (
  IF NOT EXIST "%IPFPATH2%" (
    SET MSG=IPFPATH2 is niet gevonden: %IPFPATH2%
    ECHO !MSG!
    ECHO !MSG! > %LOGFILE%
    GOTO error
  )
)

REM Create arrays for package input
SET Nr1=0
FOR %%a in (%IPFPREFIXES1%) do (
  SET IPFPREFIXES1_ARR[!Nr1!]=%%a
  SET /A Nr1=Nr1+1
)
SET Nr2=0
FOR %%a in (%IPFPREFIXES2%) do (
  SET IPFPREFIXES2_ARR[!Nr2!]=%%a
  SET /A Nr2=Nr2+1
)
IF DEFINED IPFPREFIXES2 (
  IF NOT %Nr1%==%Nr2% (
    SET MSG=Number of IPFPREFIXES1 is not equal to number of IPFPREFIXES2
    ECHO !MSG!
    ECHO !MSG! > %LOGFILE%
    GOTO error
  )
)
SET /A Nr1=Nr1-1

REM Create empty result directory
IF "%ISCLEANRESULT%"=="1" (
  IF EXIST "%RESULTPATH%\*" (
    IF "%RESULTPATH:0,1%"=="\" (
      SET MSG=Invalid RESULTPATH: %RESULTPATH%
      ECHO !MSG!
      ECHO !MSG! > %LOGFILE%
      GOTO error
    )
    RMDIR /S /Q "%RESULTPATH%"
  )
)

IF NOT EXIST %RESULTPATH% MKDIR %RESULTPATH%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET IDOPTION=
SET NAMESOPTION=
SET COLOROPTION=
SET TSCOLIDXOPTION=
SET SKIPNODATAOPTION=
IF DEFINED IDCOLSTRINGS SET IDOPTION=/i:%IDCOLSTRINGS%
IF DEFINED SERIESNAMES SET NAMESOPTION=/n:%SERIESNAMES%
IF DEFINED COLORS SET COLOROPTION=/c:%COLORS%
IF DEFINED TS_COLINDICES SET TSCOLIDXOPTION=/v:%TS_COLINDICES%
IF "%ISSKIPEMPTYPLOT%"=="1" SET SKIPNODATAOPTION=/x
FOR /L %%i IN (0,1,%Nr1%) DO (
  SET IPFPREFIX1=!IPFPREFIXES1_ARR[%%i]!
  SET IPFPREFIX2=!IPFPREFIXES2_ARR[%%i]!
  
  ECHO   processing !IPFPREFIX1! ...
  IF DEFINED MODELLAYERS (
    FOR %%l IN (!MODELLAYERS!) DO (
      SET IPFFILENAME1=%IPFPATH1%\!IPFPREFIX1!%IPFPOSTFIX1%%%l.IPF
      IF NOT EXIST "!IPFFILENAME1!" (
        ECHO     File not found and skipped: !IPFFILENAME1!
        ECHO     File not found and skipped: !IPFFILENAME1! >> %LOGFILE%
        REM GOTO error
      ) ELSE (
        ECHO     processing IPF-file !IPFPREFIX1!%IPFPOSTFIX1%%%l.IPF ...
  	IF NOT EXIST "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" MKDIR "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" 
        IF DEFINED IPFPATH2 (
          SET IPFFILENAME2=%IPFPATH2%\!IPFPREFIX2!%IPFPOSTFIX2%%%l.IPF
          IF NOT EXIST "!IPFFILENAME2!" (
            ECHO     File not found and skipped: !IPFFILENAME2!
            ECHO     File not found and skipped: !IPFFILENAME2! >> %LOGFILE%
            REM GOTO error
          ) ELSE (
            ECHO "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!","!IPFFILENAME2!" "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" >> %LOGFILE%
            "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!","!IPFFILENAME2!" "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" >> %LOGFILE%
            IF ERRORLEVEL 1 GOTO error
          )
        ) ELSE (
          ECHO "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!" "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" >> %LOGFILE%
          "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!" "%RESULTPATH%\!IPFPREFIX1!%IPFPOSTFIX1%%%l" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
      )
    )
  ) ELSE (
    FOR %%D IN ("%IPFPATH1%\!IPFPREFIX1!!IPFPOSTFIX1!*.IPF") DO (
      SET NAME1=%%~nD
      SET IPFFILENAME1=%%D
      ECHO     processing IPF-file !NAME1!.IPF ...
      IF NOT EXIST "%RESULTPATH%\!NAME1!" MKDIR "%RESULTPATH%\!NAME1!" 
      IF DEFINED IPFPATH2 (
        REM Replace pre and postfix1 with pre and postfix2. Use FOR-loops to perform replacement within delayed expansion variable with delayed expansion variables
        SET SEARCH=!IPFPREFIX1!%IPFPOSTFIX1%
        SET REPLACEVAL=!IPFPREFIX2!%IPFPOSTFIX2%
        FOR /F "delims=" %%S in (^""!SEARCH!"^") DO (
          FOR /F "delims=" %%R in (^""!REPLACEVAL!"^") DO (
              SET IPFFILENAME2=%IPFPATH2%\!NAME1:%%~S=%%~R!.IPF
          )
        )

        IF NOT EXIST "!IPFFILENAME2!" (
          ECHO     File not found and skipped: !IPFFILENAME2!
          ECHO     File not found and skipped: !IPFFILENAME2! >> %LOGFILE%
          REM GOTO error
        ) ELSE (
          ECHO "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!","!IPFFILENAME2!" "%RESULTPATH%\!NAME1!" >> %LOGFILE%
          "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!","!IPFFILENAME2!" "%RESULTPATH%\!NAME1!" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
      ) ELSE (
        ECHO "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!" "%RESULTPATH%\!NAME1!" >> %LOGFILE%
        "%TOOLSPATH%\IPFplot.exe" %IDOPTION% %SKIPNODATAOPTION% %TSCOLIDXOPTION% %NAMESOPTION% %COLOROPTION% "!IPFFILENAME1!" "%RESULTPATH%\!NAME1!" >> %LOGFILE%
        IF ERRORLEVEL 1 GOTO error
      )
    )
  )
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
