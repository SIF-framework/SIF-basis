@ECHO OFF
REM ***************************************************
REM * SIF-basis v2.1.0 (Sweco)                        *
REM *                                                 *
REM * IDFbnd.bat                                      *
REM * DESCRIPTION                                     *
REM *   Sets BND-values in BND-files at modelboundary *
REM *   and corrects BND-files for NoData SHD-values. *
REM * AUTHOR(S): Koen van der Hauw (Sweco)            *
REM * VERSION: 2.0.0                                  *
REM * MODIFICATIONS                                   *
REM *   2016-08-01 Initial version                    *
REM ***************************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM IDFbnd sets IDF-values to -1 at the boundary between inactive (0) and active (1) values. 
REM Ensure that inactive values are defined around the active values in the input grid or set EXTENT-parameter.

REM ********************
REM * Script variables *
REM ********************
REM SOURCEBNDPATH:   Path to source BND-files
REM SOURCEBNDFILTER: Filter for boundary IDF-files in SOURCEBNDPATH, e.g. *.IDF
REM EXTENT:          Extent of the modelboundary (llx,lly,urx,ury), or leave empty to use input extent
REM RESULTPATH:      Path where the scriptresults should be stored
REM METADATA_SOURCE: Metadata source path or organization, or leave empty. Note: the directory with this script is added automatically to a metadata file
SET SOURCEBNDPATH=input
SET SOURCEBNDFILTER=*.IDF
SET EXTENT=%MODELEXTENT%
SET RESULTPATH=result
SET METADATA_SOURCE=

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-plus: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEBNDPATH%" (
   ECHO The specified SOURCEBNDPATH is not existing: %SOURCEBNDPATH%
   ECHO The specified SOURCEBNDPATH is not existing: %SOURCEBNDPATH% > %LOGFILE%
   GOTO error
)
IF NOT EXIST "%SOURCEBNDPATH%\%SOURCEBNDFILTER%" (
   ECHO The specified '%SOURCEBNDFILTER%'-files in SOURCEBNDPATH do not exist: %SOURCEBNDPATH%
   ECHO The specified '%SOURCEBNDFILTER%'-files in SOURCEBNDPATH do not exist: %SOURCEBNDPATH% > %LOGFILE%
   GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

REM Log settings
SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
SET MSG=SOURCEBNDPATH: %SOURCEBNDPATH%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET MSG=EXTENT: %EXTENT%
ECHO %MSG% 
ECHO %MSG% >> %LOGFILE%
ECHO:

REM Correct boundary
SET MSG=Boundary correction for extent ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

IF "%SOURCEBNDFILTER%"=="" SET SOURCEBNDFILTER=*.IDF
SET EXTENTOPTION=/o
IF DEFINED EXTENT SET EXTENTOPTION=/e:%EXTENT%

REM Do boundary corrections with specified options and correction for NoData SHD-valuees
ECHO "%TOOLSPATH%\IDFbnd.exe" /o %EXTENTOPTION% "%SOURCEBNDPATH%" "%SOURCEBNDFILTER%" 1 -1 0 "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IDFbnd.exe" /o %EXTENTOPTION% "%SOURCEBNDPATH%" "%SOURCEBNDFILTER%" 1 -1 0 "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

REM Add metadata to metadata files with process details that have been created by IDFbnd.exe
FOR %%G IN (.\%RESULTPATH%\*.IDF) DO (
  ECHO   adding metadata for %%~nG ...
  ECHO "%TOOLSPATH%\iMODmetadata.exe" "%%~dpnG.MET" "" "" 1 ="%MODELREF0% %MODELNAME%" "" "%CONTACTORG%" "" "" "" "%METADATA_SOURCE%; !THISPATH:%ROOTPATH%\=! " "!THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata.exe" "%%~dpnG.MET" "" "" 1 ="%MODELREF0% %MODELNAME%" "" "%CONTACTORG%" "" "" "" "%METADATA_SOURCE%; !THISPATH:%ROOTPATH%\=! " "!THISPATH:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

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
