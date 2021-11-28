@ECHO OFF
REM *************************************************
REM * SIF-basis (Sweco)                             *
REM * Version 1.1.1 November 2021                   *
REM *                                               *
REM * IDFmath.bat                                   *
REM * DESCRIPTION                                   *
REM *   Performs a single IDFmath operation for     *
REM *   multiple IDF-files and/or constant values   * 
REM * AUTHOR(S): Koen van der Hauw (Sweco)          *
REM * MODIFICATIONS                                 *
REM *   2017-09-14 Initial version                  *
REM *************************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM Executes a simple math operation multiple times: <IDF1> <op> <value2>, 
REM   with <IDF1> an IDF-file, <value2> an IDF-file or a constant value and <op> one of +,-,*./
REM IDFFILES1_PATH: Path for first set of IDFs files, to be used before the operator
REM IDFFILES1:      Comma seperated list of IDF-filenames (excluding path), to be used before the operator
REM MATHOPERATOR:   One of the following math operators: +,-,*,/
REM IDFFILES2_PATH: Path for second IDF-files, to be used after the operator, or leave empty if constant values are used
REM IDFFILES2:      Comma seperated list of second IDF-files (excluding path), constant values or NoData, to be used after math operator
REM MATHOPTIONS:    Optional IDFmath options: /o to overwrite output; /v:v1,v2 to use NoData as value v1 or v2 (or leave v1/v2 empty to use NoData-value)
REM RESULTPATH:     Path to write result IDF-files to
REM RESULTFILES:    Comma seperated list of result IDF-filenames
SET IDFFILES1_PATH=%RESULTSPATH%\ORG\BAS\head
SET IDFFILES1=HEAD_STEADY-STATE_L1.IDF,HEAD_STEADY-STATE_L2.IDF,HEAD_STEADY-STATE_L3.IDF
SET MATHOPERATOR=-
SET IDFFILES2_PATH=%RESULTSPATH%\BASIS1\BAS\head
SET IDFFILES2=%IDFFILES1%
SET MATHOPTIONS=/o
SET RESULTPATH=result\effect
SET RESULTFILES=%IDFFILES1:HEAD=EFFECT_HEAD%

REM METADATA_DESCRIPTION:  Metadata description for all files
REM METADATA_SOURCE:       Metadata source for all files
REM METADATA_BASEIDFGROUP: Metadata IDF-group to copy base metadata from: 1 or 2 for each of the inputsets of IDFmath, or leave empty to create new metadata files
SET METADATA_DESCRIPTION=
SET METADATA_SOURCE=%IDFFILES1_PATH%; %IDFFILES2_PATH%
SET METADATA_BASEIDFGROUP=1

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Create arrays for package input
SET Nr1=0
FOR %%a in (%IDFFILES1%) do (
  SET IDFFILES1_ARR[!Nr1!]=%%a
  SET /A Nr1=Nr1+1
)
SET Nr2=0
FOR %%a in (%IDFFILES2%) do (
  SET IDFFILES2_ARR[!Nr2!]=%%a
  SET /A Nr2=Nr2+1
)
SET Nr3=0
FOR %%a in (%RESULTFILES%) do (
  SET RESULTFILES_ARR[!Nr3!]=%%a
  SET /A Nr3=Nr3+1
)
IF NOT %Nr1%==%Nr2% (
  ECHO Number of IDFFILES1 is not equal to number of IDFFILES2
  ECHO Number of IDFFILES1 is not equal to number of IDFFILES2 >> %LOGFILE%
  GOTO error
)
IF NOT %Nr1%==%Nr3% (
  ECHO Number of IDFFILES1 is not equal to number of RESULTFILES
  ECHO Number of IDFFILES1 is not equal to number of RESULTFILES >> %LOGFILE%
  GOTO error
)
SET /A Nr1=Nr1-1

SET MSG=Starting IDF-calculation '%MATHOPERATOR%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST %RESULTPATH% MKDIR %RESULTPATH%

FOR /L %%i IN (0,1,%Nr1%) DO (
  SET IDFFILE1=!IDFFILES1_ARR[%%i]!
  SET IDFFILE2=!IDFFILES2_ARR[%%i]!
  SET IDFPATH1=%IDFFILES1_PATH%\!IDFFILE1!
  SET IDFPATH2=%IDFFILES2_PATH%\!IDFFILE2!
  IF "%IDFFILES1_PATH%"=="" SET IDFPATH1=!IDFFILE1!
  IF "%IDFFILES2_PATH%"=="" SET IDFPATH2=!IDFFILE2!
  SET RESULTFILE=!RESULTFILES_ARR[%%i]!
  ECHO Applying IDFmath.exe !IDFFILE1! '%MATHOPERATOR%' !IDFFILE2! ...
  ECHO Applying IDFmath.exe !IDFFILE1! '%MATHOPERATOR%' !IDFFILE2! ... >> %LOGFILE%
  ECHO "%TOOLSPATH%\IDFmath" %MATHOPTIONS% "!IDFPATH1!" %MATHOPERATOR% "!IDFPATH2!" "%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
  "%TOOLSPATH%\IDFmath" %MATHOPTIONS% "!IDFPATH1!" %MATHOPERATOR% "!IDFPATH2!" "%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error

  ECHO   adding metadata for !RESULTFILE! ...
  SET OVERWRITEMETADATA=
  IF "%METADATA_BASEIDFGROUP%"=="1" IF EXIST "!IDFPATH1:.IDF=.MET!" COPY "!IDFPATH1:.IDF=.MET!" "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" >> %LOGFILE%
  IF "%METADATA_BASEIDFGROUP%"=="2" IF EXIST "!IDFPATH2:.IDF=.MET!" COPY "!IDFPATH2:.IDF=.MET!" "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" >> %LOGFILE%
  IF "%METADATA_BASEIDFGROUP%"=="" SET OVERWRITEMETADATA=/o
  ECHO "%TOOLSPATH%\iMODmetadata" !OVERWRITEMETADATA! "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" "" "" 1 "%MODELREF0%" "!IDFFILE1! %MATHOPERATOR% !IDFFILE2!; %METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "" "" ="%METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata" !OVERWRITEMETADATA! "%RESULTPATH%\!RESULTFILE:.IDF=.MET!" "" "" 1 "%MODELREF0%" "!IDFFILE1! %MATHOPERATOR% !IDFFILE2!; %METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "" "" ="%METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

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
