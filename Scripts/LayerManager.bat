@ECHO OFF
REM **********************************************
REM * SIF-basis v2.1.0 (Sweco)                   *
REM *                                            *
REM * LayerManager.bat                           *
REM * DESCRIPTION                                *
REM *   Checks REGIS/iMOD layers for consistency *
REM * VERSION: 2.0.3                             *
REM * AUTHOR(S): Koen van der Hauw (Sweco)       *
REM * MODIFICATIONS                              *
REM *   2019-02-08 Initial version               *
REM **********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM ISIMODMODEL:    Specify (with value 1) if input files define an iMOD-model, or use value 0 or leave empty to specify REGIS-files (default)
REM INPUTPATH:      Base path to input files
REM TOPPATH:        Path to (unfilled) REGIS/iMOD TOP IDF-files: absolute or relative to INPUTPATH, or leave empty if TOP-files are in INPUTPATH
REM BOTPATH:        Path to (unfilled) REGIS/iMOD BOT IDF-files: absolute or relative to INPUTPATH, or leave empty if BOT-files are in INPUTPATH
REM KHPATH:         Path to corresponding REGIS/iMOD kh IDF-files: absolute or relative to INPUTPATH, or leave empty if files are in INPUTPATH
REM KVPATH:         Path to corresponding REGIS/iMOD kv IDF-files: absolute or relative to INPUTPATH, or leave empty if files are in INPUTPATH
REM KVAPATH:        Path to KVA-files in case of an input iMOD-model and when a KHKVPATH has been set
REM DEFAULTKVA:     Default KVA-value (floating point value in English notation) for missing KVA-files, leave empty to skip KVA
REM REGISORDERFILE: Filename of ASCI-file with current order of all REGIS layers, or leave empty. For each line of this textfile an order number and REGIS layername should be specified (comma seperated), e.g. '1,hlc'
REM ISCHECKED:      Specify (with value 1) that input (REGIS or IMOD) layers should be checked for inconsistencies
REM ISKDCCREATED:   Specify (with value 1) that kD-, c- and thickness IDF-files should be created for output
REM KDCSUBDIRNAME:  Name of subdirectory to store kD-, c- and thickness-grids (if ISKDCCREATED is specified), or leave empty to use default
REM ISCLEANOUTPUT:  Specify (with value 1) if current/old files in 'output'-subdirectory should be deleted before starting
REM RESULTPATH:     Path to write/copy results to
SET ISIMODMODEL=0
SET INPUTPATH=%ROOTPATH%\BASISDATA\REGIS
SET TOPPATH=TOPBOT
SET BOTPATH=TOPBOT
SET KHPATH=KHV
SET KVPATH=KVV
SET KVAPATH=
SET DEFAULTKVA=
SET REGISORDERFILE=
SET ISCHECKED=0
SET ISKDCCREATED=1
SET KDCSUBDIRNAME=.
SET ISCLEANOUTPUT=1
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET LAYERMANAGEREXE=%TOOLSPATH%\LayerManager.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Running script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF DEFINED TOPPATH IF NOT EXIST "%TOPPATH%" (
  IF NOT EXIST "%INPUTPATH%\%TOPPATH%" (
    ECHO TOPPATH could not be found: %TOPPATH%
    ECHO TOPPATH could not be found: %TOPPATH% >> %LOGFILE%
  )
  GOTO error
)
IF DEFINED BOTPATH IF NOT EXIST "%BOTPATH%" (
  IF NOT EXIST "%INPUTPATH%\%BOTPATH%" (
    ECHO BOTPATH could not be found: %BOTPATH%
    ECHO BOTPATH could not be found: %BOTPATH% >> %LOGFILE%
  )
  GOTO error
)

IF DEFINED REGISORDERFILE IF NOT EXIST "%REGISORDERFILE%" (
  IF NOT EXIST "%INPUTPATH%\%REGISORDERFILE%" (
    ECHO INI-file not found: %REGISORDERFILE%
    ECHO INI-file not found: %REGISORDERFILE% >> %LOGFILE%
    GOTO error
  )
)

IF NOT EXIST "%LAYERMANAGEREXE%" (
  ECHO LAYERMANAGEREXE could not be found: %LAYERMANAGEREXE%
  ECHO LAYERMANAGEREXE could not be found: %LAYERMANAGEREXE% >> %LOGFILE%
  GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET IMODOPTION=
SET KHOPTION=
SET KVOPTION=
SET KVAOPTION=
SET DELOPTION=
SET CHECKOPTION=
SET KDCOPTION=
SET ORDEROPTION=
SET TOPOPTION=
SET BOTOPTION=
IF "%ISIMODMODEL%"=="1" SET IMODOPTION=/i
IF DEFINED KHPATH SET KHOPTION=/khv:"%KHPATH%"
IF DEFINED KVPATH SET KVOPTION=/kvv:"%KVPATH%"
IF DEFINED KVAPATH (
  SET KVAOPTION=/kva:"%KVAPATH%"
  IF DEFINED DEFAULTKVA SET KVAOPTION=!KVAOPTION!,%DEFAULTKVA%
) ELSE (
  IF DEFINED DEFAULTKVA SET KVAOPTION=/kva:.,%DEFAULTKVA%
)
IF "%ISCLEANOUTPUT%"=="1" SET DELOPTION=/d
IF "%ISCHECKED%"=="1" SET CHECKOPTION=/c
IF "%ISKDCCREATED%"=="1" (
  IF NOT "%KDCSUBDIRNAME%"=="" (
    SET KDCOPTION=/kdc:"%KDCSUBDIRNAME%"
  ) ELSE (
    SET KDCOPTION=/kdc
  )
)
IF DEFINED REGISORDERFILE SET ORDEROPTION=/o:"%REGISORDERFILE%"
IF DEFINED TOPPATH SET TOPOPTION=/top:"%TOPPATH%"
IF DEFINED BOTPATH SET BOTOPTION=/bot:"%BOTPATH%"

REM Start LayerManager
IF EXIST "%TOOLSPATH%\Tee.exe" (
  ECHO "%LAYERMANAGEREXE%" %CHECKOPTION% %KDCOPTION% %IMODOPTION% %DELOPTION% %KHOPTION% %KVOPTION% %KVAOPTION% %ORDEROPTION% %TOPOPTION% %BOTOPTION% "%INPUTPATH%" "%RESULTPATH%"
  "%LAYERMANAGEREXE%" %CHECKOPTION% %KDCOPTION% %IMODOPTION% %DELOPTION% %KHOPTION% %KVOPTION% %KVAOPTION% %ORDEROPTION% %TOPOPTION% %BOTOPTION% "%INPUTPATH%" "%RESULTPATH%" | "%TOOLSPATH%\Tee.exe" /a %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
) ELSE (
  ECHO "%LAYERMANAGEREXE%" %CHECKOPTION% %KDCOPTION% %IMODOPTION% %DELOPTION% %KHOPTION% %KVOPTION% %KVAOPTION% %ORDEROPTION% %TOPOPTION% %BOTOPTION% "%INPUTPATH%" "%RESULTPATH%" >> %LOGFILE%
  "%LAYERMANAGEREXE%" %CHECKOPTION% %KDCOPTION% %IMODOPTION% %DELOPTION% %KHOPTION% %KVOPTION% %KVAOPTION% %ORDEROPTION% %TOPOPTION% %BOTOPTION% "%INPUTPATH%" "%RESULTPATH%" >> %LOGFILE%
  IF "!ERRORLEVEL!"=="1" GOTO inconsistencies
  IF "!ERRORLEVEL!"=="-1" GOTO error
)

SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
GOTO exit

:inconsistencies
ECHO:
SET MSG=INCONSISTENCIES WERE FOUND^^! Check logfile "%~n0.log"
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
REM Set errorlevel for higher level scripts
CMD /C "EXIT /B 1"
GOTO exit

:error
ECHO:
SET MSG=AN ERROR HAS OCCURRED^^! Check logfile "%~n0.log"
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
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
