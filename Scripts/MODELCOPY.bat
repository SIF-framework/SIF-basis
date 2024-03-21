@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * MODELCOPY.bat                          *
REM * DESCRIPTION                            *
REM *   Runs iMOD-batchfuntion MODELCOPY     *
REM *   and copies modelinput from RUN-file  *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-10-10 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM This script runs the iMOD-batchfunction MODELCOPY. The iMOD-manual gives the following description
REM The function MODELCOPY can be used to extract a separate data set for a sub model from a large
REM model. It can also be applied to copy the entire dataset as specified by the entered RUNFILE or
REM PRJFILE into a separate folder. In this process, all IDF and IPF files that can be identified in a 
REM given RUNFILE or PRJFILE, will be clipped to the given window. Other files that are mentioned in the
REM RUNFILE or PRJFILE will be copied. As a result a complete copy of a part of the original model will be
REM saved and can be simulated separately.
REM Note: Other files that might be referred from files other than the specified runfile, will not be copied.

REM ********************
REM * Script variables *
REM ********************
REM RUNFILE:    Runfile to clip from
REM BASEEXTENT: Comma seperated base extent: xll,yll,xur,yur. To use defined bufferextent copy following expression: %MODELEXTENT%
REM BUFFERDIST: Bufferdistance around base extent for clipping, note; use at least the bufferdistance that is used for the checks of the modelextent (default 2500)
REM CELLSIZE:   Cellsize. NOTE: Currently this parameter is mandatory, but is not described in the iMOD-manual and doesn't seem to have any effect. The current cellsize seems to be maintained.
REM CLIPDIR:    Foldername for which all filenames will be trimmed, or leave empty to remove files to subdirectories with package name. See iMOD-manual for example.
REM RESULTPATH: Path to result directory
SET RUNFILE=C:\Data\XXX\RUNFILES\BASISx\XXX_STAT_BASISx_BAS.RUN
SET BASEEXTENT=%MODELEXTENT%
SET BUFFERDIST=2500
SET CELLSIZE=100
SET CLIPDIR=C:\Data\XXX\DBASE
SET RESULTPATH=result

REM ADDMETADATA:         Use 1 to add metadata to clipped iMOD-files, leave empty otherwise
REM METADATAFILTER:      
REM METADATADESCRIPTION: Description to add to metadata (metadata source is added automatically)
REM Specify an optional extra metadescription or leave empty
SET ADDMETADATA=1
SET METADATAFILTERS=*.IDF,*.IPF,*.GEN
SET METADATADESCRIPTION=

REM IMODEXE: Path to iMOD executable to use for MODELCOPY batchfunction, use %iMODEXE% for default or for example %EXEPATH%\iMOD\iMOD_V4_4_X64R.EXE
SET IMODEXE=%IMODEXE%

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET TEMPDIR=tmp
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"
SET INIFILE="%RESULTPATH%\MODELCOPY.INI"

REM ******************
REM * Script commands *
REM ******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%RUNFILE%" (
   ECHO The specified RUNFILE does not exist: %RUNFILE%
   ECHO The specified RUNFILE does not exist: %RUNFILE% > %LOGFILE% 
   GOTO error
)

IF NOT EXIST "%iMODEXE%" (
   ECHO IMODEXE could not be found: %iMODEXE%
   ECHO IMODEXE could not be found: %iMODEXE% > %LOGFILE%
   GOTO error
)

SET MSG=Clipping RUNFILE "%RUNFILE%" 
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO Base extent: %BASEEXTENT%
ECHO BASEEXTENT=%BASEEXTENT% >> %LOGFILE%
ECHO Buffer distance: %BUFFERDIST% 
ECHO BUFFERDIST=%BUFFERDIST% >> %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

REM Calculate clipextents
FOR /F "tokens=1,2,3* delims=," %%a IN ("%BASEEXTENT%") DO (
  SET /A CLIPXLL=%%a-%BUFFERDIST%
  SET /A CLIPYLL=%%b-%BUFFERDIST%
  SET /A CLIPXUR=%%c+%BUFFERDIST%
  SET /A CLIPYUR=%%d+%BUFFERDIST%
) 
SET CLIPEXTENT=%CLIPXLL% %CLIPYLL% %CLIPXUR% %CLIPYUR%

ECHO Clip extent: %CLIPEXTENT% 
ECHO CLIPEXTENT=%CLIPEXTENT% >> %LOGFILE%

REM Do clipping
ECHO FUNCTION=MODELCOPY > %INIFILE%
ECHO RUNFILE="%RUNFILE%" >> %INIFILE%
ECHO TARGETDIR="%RESULTPATH%" >> %INIFILE%
ECHO WINDOW=%CLIPEXTENT% >> %INIFILE%
ECHO CLIPDIR="%CLIPDIR%" >> %INIFILE%
ECHO CELL_SIZE=%CELLSIZE% >> %INIFILE%
 
ECHO Modelcopy ...
ECHO "%iMODEXE%" %INIFILE% >> %LOGFILE%
"%iMODEXE%" %INIFILE% >> %LOGFILE%
IF NOT EXIST "%RESULTPATH%\*.RUN" GOTO error

REM Add metadata to clipped files
SET MSG=Adding metadata to clipped iMOD-files ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
CD "%RESULTPATH%%"
IF "%ADDMETADATA%"=="1" (
  FOR /R %%G IN (%METADATAFILTERS%) DO (
    ECHO   creating metadata for %%~nxG ...
    ECHO "%TOOLSPATH%\iMODmetadata" /o "%%G" "" "" "1" ="%MODELREF0%" "MODELCOPY with extent %CLIPEXTENT: =,%" "%CONTACTORG%""" "" "" "%RUNFILE%;  !THISPATH:%ROOTPATH%\=! " "Zie script: !THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
    "%TOOLSPATH%\iMODmetadata" /o "%%G" "" "" "1" ="%MODELREF0%" "MODELCOPY with extent %CLIPEXTENT: =,%" "%CONTACTORG%" "" "" "" "%RUNFILE%; !THISPATH:%ROOTPATH%\=! " "Zie script: !THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  )
)
CD %THISPATH%

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
