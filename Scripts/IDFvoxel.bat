@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDFvoxel.bat                           *
REM * DESCRIPTION                            *
REM *   Correction of voxel IDF-files or     *
REM *   conversion from GeoTOP CSV-files.    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.3                         *
REM * MODIFICATIONS                          *
REM *   2018-05-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:    Path to source GeoTOP IDF/CSV/zip-files. Note: format of IDF-filename should be 'xxxx_iii_llll_cm_[onder|boven]_nap.IDF'
REM FILTER:        Filter for source IDF/CSV/zip-files (e.g. *.IDF). For CSV or ZIP-files use set CONVERTCSV=1
REM RECURSIVE:     Specify with value 1 that all subdirectories of the SOURCEPATH should be searched for IDFFILTER-files to scale, or leave empty to process only the SOURCEPATH directory
REM CONVERTCSV:    Specify (with value 1) if voxel CSV-file(s) should be converted to voxel model(s) with IDF-files. CSV-files may be contained in zip-files.
REM CSV_CELLSIZE:  Cellsize of voxels when CONVERTCSV=1
REM CSV_THICKNESS: Thickness (m) of voxels when CONVERTCSV=1
REM CSV_COLNRS:    List of (comma-seperated) column numbers in CSV-files to convert to voxel models when CONVERTCSV=1. Use negative columnnumbers for Exp(val).
REM                Default, both lithoklasse and stratigraphy values are converted
REM CSV_ZONE:      An extent (xll,yll,xur,yur) or a GEN-file (path and filename) with zone to process when CONVERTCSV=1. This will result in a single, merged voxelmodel when multiple csv/zip-files have been specified.
REM ISITBUPDATED:  Specify (with value 1) if ITB-levels for existing voxel IDF-files should be updated/set. The ITB-levels are defined per IDF-file as the TOP- and BOT-level of all voxels in the IDF-file.
REM ISRENAMED:     Specify (with value 1) if existing IDF-filenames of a voxelmodel should be renamed to shorter filenames: xxxx_iii_[+|-]llll_NAP.IDF, with iii reordered (low index for high level)
REM                This option only works in combination with option ISITBUPDATED, see description for that option.
REM RESULTPATH:    Path of the subdirectory where scriptresults are stored. Note: RESULTPATH may be equal to SOURCEPATH, but existing files be overwritten/deleted permanently
SET SOURCEPATH=F:\Projects\EXTERN\RDS_IBR3\Modellen\ModelTemplate-BASISDATA_NL\GeoTOP\CSV-files
SET FILTER=*.zip
SET RECURSIVE=1
SET CONVERTCSV=1
SET CSV_CELLSIZE=100
SET CSV_THICKNESS=0.5
SET CSV_COLNRS=4,5,6,7,8,15,16
SET CSV_ZONE=input\Utrecht.GEN
SET ISITBUPDATED=
SET ISRENAMED=
SET RESULTPATH=result

REM Set toolspath to path for SIF-plus tools
REM SET TOOLSPATH=%TOOLSPATH%_PLUS

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

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% >> %LOGFILE%
   GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

ECHO SOURCEPATH=%SOURCEPATH%
ECHO SOURCEPATH=%SOURCEPATH% >> %LOGFILE%

SET RECURSIVEOPTION=
SET CSVOPTION=
SET ITBOPTION=
IF "%RECURSIVE%"=="1" SET RECURSIVEOPTION=/r
IF "%ITBOPTION%"=="1" SET ITBOPTION=/u
IF "%CONVERTCSV%"=="1" (
  SET CSVOPTION=/i:%CSV_CELLSIZE%,%CSV_THICKNESS%,%CSV_COLNRS%
  IF DEFINED CSV_ZONE SET CSVZONEOPTION=/z:"%CSV_ZONE%"
)

REM Correct sourcepath for relative pathnames or characters
CD "%SOURCEPATH%"
SET SOURCEPATHCORR=%CD%
CD "%THISPATH%"

ECHO "%TOOLSPATH%\IDFvoxel.exe" /o %ITBOPTION% /n %RECURSIVEOPTION% %CSVOPTION% %CSVZONEOPTION% "%SOURCEPATH%" "%FILTER%" "!RESULTPATH!" >> %LOGFILE%
"%TOOLSPATH%\IDFvoxel.exe" /o %ITBOPTION% /n %RECURSIVEOPTION% %CSVOPTION% %CSVZONEOPTION% "%SOURCEPATH%" "%FILTER%" "!RESULTPATH!" >> %LOGFILE%
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
IF NOT DEFINED NOPAUSE PAUSE
