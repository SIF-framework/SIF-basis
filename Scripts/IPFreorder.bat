@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IPFreorder.bat                         *
REM * DESCRIPTION                            *
REM *   Reorders or selects IPF-file columns *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.3                         *
REM * MODIFICATIONS                          *
REM *   2018-10-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH:     Specify path to input IPF-file(s)
REM IPFFILTER:   Input IPF-file(s), a commaseperated list with individual files, or a single filter using wildcards * and/or ?
REM ISRECURSIVE: Specify with value 1 to search input path recursively for specified files
REM REORDERING:  A column (re)definition for each column in the result IPF-file, seperated by spaces, defined as follows:
REM                col             : column number (one-based) or columnname in the source IPF-file
REM                col;colname     : column number/name in the source IPF-file and a new columnname for the target IPF-file
REM                +colname;colval : column name for a new column in the target IPF-file, and a single string for the column value of all existing rows.
REM                                  use [n:A=B] for filename and replace substring A with B (case ignored)
REM                                  use [n:-A] for part of filename after last ocurrance of substring A (case ignored)
REM                col+            : copy specified column and all following columns from source source IPF-file
REM                colA=colB       : Rename column with name or number colA in current reordered columns with columnname colB
REM                -col            : Delete column with name or number col in current reordered columns
REM              Notes: when no column definitions are specified, all columns are copied without reordering.
REM                     environment variables are replaced before evaluating column definitions.
REM ASSOCCOL:    Column (in new ordering) with associated files; use name of number, or use value 0 for IPF-files without associated files, 
REM                or leave empty to correct an existing column number for associated files automatically when that column is copied to the new IPF-file.
REM ISTSSKIPPED: Specify with value 1 to skip reading/writing of IPF-timeseries
REM RESULTPATH:  Path to write output IPF-file(s)
REM RESULTFILE:  Optional filename if single inputfile is specified, or leave empty to use name of input file(s)
SET IPFPATH=input
SET IPFFILTER=*.IPF
SET ISRECURSIVE=
SET REORDERING=1;X 2;Y +IPESTZone;[ID] 7;SourceZone
SET ASSOCCOL=
SET ISTSSKIPPED=
SET RESULTPATH=result
SET RESULTFILE=

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Started script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET ASSOPTION=
SET RECOPTION=
SET TSOPTION=
IF DEFINED ASSOCCOL SET ASSOPTION=/a:%ASSOCCOL%
IF "%ISRECURSIVE%"=="1" SET RECOPTION=/r
IF "%ISTSSKIPPED%"=="1" SET TSOPTION=/tss

REM Process all input files, first check for presence of wildcards
SET HASWILDCARDS=
REM Check for question marks
IF NOT "%IPFFILTER:?=%"=="%IPFFILTER%" SET /HASWILDCARDS=1
REM Check for asterisks
REM The same command as above does not work for asterisks, it will make batchfile crash
REM Use workaround, see: https://stackoverflow.com/questions/11685375/i-need-to-match-or-replace-an-asterisk-in-a-batch-environmental-variable-using
FOR /f "tokens=1,* delims=*" %%a IN ("%IPFFILTER%") DO (SET CHECKSTRING=%%a%%b)
IF NOT "%IPFFILTER%"=="%CHECKSTRING%" SET HASWILDCARDS=1

CD "%RESULTPATH%"
SET OUTPUTPATH=%CD%
IF DEFINED RESULTFILE SET OUTPUTPATH=%OUTPUTPATH%\%RESULTFILE%
CD "%THISPATH%"

IF DEFINED HASWILDCARDS (
  ECHO   processing IPF-files for filter '%IPFFILTER%' ...
  ECHO "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% %TSOPTION% "%IPFPATH%" "%IPFFILTER%" "%OUTPUTPATH%" %REORDERING% >> %LOGFILE%
  "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% %TSOPTION% "%IPFPATH%" "%IPFFILTER%" "%OUTPUTPATH%" %REORDERING% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
) ELSE (
  ECHO CD /D "%IPFPATH%" > %LOGFILE%
  CD /D "%IPFPATH%"
  FOR %%G IN ("%IPFFILTER%") DO (
    ECHO   processing %%G
    SET IPFFILENAME=%%~nxG
    IF NOT EXIST "%%G" (
      ECHO File %%G not found
      ECHO File %%G not found >> %LOGFILE%
      GOTO error
    )

    ECHO "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% %TSOPTION% "." "!IPFFILENAME!" "%OUTPUTPATH%" %REORDERING% >> %LOGFILE%
    "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% %TSOPTION% "." "!IPFFILENAME!" "%OUTPUTPATH%" %REORDERING% >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  )
  CD /D "%THISPATH%"
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
IF NOT DEFINED NOPAUSE PAUSE
