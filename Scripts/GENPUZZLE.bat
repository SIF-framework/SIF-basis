@ECHO OFF
REM ************************************************
REM * SIF-basis v2.1.0 (Sweco)                     *
REM *                                              *
REM * GENPUZZLE.bat                                *
REM * DESCRIPTION                                  *
REM *   Merge short GEN-segment to larger segments *
REM *   selectively (e.g. empty files)             *
REM * AUTHOR(S): Koen van der Hauw (Sweco)         *
REM * VERSION: 2.0.0                               *
REM * MODIFICATIONS                                *
REM *   2020-02-29 Initial version                 *
REM ************************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM If segments within GEN-files are not aggregated in a single line, the faults for the HFB may have gaps that can result in unwanted leakage. 
REM The reason is that parts of segments that do not cover a complete cell are not converted to modelinput and will be discarded.
REM Therefore it is better to avoid lines with just a few segments and it is recommended to create lines with the most segments as possible.
REM For this the iMOD-batchfunction GENPUZZLE can be used. It creates a new GEN-file in which all loose-ends are connected to form continuous segments. 
REM NOTE: iMOD 5.5 DOES NOT PROCESS 3D GEN-files OR 2D GEN-POLYGONS CORRECTLY

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:   Path to input GEN-files
REM SOURCEFILTER: Filter for input GEN-files (wildcards can be used)
REM ISBINFORCED:  Specify (with value 1) if result GEN-files should always have binary format
REM RESULTPATH:   Name of subdirectory where the scriptresults are stored
REM RESULTFILE:   Optional filename of resulting GEN-file when a single input GEN-file was specified, leave empty if multiple input files are present
SET SOURCEPATH=result
SET SOURCEFILTER=*.GEN
SET ISBINFORCED=
SET RESULTPATH=result2
SET RESULTFILE=

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
REM IMODEXE:      Path and filename of iMOD-executable to use. Note: use iMOD 5.5 or later
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT DEFINED SOURCEPATH (
  SET MSG=SOURCEPATH cannot be empty
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT DEFINED SOURCEFILTER (
  SET MSG=SOURCEFILTER cannot be empty
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

FOR %%D IN ("%SOURCEPATH%\%SOURCEFILTER%") DO (
  SET GENPATH=%%~dpD
  SET GENFILE=%%~nxD
  SET TARGETFILE=!GENFILE!
  IF DEFINED RESULTFILE SET TARGETFILE=RESULTFILE
  SET TARGETFILE=%RESULTPATH%\!TARGETFILE!

  SET MSG=  processing GEN-file '!GENFILE!' ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  IF EXIST "!TARGETFILE!" (
    ECHO     removing existing output file ...
    ECHO DEL "!TARGETFILE!" >> %LOGFILE%
    DEL "!TARGETFILE!" >> %LOGFILE%
  )
  IF ERRORLEVEL 1 GOTO error

  ECHO     creating output file ...
  ECHO FUNCTION=GENPUZZLE > %INIFILE%
  ECHO GENFILE_IN="!GENPATH!!GENFILE!" >> %INIFILE%
  ECHO GENFILE_OUT="!TARGETFILE!" >> %INIFILE%
  IF "%ISBINFORCED%"=="1" ECHO IBINARY=%ISBINFORCED% >> %INIFILE%

  ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
  "%IMODEXE%" %INIFILE% >> %LOGFILE%
  IF NOT EXIST "!TARGETFILE!" (
    ECHO GENPUZZLE did not write resultfile
    ECHO GENPUZZLE did not write resultfile >> %LOGFILE%
    GOTO error
  )
  
)


)
ECHO: 

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
