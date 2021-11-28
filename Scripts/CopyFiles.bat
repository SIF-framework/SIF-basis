@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM * Version 1.1.0 December 2020            *
REM *                                        *
REM * CopyFiles.bat                          *
REM * DESCRIPTION                            *
REM *   Copy files to another path           *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2018-09-12 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:           Input path with iMOD-files
REM SOURCEFILTERS:        One or more comma seperated input file filters (use wildcards, e.g. *.IPF or use a complete filename). 
REM                         Note1: use double quotes to enclose filters with spaces
REM                         Note2: to copy one or more complete subdirectories under SOURCEPATH include subdirectoryname with backslash before filtername, e.g. subdirA\*.AAA,subdirB\*.BBB
REM ISOVERWRITE:          Specify if existing targetfiles should be overwritten or skipped (1=overwrite; empty/non-1=skip file)
REM ISMOVED:              Specify if files should be moved instead of copied (1=move; empty/non-1=copy)
REM ISSTOPIFPATHEXISTS:   Specify if whole CopyFiles-script should be stopped (without raising an error) if targetpath already exists  
REM TARGETPATH:           Target path to copy files to
REM TARGETFILENAMES:      In case FILTER did not contain wildcards, specify target filenames (or USE %SOURCEFILTERS% to keep orginal filenames in a new path)
REM ISADDMETADATA:        Specify if metadata should be created/added for each copied file (1=create/add metadata; empty/non-1=skip metadata)
REM                         Note: if an (iMOD) sourcefile has a corresponding MET-file this is copied and added to
REM METADATA_DESCRIPTION: Metadata description for this copy operation
REM METADATA_SOURCE:      Metadata description of source files for this copy operation. Note: path of sourcefile is automatically added
REM METADATA_UNIT:        Metadata unit for selected IDF-file(s)
SET SOURCEPATH=result\BND\100
SET SOURCEFILTERS=*.IDF
SET ISOVERWRITE=1
SET ISMOVED=
SET ISSTOPIFPATHEXISTS=
SET TARGETPATH=%DBASEPATH%\BASIS2\BND\100
SET TARGETFILENAMES=
SET ISADDMETADATA=
SET METADATA_DESCRIPTION=
SET METADATA_SOURCE=
SET METADATA_UNIT=

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET CURRENTDATE=%DATE:~-10,2%-%DATE:~-7,2%-%DATE:~-4,4%
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

ECHO Starting script '%SCRIPTNAME%' ... 
ECHO Starting script '%SCRIPTNAME%' in '%THISPATH%' > %LOGFILE%

IF NOT EXIST "%SOURCEPATH%" (
  SET MSG=SOURCEPATH does not exist: %SOURCEPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF "%ISSTOPIFPATHEXISTS%"=="1" (
  IF EXIST "%TARGETPATH%" (
    SET MSG=  script is skipped, TARGETPATH already exists: %TARGETPATH%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO exit
  )
)

IF "%ISMOVED%"=="1" (
  SET MSG=Moving files from '!SOURCEPATH:%ROOTPATH%\=!' to '!TARGETPATH:%ROOTPATH%\=!' ...
) ELSE (
  SET MSG=Copying files from '!SOURCEPATH:%ROOTPATH%\=!' to '!TARGETPATH:%ROOTPATH%\=!' ...
)
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%

REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
SET ASTERISK_TMP=$
SET SOURCEFILTERS_TMP=%SOURCEFILTERS:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!SOURCEFILTERS_TMP:~%IDX%,1!"=="*" SET SOURCEFILTERS_TMP=!SOURCEFILTERS_TMP:~0,%IDX%!%ASTERISK_TMP%!SOURCEFILTERS_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF NOT "!SOURCEFILTERS_TMP:~%IDX%,1!"=="" GOTO :loop1
SET Nf=0
FOR %%a in (%SOURCEFILTERS_TMP%) do (
  SET SOURCEFILTERS_ARR[!Nf!]=%%a
  SET /A Nf=Nf+1
)

REM remove double quotes for test
SET TARGETTEST="%TARGETFILENAMES%"
SET TARGETTEST=%TARGETTEST:"=%
IF NOT "%TARGETTEST%"=="" (
  SET Nt=0
  FOR %%a IN (%TARGETFILENAMES%) DO (
    SET TARGETFILENAMES_ARR[!Nt!]=%%a
    SET /A Nt=Nt+1
  )
  IF NOT "%Nf%"=="!Nt!" (
    ECHO Number of SOURCEFILTERS '%Nf%' is not equal to number of TARGETFILENAMES '!Nt!'
    ECHO Number of SOURCEFILTERS '%Nf%' is not equal to number of TARGETFILENAMES '!Nt!' >> %LOGFILE%
    GOTO error
  )
)

SET /A Nf=Nf-1

IF NOT EXIST "%TARGETPATH%" MKDIR "%TARGETPATH%"

REM retrieve absolute paths
PUSHD %SOURCEPATH%
SET SOURCEPATH=%CD%
POPD
PUSHD %TARGETPATH%
SET TARGETPATH=%CD%
POPD

FOR /L %%i IN (0,1,%Nf%) DO (
  SET SOURCEFILTER=!SOURCEFILTERS_ARR[%%i]:"=!
  REM Replace temporary wildcard symbols again
  SET SOURCEFILTER=!SOURCEFILTER:@=?!
  SET SOURCEFILTER=!SOURCEFILTER:$=*!

  FOR %%G IN ("!SOURCEPATH!\!SOURCEFILTER!") DO (
    SET SOURCEFILE=%%~dpnxG
    SET SOURCEFILE=!SOURCEFILE:%SOURCEPATH%\=!
    SET SUBPATH=%%~dpG
    SET SUBPATH=!SUBPATH:%SOURCEPATH%\=!
    
    IF NOT EXIST "%SOURCEPATH%\!SOURCEFILE!" (
      ECHO ERROR: SOURCEFILE does not exist: "%SOURCEPATH%\!SOURCEFILE!"
      ECHO ERROR: SOURCEFILE does not exist: "%SOURCEPATH%\!SOURCEFILE!" >> %LOGFILE%
      GOTO error
    )

    IF NOT "%TARGETTEST%"=="" (
      SET TARGETFILE=!TARGETFILENAMES_ARR[%%i]:"=!
    ) ELSE (
      SET TARGETFILE=!SOURCEFILE!
    )

    IF NOT "!TARGETFILE!"=="" (
      IF "%ISMOVED%"=="1" (
        SET MSG=moving "!SOURCEFILE!" to "!TARGETFILE!" ...
      ) ELSE (
        SET MSG=copying "!SOURCEFILE!" to "!TARGETFILE!" ...
      )
      ECHO   !MSG!
      ECHO !MSG!>> %LOGFILE%

      IF NOT "%ISOVERWRITE%"=="1" (
        IF EXIST "%TARGETPATH%\!TARGETFILE!" (
          SET ISSKIPPED=1
        ) ELSE (
          SET ISSKIPPED=
        )
      ) ELSE (
        SET ISSKIPPED=
      )

      IF "!ISSKIPPED!" == "" (  
        IF NOT EXIST "%TARGETPATH%\!SUBPATH!" MKDIR "%TARGETPATH%\!SUBPATH!"
        IF "%ISMOVED%"=="1" (
          ECHO MOVE /Y "%SOURCEPATH%\!SOURCEFILE!" "%TARGETPATH%\!TARGETFILE!" >> %LOGFILE%
          MOVE /Y "%SOURCEPATH%\!SOURCEFILE!" "%TARGETPATH%\!TARGETFILE!" >> %LOGFILE% 2>&1
          IF ERRORLEVEL 1 GOTO error
        ) ELSE (
          ECHO COPY /Y "%SOURCEPATH%\!SOURCEFILE!" "%TARGETPATH%\!TARGETFILE!" >> %LOGFILE%
          COPY /Y "%SOURCEPATH%\!SOURCEFILE!" "%TARGETPATH%\!TARGETFILE!" >> %LOGFILE% 2>&1
          IF ERRORLEVEL 1 GOTO error
        )
   
        IF NOT EXIST "%TARGETPATH%\!TARGETFILE!" (
          SET MSG=File has not been processed properly
          ECHO   !MSG!
          ECHO !MSG! >> %LOGFILE%
          GOTO error
        )
  
        IF "%ISADDMETADATA%"=="1" (
          REM Retrieve filter for metadata files, based on specified source or targetfilename
          FOR /F "tokens=1,2* delims=." %%a IN ("!SOURCEFILE!") DO (
            SET SOURCEFILEBASE=%%a
            SET SOURCEFILEEXT=%%b
          ) 
          FOR /F "tokens=1,2* delims=." %%a IN ("!TARGETFILE!") DO (
            SET TARGETFILEBASE=%%a
            SET TARGETFILEEXT=%%b
          ) 
          IF EXIST "%SOURCEPATH%\!SOURCEFILEBASE!.MET" (
            IF "%ISMOVED%"=="1" (
              ECHO   moving metadata from "!SOURCEFILE!" ...
              ECHO   moving metadata from "!SOURCEFILE!" ... >> %LOGFILE%
              ECHO   MOVE /Y "%SOURCEPATH%\!SOURCEFILEBASE!.MET" "%TARGETPATH%\!TARGETFILEBASE!.MET" >> %LOGFILE%
              MOVE /Y "%SOURCEPATH%\!SOURCEFILEBASE!.MET" "%TARGETPATH%\!TARGETFILEBASE!.MET" >> %LOGFILE% 2>&1
              IF ERRORLEVEL 1 GOTO error
            ) ELSE (
              ECHO   copying metadata from "!SOURCEFILE!" ...
              ECHO   copying metadata from "!SOURCEFILE!" ... >> %LOGFILE%
              ECHO   COPY /Y "%SOURCEPATH%\!SOURCEFILEBASE!.MET" "%TARGETPATH%\!TARGETFILEBASE!.MET" >> %LOGFILE%
              COPY /Y "%SOURCEPATH%\!SOURCEFILEBASE!.MET" "%TARGETPATH%\!TARGETFILEBASE!.MET" >> %LOGFILE% 2>&1
             IF ERRORLEVEL 1 GOTO error
            )
          ) ELSE (
            ECHO   creating metadata for "!TARGETFILE!" ...
            ECHO   creating metadata for "!TARGETFILE!" ... >> %LOGFILE%
            SET OVERWRITEMETADATA=/o
          )
         
          ECHO   "iMODmetadata.exe" !OVERWRITEMETADATA! "%TARGETPATH%\!TARGETFILEBASE!.MET" "" %CURRENTDATE% 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "%METADATA_UNIT%" "" ="%SOURCEPATH%\!SOURCEFILE!; %METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
          "%TOOLSPATH%\iMODmetadata.exe" !OVERWRITEMETADATA! "%TARGETPATH%\!TARGETFILEBASE!.MET" "" %CURRENTDATE% 1 "%MODELREF0%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" IDF "%METADATA_UNIT%" "" ="%SOURCEPATH%\!SOURCEFILE!; %METADATA_SOURCE%" "Zie !THISPATH:%ROOTPATH%\=!; %METADATA_DESCRIPTION%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
      ) ELSE (
        SET MSG=Targetfile already exists and is skipped: "!TARGETPATH:%ROOTPATH%\=!\!SUBPATH!!TARGETFILE!"
        ECHO   !MSG!
        ECHO !MSG! >> %LOGFILE%
      )
    )
  )
)

ECHO Creating shortcut to TARGET directory ...
SET NAME=%SCRIPTNAME%.lnk.lnk
ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%NAME%" "%TARGETPATH%" >> %LOGFILE%
CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%NAME%" "%TARGETPATH%" >NUL

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
IF "%NOPAUSE%"=="" PAUSE
