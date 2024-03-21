@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM *                                        *
REM * IDFselect.bat                          *
REM * DESCRIPTION                            * 
REM *   Select cellvalue from IDF-files      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2020-04-08 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:       Path to input IDF-file(s) to select cells from
REM SOURCEFILTER:     Filename filter for input IDF-file(s) to select cells from, including extension (? and *-characters can be used as wildcards) (use * to avoid using a filter)
REM ISRECURSIVE:      Specify (with value 1) if source path should be searched recursively for source files
REM ZONEIDFFILE:      Zone IDF-file (or a constant floating point value). Used when a CONNECT-, MINOVERLAP- or MINSIZE-options are specified;
REM CONNECT_*:        Specify with one or more of the following CONNECT_options to select regions in an input IDF-file (non-NoData cells that are connected to one of the zone cells)
REM                   If specified, ZONEIDFFILE is used to define the zones, otherwise all non-NoData values in the input IDF-file are used to define a single zone
REM CONNECT_BYVALUE:    Specify (with value 1) to select all connected non-NoData cells that have the same value in the input grid
REM CONNECT_DIAGONAL:   Specify (with value 1) to select all diagonally connected non-NoData cells
REM CONNECT_SELVALUE:   Specify (with value 1) to use write value from the zone grid to the result IDF-file
REM MINOVERLAPCELLS:  Minimum overlap in selected regions, specified by number of connected cells that overlap zone IDF-file. Specify either MINOVERLAPCELLS or MINOVERLAPPERC or leave both empty.
REM MINOVERLAPPERC:   Minimum overlap in selected regions, specified by fraction of connected cells that overlap zone IDF-file. Specify either MINOVERLAPCELLS or MINOVERLAPPERC or leave both empty.
REM MINOVERLAPCOMB:   If both MINOVERLAPCELLS and MINOVERLAPPERC is specified, define how to combine: 'AND' or 'OR'. Ignored when only one MINOVERLAP-parameter is defined
REM MINSIZEWIDTH:     Minimum width (number of cells) of rectangle inside selected regions, or leave empty. Size can be defined by number of cells or width in meters (by adding 'm' after width).
REM MINSIZEHEIGHT:    Minimum height (number of cells) of rectangle inside selected regions, or leave empty. Size can be defined by number of cells or height h in meters (by adding 'm' after height).
REM VALEXP_*:         Define value expression 'currIDF op valIDF' to select cells in currIDF (input IDF-file or current result). For operator 'op' one of : EQU, NEQ, LSS, LEQ, GTR GEQ, or leave empty to ignore
REM VALEXP_OPERATOR:    Define operator 'op' for expression 'currIDF op valIDF' as one of : EQU, NEQ, LSS, LEQ, GTR GEQ, or leave empty to ignore
REM VALEXP_VALUE:       Define value grid 'valIDF' for expression 'currIDF op valIDF' as an IDF-file or a constant floating point value.
REM EXCLUDEDVALUES:   List of values from input IDF-file to exclude in selection (these are replaced with NoDta-values before selection), or leave empty 
REM ISDELEMPTYFILES:  Specify (with value 1) to select non-empty files after selecting cells; use value 0 or leave empty to write all files
REM RESULTPATH:       Result path or filename if SOURCEFILTER is a single filename
SET SOURCEPATH=..\02 DRN-selection\result
SET SOURCEFILTER=BGTWTR_ID.IDF
SET ISRECURSIVE=
SET ZONEIDFFILE=
SET CONNECT_DIAGONAL=1
SET CONNECT_BYVALUE=1
SET CONNECT_SELVALUE=0
SET MINOVERLAPCELLS=0
SET MINOVERLAPPERC=
SET MINOVERLAPCOMB=
SET MINSIZEWIDTH=3
SET MINSIZEHEIGHT=3
SET VALEXP_OPERATOR=
SET VALEXP_VALUE=
SET EXCLUDEDVALUES=
SET ISDELEMPTYFILES=
SET RESULTPATH=tmp\BGTWTR_ID_plassen.IDF

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF "%SOURCEPATH%"=="" (
  ECHO Please specify SOURCEPATH-value
  ECHO Please specify SOURCEPATH-value > %LOGFILE%
  GOTO error
)

IF "%SOURCEFILTER%"=="" (
  ECHO Please specify SOURCEFILTER-value
  ECHO Please specify SOURCEFILTER-value > %LOGFILE%
  GOTO error
)

ECHO Started script '%SCRIPTNAME%'...
ECHO Started script '%SCRIPTNAME%'... > %LOGFILE%

IF DEFINED MINOVERLAPCELLS IF DEFINED MINOVERLAPPERC (
  IF NOT DEFINED MINOVERLAPCOMB (
    SET MSG=Define MINOVERLAPCOMB when both MINOVERLAPCELLS and MINOVERLAPPERC are set
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)
SET FOPTION=
SET ROPTION=
SET XOPTION=
SET ZOPTION=
SET COPTION=
SET VOPTION=
IF "%ISDELEMPTYFILES%"=="1" SET FOPTION=/s
IF "%ISRECURSIVE%"=="1" SET ROPTION=/r
IF NOT "%EXCLUDEDVALUES%"=="" SET XOPTION=/x:%EXCLUDEDVALUES%
IF NOT "%ZONEIDFFILE%"=="" SET ZOPTION=/z:"%ZONEIDFFILE%"
IF NOT "%VALEXP_OPERATOR%"=="" SET VOPTION=/v:%VALEXP_OPERATOR%,"%VALEXP_VALUE%"

SET COPTIONSVAL=0
IF "%CONNECT_BYVALUE%"=="1" SET /A COPTIONSVAL=COPTIONSVAL+1
IF "%CONNECT_DIAGONAL%"=="1" SET /A COPTIONSVAL=COPTIONSVAL+2
IF "%CONNECT_SELVALUE%"=="1" SET /A COPTIONSVAL=COPTIONSVAL+4
IF NOT "%COPTIONSVAL%" == "0" (
  SET COPTION=/c:%COPTIONSVAL%
  IF DEFINED MINOVERLAPCELLS (
    IF DEFINED MINOVERLAPPERC (
      SET COPTION=/c:%COPTIONSVAL%,%MINOVERLAPCELLS%%MINOVERLAPCOMB%%MINOVERLAPPERC%%%
    ) ELSE (
      SET COPTION=/c:%COPTIONSVAL%,%MINOVERLAPCELLS%
    )
  ) ELSE (
    IF DEFINED MINOVERLAPPERC SET COPTION=/c:%COPTIONSVAL%,%MINOVERLAPPERC%%%
  )
  IF DEFINED MINSIZEWIDTH SET COPTION=!COPTION!,%MINSIZEWIDTH%x%MINSIZEHEIGHT%
)

ECHO "%TOOLSPATH%\IDFselect.exe" %ROPTION% %FOPTION% %VOPTION% %COPTION% %ZOPTION% %XOPTION% "%SOURCEPATH%" "%SOURCEFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IDFselect.exe" %ROPTION% %FOPTION% %VOPTION% %COPTION% %ZOPTION% %XOPTION% "%SOURCEPATH%" "%SOURCEFILTER%" "%RESULTPATH%" >> %LOGFILE%
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
