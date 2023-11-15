@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDFinfo.bat                            *
REM * DESCRIPTION                            *
REM *   Checks content of IDF-file(s)        *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2022-01-28 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IDFPATH:       Path to input IDF-files
REM IDFFILTER:     Filter, with use of wildcards, for filenames of input IDF-files, or a single filename
REM IDFVALUE:      Value in IDF-file for check for. Number of cells will be reported. Use "NoData" (without quotes) to check for NoData-values. Leave empty to count number of non-NoData-values.
REM ISERRORRAISED: Specify (with value 1) if an error should be raised when the resulting number of cells is larger than 0 for any of the IDF-files
SET IDFPATH=input
SET IDFFILTER=*.IDF
SET IDFVALUE=NoData
SET ISERRORRAISED=1

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

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

FOR %%G IN ("%IDFPATH%\%IDFFILTER%") DO (
  SET IDFFILENAME=%%~nxG
  ECHO   checking !IDFFILENAME! ...
  ECHO   checking !IDFFILENAME! ... >> %LOGFILE%

  REM Retrieve number of cells with specified value in IDF-file
  ECHO CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%%G" 4 %IDFVALUE% >> %LOGFILE%
  CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%%G" 4 %IDFVALUE%
  IF ERRORLEVEL 1 GOTO error
 
  ECHO   number of cells with value %IDFVALUE%: !IDFINFO!
  ECHO   number of cells with value %IDFVALUE%: !IDFINFO! >> %LOGFILE%
  IF "%ISERRORRAISED%"=="1" (
    IF NOT "!IDFINFO!"=="0" GOTO error
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
