@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * GENselect.bat                          *
REM * DESCRIPTION                            * 
REM *   Selects features from GEN-file(s)    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2022-10-09 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM GENPATH:      Path for input GEN-file(s)
REM GENFILTER:    Filter for input GEN-file(s)
REM Specify optional logical expression to select column values with
REM EXPCOLNR:     For logical expression: specifiy (one based) column number of column to evaluate. Note: columnvalues are checked to determine type. Inconsistencies or a single empty string will result in type 'string'.
REM EXPOP:        For logical expression: specify logical operator: eq, gt, gteq, lt, lteq, uneq. Note: gt, gteq, lt and lteq might behave unexpected for string type comparisons, which is based on (ordinal) alphabetical order.
REM EXPVAL:       For logical expression: specify (string, integer, double, DateTime) value to compare with. Leave empty for empty string.
REM CHANGE_EXPS:  One or more column expressions, seperated by semicolons, for modifying columns of selected rows and copy other rows, or leave empty to copy only selected rows. E.g. 3,*2.5,NaN;TOP,-1
REM               Each column/exp-definition is specified by 'c,e,n', where:
REM                'c' is a (one based) column index or a column name. If a column name is not found it is added, where non-selected points will receive an empty string as a value.
REM                'e' is a constant value or a simple expression, defined as operator and value. Valid operators are: *, /, + and -.
REM                'n' is an optional NoData-value for new columns and rows that were not selected.
REM USEREGEXP:    Specify 1 to use regular expressions for string values in combination with (un)equal operator, leave empty or 0 otherwise
REM               An example expression is: '^^(7^|8)$' (without surrounding quotes) to select features with value 7 or 8 in the specified column. For some symbols you need escape characters, in this case for '^' and '|'.
REM               Both regular expressions and escape characters in batchfiles are standard techniques. Check online documentation for details.
REM RESULTPATH:   Result path or filename output GEN-file. If no filename is specified the source name with postfix _sel is used.
SET GENPATH=tmp
SET GENFILTER=*.GEN
SET EXPCOLNR=6
SET EXPOP=uneq
SET EXPVAL=XXX_PP.*
SET CHANGE_EXPS=
SET USEREGEXP=1
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

SET MSG=Selecting features in GEN-file(s^) with filter '%GENFILTER%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Build option strings
SET EXPOPTION=
SET CHANGEOPTION=
SET REGEXPOPTION=
IF DEFINED EXPCOLNR (
  IF DEFINED EXPOP (
    SET MSG=  SELECT_EXP=%EXPCOLNR%,%EXPOP%,"%EXPVAL%"
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    SET EXPOPTION=/x:%EXPCOLNR%,%EXPOP%,"%EXPVAL%"
  )
)
IF NOT "%CHANGE_EXPS%" == "" (
  SET MSG=  CHANGE_EXPS=%CHANGE_EXPS%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET CHANGEOPTION=/c:"%CHANGE_EXPS%"
)
IF "%USEREGEXP%"=="1" SET REGEXPOPTION=/r

ECHO "GENselect.exe" %REGEXPOPTION% %EXPOPTION% %CHANGEOPTION% "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\GENselect.exe" %REGEXPOPTION% %EXPOPTION% %CHANGEOPTION% "%GENPATH%" "%GENFILTER%" "%RESULTPATH%" >> %LOGFILE%
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
IF "%NOPAUSE%"=="" PAUSE
