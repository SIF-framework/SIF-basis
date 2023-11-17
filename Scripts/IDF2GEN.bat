@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * IDF2GEN.bat                            *
REM * DESCRIPTION                            *
REM *   Convertd IDF-file(s) to GEN-file(s)  *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2018-09-12 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IDFPATH:       Path to GEN-file(s)
REM IDFFILTER:     Filename filter for IDF-file(s), including extension (? and *-characters can be used as wildcards)
REM METHOD:        Method for conversion to hull from all non-NoData IDF-cells with 1: a convex hull; 2: a concave hull, 3: cell edges; 4; cell edges + IPF-points; 5; outer edges of outer cells or 0) no hull, just write IPF-points for all non-NoData IDF-cells
REM METHODPAR:     Method parameter, depending on method: 2 (concave hull), specify number of neighbours (k-value), default is 3
REM ISSPLIT:       Specify if IDF-file should be split into seperate features based on unique IDF-values (use value 1), or leave empty
REM SKIPPEDVALUES: Comma seperated values (vi) or value ranges (vi-vj) to skip, use english notation for floating points. Do not add spaces.
REM ADDLENGTH:     Specify with value 1 that an IDF-file with length of area of GEN-file in cells should be added, or leave empty to skip
REM ISMERGED:      Specify if output GEN-files should be merged (use value 1) into one GEN-file, or leave empty
REM RESULTPATH:    Result path or filename if IDFFILTER is a single filename
REM RESULTFILE:    Output GEN-filename when merged or for a single inputfile, or leave empty to use default
SET IDFPATH=input
SET IDFFILTER=*.IDF
SET METHOD=1
SET METHODPAR=100
SET ISSPLIT=0
SET SKIPPEDVALUES=
SET ISMERGED=
SET RESULTPATH=result
SET RESULTFILE=

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

ECHO Converting IDF-file from %IDFPATH% ...
ECHO Converting IDF-file from %IDFPATH% ... > %LOGFILE%

SET MERGEOPTION=
SET HULLOPTION=
SET SPLITOPTION=
SET SKIPOPTION=
IF NOT "%ISMERGED%"=="" (
  IF NOT "%RESULTFILE%"=="" (
    SET MERGEOPTION=/m:"%RESULTFILE%"
  ) ELSE (
    SET MERGEOPTION=/m
  )
)
IF NOT "%RESULTFILE%"=="" (
  SET RESULTPATH=%RESULTPATH%\%RESULTFILE%
)
IF "%ISSPLIT%"=="1" SET SPLITOPTION=/u
IF NOT "%SKIPPEDVALUES%"=="" SET SKIPOPTION=/s:%SKIPPEDVALUES%
IF DEFINED METHOD (
  IF "%METHOD%"=="2" (
    IF DEFINED METHODPAR (
      SET HULLOPTION=/h:2,%METHODPAR%
    ) ELSE (
      SET HULLOPTION=/h:2
    )
  ) ELSE (
    IF %METHOD% LSS 6 (
      SET HULLOPTION=/h:%METHOD%
    ) ELSE (
      ECHO Invalid method value, use 0 - 5: %METHOD%
      ECHO Invalid method value, use 0 - 5: %METHOD% >> %LOGFILE%
      GOTO error
    )
  )
)

ECHO "%TOOLSPATH%\IDFGENconvert.exe" %SPLITOPTION% %SKIPOPTION% %HULLOPTION% %MERGEOPTION% "%IDFPATH%" "%IDFFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IDFGENconvert.exe" %SPLITOPTION% %SKIPOPTION% %HULLOPTION% %MERGEOPTION% "%IDFPATH%" "%IDFFILTER%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

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
