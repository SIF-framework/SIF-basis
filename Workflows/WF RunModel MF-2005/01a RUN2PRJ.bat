@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * RUN2PRJ.bat                            *
REM * DESCRIPTION                            *
REM *   Runs iMOD-batchfunction RUNFILE to   *
REM *   convert a RUN-file to a PRJ-file     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 1.0.1                         *
REM * MODIFICATIONS                          *
REM *   2017-05-16 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM RUNPATH:   Path for input RUN-file, or leave empty for current directory
REM RUNFILE:   Filename of input RUN-file, or leave empty for default (last RUN-file, alphabetically sorted, in RUNPATH)
REM PRJPATH:   Path for resulting PRJ-file, or leave empty for current directory
REM PRJFILE:   Filename of resulting PRJ-file, or leave empty for default (RUN-file name with PRJ extension)
REM IMODEXE:   Path and filename of iMOD executable
REM CREATELNK: Specify (with value 1) if a symbolic link should be created to PRJ-file when PRJPATH is defined
SET RUNPATH=
SET RUNFILE=
SET PRJPATH=
SET PRJFILE=
SET IMODEXE=%IMODEXE%
SET CREATELNK=1

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILENAME="%SCRIPTNAME%.INI"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-plus: %SCRIPTNAME%

SET MSG=Start script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check that specified iMOD executable exists
IF NOT EXIST "%IMODEXE%" (
  ECHO iMOD executable does not exist: %IMODEXE%
  ECHO iMOD executable does not exist: %IMODEXE% >> %LOGFILE%
  GOTO error
)

REM If RUNPATH is not defined use current directory
IF NOT DEFINED RUNPATH SET RUNPATH=.

REM Check that RUN-file exists if defined, otherwise retrieve last RUN-file in specified path
IF DEFINED RUNFILE (
  IF NOT EXIST "%RUNPATH%\%RUNFILE%" ( 
    ECHO RUN-file does not exist: %RUNPATH%\%RUNFILE%
    ECHO RUN-file does not exist: %RUNPATH%\%RUNFILE% >> %LOGFILE%
    GOTO error
  )
) ELSE (
  REM If RUNFILE is not defined, select last RUN-file in current directory
  FOR %%D IN ("%RUNPATH%\*.RUN") DO (
    SET RUNFILE=%%~nxD
  )
)

IF NOT DEFINED RUNFILE (
  ECHO No RUN-file(s^) found for filter *.RUN
  ECHO No RUN-file(s^) found for filter *.RUN >> %LOGFILE%
  GOTO error
)

IF NOT DEFINED PRJPATH SET PRJPATH=.
IF NOT DEFINED PRJFILE SET PRJFILE=%RUNFILE:.RUN=.PRJ%
IF DEFINED PRJPATH IF NOT EXIST "%PRJPATH%" MKDIR "%PRJPATH%"

REM Log used RUN- and PRJ-file
SET MSG=Conversion from RUN-file to PRJ-file
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET MSG=  RUN-file=%RUNPATH%\%RUNFILE%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET MSG=  PRJ-file=%PRJPATH%\%PRJFILE%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

SET MSG=Creating INI-file ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Start writing RUNFILE batchfunction INI-file parameters and values
ECHO FUNCTION=RUNFILE > %INIFILENAME%
ECHO RUNFILE_IN="%RUNPATH%\%RUNFILE%" >> %INIFILENAME%
ECHO PRJFILE_OUT="%PRJPATH%\%PRJFILE%" >> %INIFILENAME%

SET MSG=Starting iMOD-batchfunction RUNFILE ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%IMODEXE%" %INIFILENAME% >> %LOGFILE%
"%IMODEXE%" %INIFILENAME% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error
IF NOT EXIST "%PRJPATH%\%PRJFILE%" GOTO error

IF /I NOT "%PRJPATH%"=="tmp" IF EXIST tmp RMDIR tmp

IF "%CREATELNK%"=="1" (
  IF NOT "%PRJPATH%"=="." (
    REM Retrieve full pathname for PRJPATH
    CD "%PRJPATH%"
    SET PRJPATH=!CD!
    CD "%THISPATH%"

    ECHO Creating shortcut to PRJ-path ...
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%SCRIPTNAME%.lnk.lnk" "!PRJPATH!" >nul
  )
)

:success
ECHO:
ECHO: >> %LOGFILE%
SET MSG=Script finished, see '%~n0.log'
ECHO %MSG%
ECHO %MSG% >> !LOGFILE!
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
