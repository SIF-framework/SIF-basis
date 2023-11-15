@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * GeoTOPscale.bat                        *
REM * DESCRIPTION                            * 
REM *   Selects points from IPF-file(s)      *
REM * AUTHOR(S): Koen Jansen (Sweco)         *
REM *            Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2022-12-22 Initial version           *
REM ******************************************
CALL :Initialization
CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM STRATPATH:    Path to directory in which stratigraphy voxel is stored
REM LITHOPATH:    Path to directory in which litho class voxel is stored
REM TOPIDFFILE:   Path to IDF-file with TOP-level of processed voxels
REM BOTIDFFILE:   Path to IDF-file with BOT-level of processed voxels
REM KDATASOURCE:  Definition of Excel datasource with k-values. Specify following comma-seperated data p,s,r,c1,c2,c3,c4: 
REM               p:  Path to Excelfile
REM               s:  one-based sheetnumber
REM               r:  one-based header rownumber
REM               c1: one-based columnnumber for stratcode
REM               c2: one-based columnnumber for lithoclass 
REM               c3: one-based columnnumber for kh-value
REM               c4: one-based columnnumber for kv-value
REM EXTENT:       Clip extent for processing input
REM BNDLEVMETHOD: Method b for upper/lower TOP/BOT-level from voxel model to TOP/BOT-IDFFiles (default=0). Use one of the following for method b:
REM               0 round to a thinner layer
REM               1 round to a thicker layer
REM               2 include TOP/BOT-layer if more than half of the voxel thickness layer is in TOP/BOT-layer
REM TIMEOUT:      Timeout length t1,t2 (ms) before cancelling MF6-run (t1) or MF6TOIDF (t2); use 0 to wait indefenitely (default 0)
REM MF6PATH:      Path to MODFLOW 6 executable
REM IMODPATH:     Path to iMOD executable
REM RESULTPATH:   Result path
REM WRITEKVBOT:	  Also write kv_bottom grid, based on bottom flux (otherwise only kv_top is written)
REM WRITEKVSTACK: Also write kv_stack grid, as calculated by simple stack-method
SET STRATPATH=%BASISDATAPATH%\GeoTOP\Voxel\eenheid
SET LITHOPATH=%BASISDATAPATH%\GeoTOP\Voxel\lithoklasse
SET TOPIDFFILE=%BASISDATAPATH%\GeoTOP\Lagenmodel\TOPBOT\bx_tcc.idf
SET BOTIDFFILE=%BASISDATAPATH%\GeoTOP\Lagenmodel\TOPBOT\bx_bcc.idf
SET KDATASOURCE="input\GeoTOP_k-waarden.xlsx",1,2,2,4,6,7 
SET EXTENT=%MODELEXTENT%
SET BNDLEVMETHOD=2
SET TIMEOUT=0,10000
SET MF6PATH=%MODFLOW6EXE%
SET IMODPATH=%iMODEXE%
SET RESULTPATH=result
SET WRITEKVBOT=1
SET WRITEKVSTACK=1

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
SETLOCAL ENABLEDELAYEDEXPANSION

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Build option strings
SET KVBOPTION=
SET KVSOPTION=
SET EOPTION=
SET BOPTION=
SET TOPTION=
SET KOPTION=

IF DEFINED WRITEKVBOT SET KVBOPTION=/kvb
IF DEFINED WRITEKVSTACK SET KVSOPTION=/kvs
IF DEFINED EXTENT SET EOPTION=/e:%EXTENT%
IF DEFINED BNDLEVMETHOD SET BOPTION=/b:%BNDLEVMETHOD%
IF DEFINED TIMEOUT SET TOPTION=/t:%TIMEOUT%
SET KOPTION=/k:%KDATASOURCE%

ECHO "%TOOLSPATH%\GeoTOPscale.exe" %KVBOPTION% %KVSOPTION% %EOPTION% %BOPTION% %TOPTION% %KOPTION% "%STRATPATH%" "%LITHOPATH%" "%TOPIDFFILE%" "%BOTIDFFILE%" "%MF6PATH%" "%IMODPATH%" "%RESULTPATH%" >> %LOGFILE%
IF EXIST "%TOOLSPATH%\Tee.exe" (
  "%TOOLSPATH%\GeoTOPscale.exe" %KVBOPTION% %KVSOPTION% %EOPTION% %BOPTION% %TOPTION% %KOPTION% "%STRATPATH%" "%LITHOPATH%" "%TOPIDFFILE%" "%BOTIDFFILE%" "%MF6PATH%" "%IMODPATH%" "%RESULTPATH%" | "%TOOLSPATH%\Tee.exe" /a %LOGFILE%
) ELSE (
  "%TOOLSPATH%\GeoTOPscale.exe" %KVBOPTION% %KVSOPTION% %EOPTION% %BOPTION% %TOPTION% %KOPTION% "%STRATPATH%" "%LITHOPATH%" "%TOPIDFFILE%" "%BOTIDFFILE%" "%MF6PATH%" "%IMODPATH%" "%RESULTPATH%" >> %LOGFILE%
)
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
IF "%NOPAUSE%"=="" PAUSE
