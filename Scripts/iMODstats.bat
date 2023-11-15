@ECHO OFF
REM ***********************************************
REM * SIF-basis v2.1.0 (Sweco)                    *
REM *                                             *
REM * iMODstats.bat                               *
REM * DESCRIPTION                                 * 
REM *   Calculates statistics for IDF-file(s) and *
REM *   specified extent                          *
REM * AUTHOR(S): Koen van der Hauw (Sweco)        *
REM * VERSION: 2.0.0                              *
REM * MODIFICATIONS                               *
REM *   2017-08-20 Initial version                *
REM ***********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEIDFPATH:  Path with input iMOD IDF-files to calculate statistics for
REM FILTER:         Filter for input IDF-file, wildcards are allowed
REM EXTENT:         Extent (xll,yll,urx,ury), or leave empty to use file extent
REM ISOVERWRITE:    Specify (with value 1) if an existing outputfile should be overwritten or that results should be added to it, or leave empty otherwise
REM RESULTPATH:          Result path
REM RESULTEXCELFILENAME: Result Excel filename
SET SOURCEIDFPATH=%DBASEPATH%\ORG\KHV\100
SET FILTER=*.IDF
SET EXTENT=
SET ISOVERWRITE=1
SET RESULTPATH=result
SET RESULTEXCELFILENAME=iMODstats KHV_L1-19.xlsx

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET IMODSTATSEXE=%TOOLSPATH%\iMODstats.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEIDFPATH%" (
   ECHO The specified SOURCEIDFPATH does not exist: %SOURCEIDFPATH%
   ECHO The specified SOURCEIDFPATH does not exist: %SOURCEIDFPATH% > %LOGFILE%
   GOTO error
)

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO:

SET EXTENTOPTION=
SET OVERWRITEOPTION=
IF DEFINED EXTENT SET EXTENTOPTION=/e:%EXTENT% 
IF "%ISOVERWRITE%"=="1" SET OVERWRITEOPTION=/o
ECHO "%IMODSTATSEXE%" %OVERWRITEOPTION% %EXTENTOPTION% "%SOURCEIDFPATH%" "%FILTER%" "%RESULTPATH%\%RESULTEXCELFILENAME%" >> %LOGFILE% 
"%IMODSTATSEXE%" %OVERWRITEOPTION% %EXTENTOPTION% "%SOURCEIDFPATH%" "%FILTER%" "%RESULTPATH%\%RESULTEXCELFILENAME%" >> %LOGFILE% 
IF ERRORLEVEL 1 GOTO error

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
