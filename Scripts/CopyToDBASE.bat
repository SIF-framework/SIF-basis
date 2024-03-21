@ECHO OFF
REM **********************************************
REM * SIF-basis v2.1.0 (Sweco)                   *
REM *                                            *
REM * CopyToDBASE.bat                            *
REM * DESCRIPTION                                *
REM *   Copies modelfiles to DBASE subdirs       *
REM *   MET-files are updated and copied as well *
REM * AUTHOR(S): Koen van der Hauw (Sweco)       *
REM * VERSION: 2.0.1                             *
REM * MODIFICATIONS                              *
REM *   2016-08-01 Initial version               *
REM *   2017-10-01 Version with subdirs/removal  *
REM **********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM BASEPATH:        Name of subdirectory where (script)results are stored that should be copied to the DBASE-subdirectory
REM PACKAGEDIRS:     Comma-seperated list of (package) subdirectory names, under the BASEPATH, that will be copied to %DBASEPATH%\MODELREF1[\MODELREF2]. Or leave empty to copy to targetpath MODELREF1[\MODELREF2].
REM                    Each subdirectory can consist of one or more subdirectories e.g. 'DRN\RIVER_SECUNDAIR' and will be copied/moved as a whole.
REM FILTERS:         Specify commaseperated list of filename filter(s) for each of the PACKAGEDIRS, to select files to be copied (? and *-characters can be used as wildcards)
REM MODELREFERENCE:  Model reference string (MODELREF1[_MODELREF2[_MODELREF3]]), to specify DBASE-subdirectory that files should be copied to (e.g. BASIS1_02KHVcorr), or leave empty to retrieve from subdirectory under WORKINPATH
REM MODELSUBDIR:     Optional subdirectory name, under the DBASE-modelmap, to copy files to, or leave empty
REM ISTARGETCLEANED: Specify (with value 1) if contents of targetpath including subdirectories should be deleted before copy
REM ISMOVED:         Specify (with value 1) if source files should be moved instead of copied
REM ISMETADATAADDED:     Specify (with value 1) if metadata should be added to copied/moved files with source path and optional metadata version and decription
REM METADATAVERSION:     Optional version number to be included in the metadata
REM METADATADESCRIPTION: Optional extra metadescription or leave empty
SET BASEPATH=result
SET PACKAGEDIRS=
SET FILTERS=*.IDF
SET MODELREFERENCE=BASIS0
SET MODELSUBDIR=02XXX
SET ISTARGETCLEANED=0
SET ISMOVED=0
SET ISMETADATAADDED=
SET METADATAVERSION=1
SET METADATADESCRIPTION=

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"
SET TMPFILE="%SCRIPTNAME%.tmp"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Retrieve default MODELREFERENCE when not yet defined
IF NOT DEFINED MODELREFERENCE (
  FOR /F "tokens=1,* delims=\" %%A IN ("!CD:%ROOTPATH%\WORKIN\=!") DO (
    SET MODELREFERENCE=%%A
  )
  ECHO MODELREFERENCE: !MODELREFERENCE!
)

SET FULLMODELRELPATH=%MODELREFERENCE:_=\%
IF DEFINED MODELSUBDIR SET FULLMODELRELPATH=%FULLMODELRELPATH%\%MODELSUBDIR%

REM Check DBASEPATH is defined, before continuing with copying data to some unexpected place
IF NOT DEFINED DBASEPATH (
  SET MSG=variable DBASEPATH not defined, ensure script is run from model subdirectory and that SIF.Settings.Project.bat is in SETTINGS-path
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

SET SOURCEPATH=%THISPATH%

REM If PACKAGEDIRS is not defined, simply copy from sourcepath to targetpath DBASE\MODELREFERENCE
IF NOT DEFINED PACKAGEDIRS SET PACKAGEDIRS=.

REM Create arrays for package input
SET Np=0
FOR %%A IN (%PACKAGEDIRS%) DO (
  SET PACKAGEDIR_ARR[!Np!]=%%A
  SET /A Np=Np+1
)
REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
SET ASTERISK_TMP=$
SET FILTERS_TMP=%FILTERS:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!FILTERS_TMP:~%IDX%,1!"=="*" SET FILTERS_TMP=!FILTERS_TMP:~0,%IDX%!%ASTERISK_TMP%!FILTERS_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF NOT "!FILTERS_TMP:~%IDX%,1!"=="" GOTO :loop1
SET Nf=0
FOR %%A IN (%FILTERS_TMP%) DO (
  SET FILTER_ARR[!Nf!]=%%A
  SET /A Nf=Nf+1
)
SET /A N=%Np%-1
IF NOT %Np% == %Nf% (
  ECHO Ensure that number of elements is equal for parameters PACKAGEDIRS (%Np%^) and FILTERS (%Nf%^)
  GOTO error
)

ECHO %SCRIPTNAME% started from %THISPATH% > %LOGFILE%
SET PACKAGEDIRSTRING=%PACKAGEDIRS% subdirectories
IF "!PACKAGEDIRS!"=="." SET PACKAGEDIRSTRING=subdirectories
IF "%ISMOVED%"=="1" (
  SET MSG=Moving !PACKAGEDIRSTRING!
) ELSE (
  SET MSG=Copying !PACKAGEDIRSTRING!
)
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%

SET NTOTALFILES=0
FOR /L %%i IN (0,1,%N%) DO (
  SET NFILES=0
  SET PACKAGEDIR=!PACKAGEDIR_ARR[%%i]!
  SET FILTER_TMP=!FILTER_ARR[%%i]!

  REM Check if BASEPATH is relative or absolute path
  IF "%BASEPATH:~1,1%"==":" (
    SET SOURCEPATH=%BASEPATH%\!PACKAGEDIR!
  ) ELSE (
    SET SOURCEPATH=%THISPATH%%BASEPATH%\!PACKAGEDIR!
  )
  SET TARGETPATH=%DBASEPATH%\%FULLMODELRELPATH%\!PACKAGEDIR!

  REM Replace temporary wildcard symbols again
  SET FILTER=!FILTER_TMP:@=?!
  SET FILTER=!FILTER:$=*!
  
  REM Retrieve filter for metadata files, based on specified filter
  FOR /F "tokens=1,2* delims=." %%a IN ("!FILTER!") DO (
    SET FILTERBASE=%%a
    SET FILTEREXT=%%b
  ) 

  SET PACKAGEDIRSTRING=!PACKAGEDIR!-files
  IF "!PACKAGEDIRS!"=="." SET PACKAGEDIRSTRING=files
  IF "%ISMOVED%"=="1" (
    SET MSG=  moving !PACKAGEDIRSTRING! to %FULLMODELRELPATH%...
  ) ELSE (
    SET MSG=  copying !PACKAGEDIRSTRING! to %FULLMODELRELPATH%...
  )
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  REM Log settings
  SET MSG=SOURCEPATH: !SOURCEPATH!
  ECHO !MSG! >> %LOGFILE%
  SET MSG=TARGETPATH: !TARGETPATH!
  ECHO !MSG! >> %LOGFILE%

  REM Delete target subdirectory (under model dbase path) if specified and name was not empty 
  IF "%ISTARGETCLEANED%"=="1" (
    IF EXIST !TARGETPATH! (
      IF NOT "!TARGETPATH!"=="" (
        IF NOT "!PACKAGEDIR!"=="" (
          IF EXIST "!TARGETPATH!\*" (
            ECHO Removing following files from !TARGETPATH! ... >> %LOGFILE%
            DIR /B "!TARGETPATH!" >> %LOGFILE%
            ECHO "%TOOLSPATH%\Del2Bin.exe" /E /S "!TARGETPATH!" >> %LOGFILE%
            "%TOOLSPATH%\Del2Bin.exe" /E /S "!TARGETPATH!" >> %LOGFILE% 2>&1
            IF ERRORLEVEL 1 GOTO error
            ECHO: >> %LOGFILE%
          )
        )
      )
    )
  )

  IF NOT EXIST "!TARGETPATH!" MKDIR "!TARGETPATH!"
  
  REM Move/copy files to DBASE
  FOR %%G IN ("!SOURCEPATH!\!FILTER!") DO (
    IF /I NOT "%%~xG"==".MET" IF /I NOT "%%~xG"==".lnk" (
      IF "%ISMOVED%"=="1" (
        SET MSG=    moving %%~nxG ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        ECHO MOVE /Y "!SOURCEPATH!\%%~nxG" "!TARGETPATH!" >> %LOGFILE%
        MOVE /Y "!SOURCEPATH!\%%~nxG" "!TARGETPATH!" > %TMPFILE%
      ) ELSE (
        SET MSG=    copying %%~nxG ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        ECHO XCOPY /Y /S "!SOURCEPATH!\%%~nxG" "!TARGETPATH!" >> %LOGFILE%
        XCOPY /Y /S "!SOURCEPATH!\%%~nxG" "!TARGETPATH!" > %TMPFILE%
      )
      IF ERRORLEVEL 1 (
        TYPE %TMPFILE%
        TYPE %TMPFILE% >> %LOGFILE%
        DEL %TMPFILE%
        GOTO error
      )
      TYPE %TMPFILE% >> %LOGFILE%

      SET /A NFILES=NFILES + 1
    )
  
    REM Copy metadata if present
    IF EXIST "!SOURCEPATH!\%%~nG.MET" (
      IF "%ISMOVED%"=="1" (
        ECHO MOVE /Y "!SOURCEPATH!\%%~nG.MET" "!TARGETPATH!" >> %LOGFILE%
        MOVE /Y "!SOURCEPATH!\%%~nG.MET" "!TARGETPATH!" > %TMPFILE%
      ) ELSE (
        ECHO XCOPY /Y /S "!SOURCEPATH!\%%~nG.MET" "!TARGETPATH!" >> %LOGFILE%
        XCOPY /Y /S "!SOURCEPATH!\%%~nG.MET" "!TARGETPATH!" > %TMPFILE%
      )
      IF ERRORLEVEL 1 (
        TYPE %TMPFILE%
        TYPE %TMPFILE% >> %LOGFILE%
        DEL %TMPFILE%
        GOTO error
      )
      TYPE %TMPFILE% >> %LOGFILE%
    )

    IF "%ISMETADATAADDED%"=="1" (
      REM Add metadata with process details to existing metadata files 
      IF DEFINED METADATAVERSION (
        SET METADATAVERSION="%METADATAVERSION%"
      )
      SET MSG=    adding metadata for %%~nxG ...
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      ECHO "%TOOLSPATH%\iMODmetadata" "!TARGETPATH!\%%~nxG" "%%~dpnxG" "" !METADATAVERSION! ="%MODELREF0% %MODELREFERENCE%" "%METADATADESCRIPTION%" "%CONTACTORG%" "" "" "" "%SOURCEPATH%; " "Zie %THISPATH:~,-1%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
      "%TOOLSPATH%\iMODmetadata" "!TARGETPATH!\%%~nxG" "%%~dpnxG" "" !METADATAVERSION! ="%MODELREF0% %MODELREFERENCE%" "%METADATADESCRIPTION%" "%CONTACTORG%" "" "" "" "%SOURCEPATH%; " "Zie %THISPATH:~,-1%" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  )
  IF "%ISMOVED%"=="1" (
    REM Put symbolic link in source path
    CD "!SOURCEPATH!"
    ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "DBASE %FULLMODELRELPATH:\=_% - snelkoppeling.lnk" "!TARGETPATH:\.=!" >> %LOGFILE%
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "DBASE %FULLMODELRELPATH:\=_% - snelkoppeling.lnk" "!TARGETPATH:\.=!" >nul
  )
  CD "%THISPATH%"
  
  SET PACKAGEDIRSTRING=!PACKAGEDIR!-file(s^)
  IF "!PACKAGEDIRS!"=="." SET PACKAGEDIRSTRING=file(s^)
  SET /A NTOTALFILES=NTOTALFILES+NFILES
  IF "%ISMOVED%"=="1" (
    SET MSG=  !NFILES! !PACKAGEDIRSTRING! have been moved to !TARGETPATH:%ROOTPATH%\=!
  ) ELSE (
    SET MSG=  !NFILES! !PACKAGEDIRSTRING! have been copied to !TARGETPATH:%ROOTPATH%\=!
  )
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO:
  ECHO: >> %LOGFILE%
)
IF EXIST %TMPFILE% DEL %TMPFILE%
  
ECHO Creating shortcut to DBASE directory ...
ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "DBASE %FULLMODELRELPATH:\=_% - snelkoppeling.lnk" "%DBASEPATH%\%FULLMODELRELPATH%" >> %LOGFILE%
CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "DBASE %FULLMODELRELPATH:\=_% - snelkoppeling.lnk" "%DBASEPATH%\%FULLMODELRELPATH%" >nul

ECHO:
ECHO: >> %LOGFILE%

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
