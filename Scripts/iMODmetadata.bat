@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM * Version 1.1.0 December 2020            *
REM *                                        *
REM * iMODmetadata.bat                       *
REM * DESCRIPTION                            * 
REM *   Creates MET-file for given input     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2019-08-26 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:   Input path with iMOD-files
REM SOURCEFILTER: Filter for input files (wildcards * and ? are allowed)
REM ISRECURSIVE:  Specify (with value 1) if subdirectories in input path are checked recursively for input files
REM ISOVERWRITE:  Specify (with value 1) if existing metadatafiles should be overwritten or merged (with value 0)
REM METADATA_SOURCE:             Location of most important sourcefiles. Note that the ROOTPATH-part will be removed from paths in this variable to result in relative paths
REM METADATA_DESCRIPTION:        Description of iMOD-file
REM METADATA_PROCESSDESCRIPTION: Description of process for creating iMOD-file, or leave empty to skip
REM METADATA_UNIT:               Unit abbreviation of data in iMOD-file, or leave empty to skip
REM CONTACTPERSON:               Contactperson for these iMOD-files
REM CONTACTEMAIL:                Emailaddress of contactperson
REM CONTACTORG:                  Organisation of contactperson
REM CONTACTSITE:                 Website of organisation
SET SOURCEPATH=result
SET SOURCEFILTER=*.IDF
SET ISRECURSIVE=1
SET ISOVERWRITE=1
SET METADATA_SOURCE=
SET METADATA_DESCRIPTION=
SET METADATA_PROCESSDESCRIPTION=
SET METADATA_UNIT=
SET CONTACTPERSON=%CONTACTPERSON%
SET CONTACTORG=%CONTACTORG%
SET CONTACTSITE=%CONTACTSITE%
SET CONTACTEMAIL=%CONTACTEMAIL%

REM *********************
REM * Derived variables *
REM *********************
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET SCRIPTNAME=%~n0
SET LOGFILEPATH="%THISPATH%\%SCRIPTNAME%.log"
SET LOGFILENAME="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILEPATH%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% >> %LOGFILEPATH%
   GOTO error
)

SET ISRECURSIVEOPTION=
IF "%ISRECURSIVE%"=="1" SET ISRECURSIVEOPTION=/R

CD "%SOURCEPATH%"
FOR %ISRECURSIVEOPTION% %%G IN ("%SOURCEFILTER%") DO (
  SET MSG=   adding metadata for %%~nG ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILEPATH%
  SET FNAMEnx=%%~nxG
  SET FNAMEn=%%~nG
  SET FNAMEdp=%%~dpG
  SET OVERWRITEOPTION=
  IF "%ISOVERWRITE%"=="1" SET OVERWRITEOPTION=/o
  ECHO "%TOOLSPATH%\iMODmetadata.exe" !OVERWRITEOPTION! "!FNAMEdp!\!FNAMEnx!" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" "" "%METADATA_UNIT%" "" ="!METADATA_SOURCE:%ROOTPATH%\=!" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_PROCESSDESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILEPATH%
  "%TOOLSPATH%\iMODmetadata.exe" !OVERWRITEOPTION! "!FNAMEdp!\!FNAMEnx!" "" "" 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" "" "%METADATA_UNIT%" "" ="!METADATA_SOURCE:%ROOTPATH%\=!" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_PROCESSDESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILEPATH%
  IF ERRORLEVEL 1 GOTO error
)
ECHO:

:success
SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILEPATH%
REM Set errorlevel 0 for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:error
ECHO:
SET MSG=AN ERROR HAS OCCURRED^^! Check logfile "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILEPATH%
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
