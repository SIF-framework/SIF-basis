@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * IPFselect.bat                          *
REM * DESCRIPTION                            * 
REM *   Selects points from IPF-file(s)      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.2.4                         *
REM * MODIFICATIONS                          *
REM *   2020-01-17 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM --- Define input IPF-file(s) ---
REM IPFPATH:      Path for input IPF-file(s)
REM IPFFILTER:    Filter for input IPF-file(s)
REM X/Y/ZCOLIDX:  X, Y and Z-column indices (one-based), or leave empty to use default of 1 and 2 (and 3 if level selection is specified)
SET IPFPATH=input
SET IPFFILTER=*.IPF
SET XCOLIDX=
SET YCOLIDX=
SET ZCOLIDX=

REM --- Define optional selection area/volume ---
REM GENFILE:      GEN-file for definition of clip/select-volume, or leave empty
REM TOPLEVEL:     TOP-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
REM BOTLEVEL:     BOT-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
SET GENFILE=
SET TOPLEVEL=
SET BOTLEVEL=

REM --- Define optional column expression for selection and/or for changing selected values with ---
REM EXPCOL:       For logical expression: specify (one-based) column number or name of column to evaluate. Note: columnvalues are checked to determine type. Inconsistencies or a single empty string will result in type 'string'.
REM EXPOP:        For logical expression: specify logical operator: eq, gt, gteq, lt, lteq, uneq. Note: gt, gteq, lt and lteq might behave unexpected for string type comparisons, which is based on (ordinal) alphabetical order.
REM EXPVAL:       For logical expression: specify (string, integer, double, DateTime) value to compare with. EXPVAL can also be a string expression as described for option CHANGE_EXPS. Leave empty for empty string.
REM CHANGE_EXPS:  One or more column/exp-definitions, seperated by commas, for modifying columns of selected rows and copy other rows, or leave empty to copy only selected rows. E.g. 3;*2.5;NaN,TOP;-1
REM               Each column/exp-definition is specified by 'c;e;n', where:
REM                'c' is a (one based) column number or a column name. If a column name is not found it is added, where non-selected points will receive an empty string as a value.
REM                'e' is a constant value, a mathetical expression or a string expression:
REM                    - a mathemetical expression is defined as an operator and value; valid operators are: '*', '/', '+' and '-'. E.g. "/c:3;*2.5,TOP;-1"
REM                      for the value a floating point value or a columnname can be specified. A columnname must be surrounded with curly braces, e.g. '-{TOP}'
REM                      for stringvalues only operators '+' and '-' are valid (to concatenate or remove a substring).
REM                    - a string expression is a combination of (one-based) column numbers/names and/or constant values/strings; 
REM                      column numbers/names must be surrounded by {}-brackets and {<col>}-substrings are replaced with the corresponding column values in that row;
REM                      use[ID](including brackets) for the (one-based) rownumber of the processed row.
REM                    - for string manipulation two forms are allowed:
REM                      {<col>:~idx,len} to select substring at (zero based) index idx with length len (see batchfile-syntax)
REM                      {<col>:A=B} to replace substrings A by B
REM                    Note: string expression results are trimmed after applying expressions.
REM                'n' is an optional NoData-value for new columns and rows that were not selected.
REM USEREGEXP:    Specify 1 to use regular expressions for string values in combination with (un)equal operator, leave empty or 0 otherwise
REM               An example expression is: '^^(7^|8)$' (without surrounding quotes) to select points with value 7 or 8 in the specified column. For some symbols you need escape characters, in this case for '^' and '|'.
REM               Both regular expressions and escape characters in batchfiles are standard techniques. Check online documentation for details.
SET EXPCOL=6
SET EXPOP=uneq
SET EXPVAL=XXX_PP.*
SET CHANGE_EXPS=
SET USEREGEXP=1

REM --- Define optional criteria for selection/reading timeseries of IPF-file(s) ---
REM TS_PERIOD_S/EDATE:   Start-/enddate of period to select IPF-points that have non-NoData values in timeseries within specified period. Use format yyyymmdd[hhmmss]. 
REM TS_PERIOD_CLIP:      Specify if timeseries should be clipped to specified period: use 0 to select points without clipping (default); use 1 to select points and clip; use 2 to just clip, but not remove points without dates in period
REM TS_PERIOD_VALCOLIDX: Index (zero-based) of value column that should be checked for non-NoData values within defined period. 
REM                      When TS_PERIOD_VALCOLIDX is -1 or not defined, all value columns must contain non-NoData values for a point to be selected.
REM TS_SKIP:             Specify (with value 1) to skip reading/writing of IPF-timeseries, or use 0 or leave empty to not skip
REM TS_DELEMPTY:         Specify (with value 1) to delete IPF-points with empty timeseries (without any timestamps/values), or use 0 or leave empty to not delete
SET TS_PERIOD_SDATE=
SET TS_PERIOD_EDATE=
SET TS_PERIOD_VALCOLIDX=
SET TS_PERIOD_CLIP=
SET TS_SKIP=
SET TS_DELEMPTY=

REM --- Define result path and (optional) filename ---
REM RESULTPATH:  Result path or filename output IPF-file (if a single input file was selected). If no filename is specified the source name with postfix _sel is used.
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL ENABLEDELAYEDEXPANSION

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET MSG=selecting points in IPF-file(s^) with filter '%IPFFILTER%' ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%

REM Build option strings
SET GENFILEOPTION=
SET LEVELOPTION=
SET XYZOPTION=
SET METHODOPTION=
SET EXPOPTION=
SET CHANGEOPTION=
SET TSPOPTION=
SET TSSOPTION=
SET TSEOPTION=
SET REGEXPOPTION=
SET MOPTION=
IF NOT "%XCOLIDX%"=="" (
  IF NOT "%YCOLIDX%"=="" (
    SET MSG=XY_COLINDICES=%XCOLIDX%,%YCOLIDX%
    ECHO     !MSG!
    ECHO !MSG! >> %LOGFILE%
    SET XYZOPTION=/y:%XCOLIDX%,%YCOLIDX%
    IF NOT "%ZCOLIDX%"=="" (
      SET MSG=Z_COLINDEX=%ZCOLIDX%
      ECHO     !MSG!
      ECHO !MSG! >> %LOGFILE%
      SET XYZOPTION=/y:%XCOLIDX%,%YCOLIDX%,%ZCOLIDX%
    )
  )
)
IF NOT "%GENFILE%"=="" (
  SET MSG=GENFILE=%GENFILE%
  ECHO     !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET GENFILEOPTION=/z:"%GENFILE%"
)
IF NOT "%TOPLEVEL%"=="" (
  SET LEVELOPTION=/l:"%TOPLEVEL%"
  IF NOT "%BOTLEVEL%"=="" (
    SET MSG=LEVELS=%TOPLEVEL%,%BOTLEVEL%
    ECHO     !MSG!
    ECHO !MSG! >> %LOGFILE%
    SET LEVELOPTION=/l:"%TOPLEVEL%","%BOTLEVEL%"
  )
)
IF DEFINED EXPCOL (
  IF DEFINED EXPOP (
    SET MSG=SELECT_EXP=%EXPCOL%,%EXPOP%,'%EXPVAL%'
    ECHO     !MSG!
    ECHO !MSG! >> %LOGFILE%
    SET EXPOPTION=/x:%EXPCOL%,%EXPOP%,'%EXPVAL%'
  )
)
IF NOT "%CHANGE_EXPS%" == "" (
  SET MSG=CHANGE_EXPS=%CHANGE_EXPS%
  ECHO     !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET CHANGEOPTION=/c:"%CHANGE_EXPS%"
)
IF "%USEREGEXP%"=="1" SET REGEXPOPTION=/r
IF "%ADDMETADATA%"=="1" SET MOPTION=/m
IF "%TS_SKIP%"=="1" SET TSSOPTION=/tss
IF "%TS_DELEMPTY%"=="1" SET TSEOPTION=/tse
IF DEFINED TS_PERIOD_SDATE (
  IF NOT DEFINED TS_PERIOD_CLIP SET TS_PERIOD_CLIP=0
  SET TSPOPTION=/tsp:%TS_PERIOD_SDATE%,%TS_PERIOD_EDATE%,!TS_PERIOD_CLIP!
  IF DEFINED TS_PERIOD_VALCOLIDX SET TSPOPTION=!TSPOPTION!,%TS_PERIOD_VALCOLIDX%
)

ECHO "%TOOLSPATH%\IPFselect.exe" %MOPTION% %XYZOPTION% %REGEXPOPTION% %EXPOPTION% %GENFILEOPTION% %LEVELOPTION% %CHANGEOPTION% %TSSOPTION% %TSPOPTION% %TSEOPTION% "%IPFPATH%" "%IPFFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IPFselect.exe" %MOPTION% %XYZOPTION% %REGEXPOPTION% %EXPOPTION% %GENFILEOPTION% %LEVELOPTION% %CHANGEOPTION% %TSSOPTION% %TSPOPTION% %TSEOPTION% "%IPFPATH%" "%IPFFILTER%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

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
IF NOT DEFINED NOPAUSE PAUSE
