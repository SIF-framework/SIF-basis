@ECHO OFF
REM *************************************************
REM * SIF-basis (Sweco)                             *
REM * Version 1.1.0 December 2020                   *
REM *                                               *
REM * Clip model.bat                                *
REM * DESCRIPTION                                   * 
REM *   Clips iMOD modelfiles in specified          *
REM *   subdirectories to some extent               *
REM * AUTHOR(S): Pim Dik, Koen van der Hauw (Sweco) *
REM * MODIFICATIONS                                 *
REM *   2017-02-01 Initial version                  *
REM *************************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:        Path to source model
REM BASEEXTENT:        Base extent coordinates (comma seperated): xll,yll,xur,yur. To use defined bufferextent use variable: %MODELEXTENT%
REM BUFFERDIST:        Bufferdistance around base extent for clipping, note; use at least the bufferdistance that is used for the checks of the modelextent (default 2500)
REM CLIPPEDSUBDIRS:    List (comma seperated) of subdirectories to clip; subdirectories with spaces should be surrounded by quotes
REM SKIPPEDEXTENSIONS: List (comma seperated) of file extensions to skip (case insensitive, with or without period)
REM METADATASUBDIRS:   List (comma seperated) of subdirectories to add metadata 
REM OVERWRITEMETADATA: Use 1 if existing metadata should be overwritten with clip details and sourcepath, or leave empty to add to existing metadata
REM IS_WELTXT_DELETED: Use 1 if TXT-files of the WEL-package should be removed (to reduce filesize for steade-state models): use 1 to delete and 0 or empty otherwise
REM WELDIR:            WEL-subdirectory when IS_WELTXT_DELETED=1
REM RESULTPATH:        Path to target model (leave empty to place results in same folder as script)
SET SOURCEPATH=C:\Data\XXX\DBASE\ORG
SET BASEEXTENT=%MODELEXTENT%
SET BUFFERDIST=2500
SET CLIPPEDSUBDIRS=MAAIVELD,KALIBRATIESET,SHD
SET SKIPPEDEXTENSIONS=lnk
SET METADATASUBDIRS=%CLIPPEDSUBDIRS%
SET OVERWRITEMETADATA=
SET IS_WELTXT_DELETED=0
SET WELDIR=WEL
SET RESULTPATH=%DBASEPATH%\ORG-test

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Clipping sourcepath "%SOURCEPATH%" 
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO Base extent: %BASEEXTENT%
ECHO BASEEXTENT=%BASEEXTENT% >> %LOGFILE%
ECHO Buffer distance: %BUFFERDIST% 
ECHO BUFFERDIST=%BUFFERDIST% >> %LOGFILE%

IF "%RESULTPATH%" == "" SET RESULTPATH=.

REM Check that the RESULTPATH is not a rootfolder, to prevent accidental deletion of folders in the root
IF "%RESULTPATH%" == "%RESULTPATH:~0,1%:\" (
   ECHO Please specify a valid RESULTPATH, a root folder is not allowed: %RESULTPATH%
   ECHO Please specify a valid RESULTPATH, a root folder is not allowed: %RESULTPATH% >> %LOGFILE%
   GOTO error
)

IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH is not existing: %SOURCEPATH%
   ECHO The specified SOURCEPATH is not existing: %SOURCEPATH% >> %LOGFILE%
   GOTO error
)

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

IF "%BUFFERDIST%"=="" SET BUFFERDIST=0

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

REM Define clip options
SET XOPTION=
IF NOT "%SKIPPEDEXTENSIONS%"=="" SET XOPTION=/x:%SKIPPEDEXTENSIONS%

REM Do clipping
FOR %%D IN (%CLIPPEDSUBDIRS%) DO (
   ECHO Clippen van %%D ...
   SET CLIPPEDSUBDIR=%%D
   SET CLIPPEDSUBDIR=!CLIPPEDSUBDIR:"=!
   IF "!CLIPPEDSUBDIR!" == "" (
     ECHO Skipping empty subdirectory
   ) ELSE (
     IF EXIST "%RESULTPATH%\!CLIPPEDSUBDIR!" (
       ECHO "%TOOLSPATH%\Del2Bin.exe" /E /F /S "%RESULTPATH%\!CLIPPEDSUBDIR!"  >> %LOGFILE%
       "%TOOLSPATH%\Del2Bin.exe" /E /F /S "%RESULTPATH%\!CLIPPEDSUBDIR!" >> %LOGFILE%
       IF ERRORLEVEL 1 GOTO error
     )
     ECHO "%TOOLSPATH%\iMODclip.exe" /r /o %XOPTION% "%SOURCEPATH%\!CLIPPEDSUBDIR!" "%RESULTPATH%\!CLIPPEDSUBDIR!" %CLIPEXTENT% >> %LOGFILE%
     "%TOOLSPATH%\iMODclip.exe" /r /o %XOPTION% "%SOURCEPATH%\!CLIPPEDSUBDIR!" "%RESULTPATH%\!CLIPPEDSUBDIR!" %CLIPEXTENT% >> %LOGFILE%
     IF ERRORLEVEL 1 GOTO error
   )
)  
ECHO:
ECHO: >> %LOGFILE%

REM Remove TXT-files in WEL-map if requested
IF "%IS_WELTXT_DELETED%" == "1" (
   SET MSG=Deleting TXT-files in WEL-subdirectory ...
   ECHO !MSG!
   ECHO !MSG! >> %LOGFILE%
   ECHO DEL /Q /S /F "%RESULTPATH%\%WELDIR%\*.txt" >> %LOGFILE%
   DEL /Q /S /F "%RESULTPATH%\%WELDIR%\*.txt" >> %LOGFILE%
   ECHO:
   ECHO: >> %LOGFILE%
)

REM Adding metadata to clipped files
SET OVERWRITEOPTION=
IF NOT "%OVERWRITEMETADATA%"=="" SET OVERWRITEOPTION=/o
SET MSG=Adding metadata to subdirectories: %METADATASUBDIRS% ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
FOR %%D IN (%METADATASUBDIRS%) DO (
   IF "%%D" == "" (
     ECHO Skipping empty subdirectory
   ) ELSE (
     IF EXIST "%RESULTPATH%\%%D" (
       ECHO Adding metadata in %%D ...
       CD "%RESULTPATH%\%%D\"
       FOR /R %%G IN (*.IDF) DO (
         ECHO   adding metadata for %%~nG ...
         ECHO "%TOOLSPATH%\iMODmetadata" %OVERWRITEOPTION% "%%G" "" "" "1" ="%MODELREF0%" "Clipped to extent %CLIPEXTENT: =,%" "%CONTACTORG%" "" "" "" "%SOURCEPATH%; See!THISPATH:%ROOTPATH%\=! " "See script: !THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
         "%TOOLSPATH%\iMODmetadata" %OVERWRITEOPTION% "%%G" "" "" "1" ="%MODELREF0%" "Clipped to extent %CLIPEXTENT: =,%" "%CONTACTORG%" "" "" "" "%SOURCEPATH%; See !THISPATH:%ROOTPATH%\=! " "See script: !THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
         IF ERRORLEVEL 1 GOTO error
       )
     )
   )
)
CD "%THISPATH%"
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
