@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * Settings.bat                           *
REM * DESCRIPTION                            *
REM *   Defines settings for subworkflow     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2020-01-23 Initial version           *
REM ******************************************
CALL :Initialization

REM **********************
REM * Workflow variables *
REM **********************
REM EXAMPLE1_EXCELFILE:  Path to Excel file XXX with ...
REM EXAMPLE1_EXCELSHEET: Number of sheet with definitions for XXX (first sheet has number 1)
REM EXAMPLE1_STARTROW:   Number of first datarow with data for XXX (first row has number 1)
REM RESULTPATH:    Path to write XXX resultfile to
REM RESULTFILE:    Filename of resulting XXX file 
SET MV_EXCELFILE=input\Example1.xlsx
SET MV_EXCELSHEET=1
SET MV_STARTROW=8
SET RESULTPATH=%DBASEPATH%\%MODELREF1%\Example1
SET RESULTFILE=Example1.IDF

REM *******************
REM * Script commands *
REM *******************
CMD /C "EXIT /B 0"
GOTO exit

REM FUNCTION: Intialize script and search/call 'SETTINGS\SIF.Settings.Project.bat' and '00 settings.bat'. To use: "CALL :Initialization", without arguments
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
  IF EXIST "%~dp0..\00 settings.bat" (
    CALL "%~dp0..\00 settings.bat"
  ) ELSE (
    IF EXIST "%~dp0..\..\00 settings.bat" (
      CALL "%~dp0..\..\00 settings.bat"
    ) ELSE (
      IF EXIST "%~dp0..\..\..\00 settings.bat" (
        CALL "%~dp0..\..\..\00 settings.bat"
      ) ELSE (
        IF EXIST "%~dp0..\..\..\..\00 settings.bat" (
          CALL "%~dp0..\..\..\..\00 settings.bat"
        ) ELSE (
          IF EXIST "%~dp0..\..\..\..\..\00 settings.bat" (
            CALL "%~dp0..\..\..\..\..\00 settings.bat"
          ) ELSE (
            IF EXIST "%~dp0..\..\..\..\..\..\00 settings.bat" (
              CALL "%~dp0..\..\..\..\..\..\00 settings.bat"
            ) ELSE (
              REM Higher level settings file not found, ignore
            )
          )
        )
      )
    )
  )
  GOTO:EOF

:exit
