@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDFSCALE.bat                           *
REM * DESCRIPTION                            *
REM *   Runs iMOD-batchfunction IDFSCALE for *
REM *   one or more IDF-files.               *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.2                         *
REM * MODIFICATIONS                          *
REM *   2017-06-20 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:   Path to IDF-file(s)
REM IDFFILTER:    Filter for IDF-files to scale
REM ISRECURSIVE:  Specify (with value 1) if all subdirectories of SOURCEPATH should be searched recursively for IDFFILTER-files, or leave empty to search in SOURCEPATH only
REM SCALESIZE:    Cellsize to scale to. If empty or equal to cellsize of source IDF-file, the file is copied.
REM SCLTYPE_UP:   Scaletype for upscaling: 1=boundary, 2=arithmetic mean, 3=geometric mean, 4=sum, 5=sum conductance, 7=most frequent occurence, 10=blockvalue, 9=percentile, see iMOD-manual for other types. Or leave empty to skip upscaling.
REM SCLTYPE_DOWN: Scaletype for downscaling: 1=interpolation, 2=gridvalue, see imod-manual for options. Or leave empty to skip downscaling. 
REM WEIGHFACTOR:  Weight factor, optional in SCLTYPE_UP (types 1,3,4,5,6,9), the default value is 1.0
REM PERCENTILE:   Percentile (between 0.0 and 1.0) in case of SCLTYPE_UP=9, otherwise leave empty
REM BLOCK:        Size of interpolation block, optional for SCLTYPE_DOWN=1. Possible values: 4,16,36,64,100. Matrices of BLOCKxBLOCK are used for interpolation of each point.
REM WINDOW:       Extent of the modelboundary (llx,lly,urx,ury or llx lly urx ury), or leave empty to keep current extent
REM ISCOPYOTHER:  Use value 1 to copy non IDF-files in SOURCEPATH, or leave empty to skip other files
REM RESULTPATH:   Path to (sub)directory where scriptresults are stored
REM RESULTFILE:   Filename of result file when a single source file has been specified, otherwise leave empty
SET SOURCEPATH=%DBASEPATH%\ORG\KHV\25
SET IDFFILTER=*.IDF
SET ISRECURSIVE=1
SET SCALESIZE=100
SET SCLTYPE_UP=2
SET SCLTYPE_DOWN=1
SET WEIGHFACTOR=
SET PERCENTILE=0.5
SET BLOCK=
SET WINDOW=
SET ISCOPYOTHER=1
SET RESULTPATH=result
SET RESULTFILE=

REM IMODEXE:    Path to iMOD executable to use for IDFSCALE batchfunction, use %iMODEXE% for default or for example %EXEPATH%\iMOD\iMOD_V4_4_X64R.EXE
REM DEL2BINEXE: Path to Del2Bin.exe
SET IMODEXE=%IMODEXE%
SET DEL2BINEXE=%TOOLSPATH%\Del2Bin.exe

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% > %LOGFILE%
   GOTO error
)

IF "%SOURCEPATH%" == "%RESULTPATH%" (
  IF NOT DEFINED RESULTFILE (
    ECHO SOURCEPATH should not be equal to RESULTPATH: %SOURCEPATH%
    ECHO SOURCEPATH should not be equal to RESULTPATH: %SOURCEPATH% > %LOGFILE%
    GOTO error
  )
)

IF NOT EXIST "%IMODEXE%" (
   ECHO IMODEXE could not be found: %IMODEXE%
   ECHO IMODEXE could not be found: %IMODEXE% > %LOGFILE%
   GOTO error
)

REM Create result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

REM Log settings
ECHO   Sourcepath: !SOURCEPATH:%ROOTPATH%\=!
ECHO SOURCEPATH=%SOURCEPATH% >> %LOGFILE%
ECHO   Scalesize: %SCALESIZE%
ECHO SCALESIZE=%SCALESIZE% >> %LOGFILE%
ECHO:

REM Retrieve absolute path for SOURCEPATH
PUSHD %SOURCEPATH%
SET SOURCEPATH=%CD%
POPD

REM Scaling IDF-files
IF "%ISRECURSIVE%"=="1" (
  SET MSG=Scaling IDF-files recursively ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  FOR /R "%SOURCEPATH%" %%G IN (%IDFFILTER%) DO (
    SET IDFFILENAME=%%~nxG
    SET IDFFILEPATH=%%G
    SET IDFPATH=%%~dpG

    REM Remove first part of path in message for readability 
    SET TARGETSUBPATH=!IDFPATH:%SOURCEPATH%=!
    SET TARGETSUBPATH=!TARGETSUBPATH:~1!
    SET TARGETPATH=!IDFPATH:%SOURCEPATH%=%RESULTPATH%!
    SET TARGETPATH=!TARGETPATH:~0,-1!
    IF DEFINED RESULTFILE (
      SET TARGETFILENAME=%RESULTFILE%
    ) ELSE (
      SET TARGETFILENAME=!IDFFILENAME!
    )

    IF NOT EXIST "!TARGETPATH!" MKDIR "!TARGETPATH!"

    REM Check cellsize of source IDF-file
    SET ISIDFCOPIED=
    IF DEFINED SCALESIZE (
      IF EXIST "%TOOLSPATH%\SIF.iMOD.runsub.bat" (
        ECHO   CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "!IDFFILEPATH!" 1 >> %LOGFILE%
        CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "!IDFFILEPATH!" 1
        IF NOT "!IDFINFO!"=="0" (
          SET SOURCECELLSIZE=!IDFINFO!
          SET MSGPOSTFIX=(from cellsize !SOURCECELLSIZE!^) 
        )
        IF "%SCALESIZE%"=="!SOURCECELLSIZE!" (
          REM Check extent of source IDF-file
          ECHO   CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "!IDFFILEPATH!" 3 >> %LOGFILE%
          CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "!IDFFILEPATH!" 3
          IF NOT "!IDFINFO!"=="0" (
            SET SOURCEEXTENT=!IDFINFO!
            SET TARGETEXTENT=!SOURCEEXTENT!
            IF DEFINED WINDOW SET TARGETEXTENT=%WINDOW%
            
            REM For now assume extent is different and file should be scaled
            SET MSGPOSTFIX=(with cellsize %SCALESIZE%, but different extent^) 

            REM Compare extents
            ECHO   CALL :ISEQUALEXTENT "!SOURCEEXTENT!" "!TARGETEXTENT!" >> %LOGFILE%
            CALL :ISEQUALEXTENT "!SOURCEEXTENT!" "!TARGETEXTENT!"
            IF ERRORLEVEL 1 GOTO error
            
            IF "!ISEQUALEXTENT!"=="1" (
              SET ISIDFCOPIED=1
              SET MSGPOSTFIX=(with cellsize %SCALESIZE% and equal extent^) 
            )
          )
        )
      ) ELSE (
        IF NOT DEFINED RUNSUBBATNOTFOUND (
          ECHO Note: SIF.iMOD.runsub not found, check for current scale is skipped
          ECHO Note: SIF.iMOD.runsub not found, check for current scale is skipped >> %LOGFILE%
        )  
        SET RUNSUBBATNOTFOUND=1
      )
    ) ELSE (
      SET ISIDFCOPIED=1
    )

    IF NOT DEFINED ISIDFCOPIED (
      ECHO   scaling !TARGETSUBPATH!!IDFFILENAME! !MSGPOSTFIX!...
      ECHO   scaling !TARGETSUBPATH!!IDFFILENAME! !MSGPOSTFIX!... >> %LOGFILE%
      ECHO FUNCTION=IDFSCALE > %INIFILE%
      ECHO SCALESIZE=%SCALESIZE% >> %INIFILE%
      IF NOT "%SCLTYPE_UP%"=="" (
        ECHO SCLTYPE_UP=%SCLTYPE_UP% >> %INIFILE%
  
        IF NOT "%WEIGHFACTOR%"=="" (
          ECHO WEIGHFACTOR=%WEIGHFACTOR% >> %INIFILE%
        )
        IF NOT "%PERCENTILE%"=="" (
          ECHO PERCENTILE=%PERCENTILE% >> %INIFILE%
        )
      )
      IF NOT "%SCLTYPE_DOWN%"=="" (
        ECHO SCLTYPE_DOWN=%SCLTYPE_DOWN% >> %INIFILE%
  
        IF NOT "%BLOCK%"=="" (
          ECHO BLOCK=%BLOCK% >> %INIFILE%
        )
      )
      IF NOT "%WINDOW%"=="" (
        ECHO WINDOW=%WINDOW: =,% >> %INIFILE%
      )
      ECHO SOURCEIDF='!IDFFILEPATH!' >> %INIFILE%
      ECHO OUTFILE='!TARGETPATH!\!TARGETFILENAME!' >> %INIFILE%
     
      IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
        REM Remove previous result 
        IF EXIST "!TARGETPATH!\!TARGETFILENAME!" (
          ECHO "%DEL2BINEXE%" /E /F "!TARGETPATH!\!TARGETFILENAME!" >> %LOGFILE%
          "%DEL2BINEXE%" /E /F "!TARGETPATH!\!TARGETFILENAME!" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
      ) ELSE (
        IF NOT DEFINED DEL2BINNOTFOUND (
          ECHO Note: previous results not removed, Del2Bin.exe not found: !DEL2BINEXE:%ROOTPATH%\=!
          ECHO Note: previous results not removed, Del2Bin.exe not found: !DEL2BINEXE:%ROOTPATH%\=! >> %LOGFILE%
        )  
        SET DEL2BINNOTFOUND=1
      )

      REM Use iMOD to scale
      ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
      "%IMODEXE%" %INIFILE% >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
      IF NOT EXIST "!TARGETPATH!\!TARGETFILENAME!" (
        ECHO ERROR: !TARGETPATH!\!TARGETFILENAME! has not been created!
        ECHO ERROR: !TARGETPATH!\!TARGETFILENAME! has not been created! >> %LOGFILE%
        GOTO error
      ) 
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO   copying !TARGETSUBPATH!!TARGETFILENAME! !MSGPOSTFIX!...
      ECHO   copying !TARGETSUBPATH!!TARGETFILENAME! !MSGPOSTFIX!... >> %LOGFILE%
      ECHO COPY /Y "!IDFFILEPATH!" "!TARGETPATH!\!TARGETFILENAME!" >> %LOGFILE%
      COPY /Y "!IDFFILEPATH!" "!TARGETPATH!\!TARGETFILENAME!" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  )

  IF "%ISCOPYOTHER%"=="1" (
    ECHO Copying other files (non-IDF^) recursively ...
    FOR /R "%SOURCEPATH%" %%G IN (*) DO (
      SET FILEEXT=%%~xG
      IF /I NOT "!FILEEXT!"==".IDF" (
        SET FILENAME=%%~nxG
        SET FULLFILENAME=%%G
        SET FILEPATH=%%~dpG
        SET TARGETSUBPATH=!FILEPATH:%SOURCEPATH%=!
        SET TARGETSUBPATH=!TARGETSUBPATH:~1!
        SET TARGETPATH=!FILEPATH:%SOURCEPATH%=%RESULTPATH%!
        SET TARGETPATH=!TARGETPATH:~0,-1!
        IF NOT EXIST "!TARGETPATH!" MKDIR "!TARGETPATH!"
        ECHO   Copying !TARGETSUBPATH!!FILENAME! ...
        ECHO   Copying !TARGETSUBPATH!!FILENAME! ... >> %LOGFILE%
        ECHO COPY /Y "!FULLFILENAME!" "!TARGETPATH!" >> %LOGFILE%
        COPY /Y "!FULLFILENAME!" "!TARGETPATH!" >> %LOGFILE%
      )
    )
  )
) ELSE (
  SET MSG=Scaling IDF-files ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  FOR %%G IN ("%SOURCEPATH%\%IDFFILTER%") DO (
    SET IDFFILENAME=%%~nxG
    IF DEFINED RESULTFILE (
      SET TARGETFILENAME=%RESULTFILE%
    ) ELSE (
      SET TARGETFILENAME=!IDFFILENAME!
    )

    REM Check cellsize of source IDF-file
    SET ISIDFCOPIED=
    IF DEFINED SCALESIZE (
      IF EXIST "%TOOLSPATH%\SIF.iMOD.runsub.bat" (
        ECHO   CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%SOURCEPATH%\!IDFFILENAME!" 1 >> %LOGFILE%
        CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%SOURCEPATH%\!IDFFILENAME!" 1
        IF NOT "!IDFINFO!"=="0" (
          SET SOURCECELLSIZE=!IDFINFO!
          REM For now assume cellsize is different and file should be scaled
          SET MSGPOSTFIX=(from cellsize !SOURCECELLSIZE!^) 
        )
        IF "%SCALESIZE%"=="!SOURCECELLSIZE!" (
          REM Check extent of source IDF-file
          ECHO   CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%SOURCEPATH%\!IDFFILENAME!" 3 >> %LOGFILE%
          CALL "%TOOLSPATH%\SIF.iMOD.runsub" :IDFINFO "%SOURCEPATH%\!IDFFILENAME!" 3
          IF NOT "!IDFINFO!"=="0" (
            SET SOURCEEXTENT=!IDFINFO!
            SET TARGETEXTENT=!SOURCEEXTENT!
            IF DEFINED WINDOW SET TARGETEXTENT=%WINDOW%
            
            REM For now assume extent is different and file should be scaled
            SET MSGPOSTFIX=(with cellsize %SCALESIZE%, but different extent^) 

            REM Compare extents
            ECHO   CALL :ISEQUALEXTENT "!SOURCEEXTENT!" "!TARGETEXTENT!" >> %LOGFILE%
            CALL :ISEQUALEXTENT "!SOURCEEXTENT!" "!TARGETEXTENT!"
            IF ERRORLEVEL 1 GOTO error
            
            IF "!ISEQUALEXTENT!"=="1" (
              SET ISIDFCOPIED=1
              SET MSGPOSTFIX=(with cellsize %SCALESIZE% and equal extent^) 
            )
          )
        )
      ) ELSE (
        IF NOT DEFINED RUNSUBBATNOTFOUND (
          ECHO Note: SIF.iMOD.runsub not found, check for current scale is skipped
          ECHO Note: SIF.iMOD.runsub not found, check for current scale is skipped >> %LOGFILE%
        )  
        SET RUNSUBBATNOTFOUND=1
      )
    ) ELSE (
      SET ISIDFCOPIED=1
    )

    IF NOT DEFINED ISIDFCOPIED (
      ECHO   scaling !IDFFILENAME! !MSGPOSTFIX!...
      ECHO   scaling !IDFFILENAME! !MSGPOSTFIX!... >> %LOGFILE%
      ECHO FUNCTION=IDFSCALE > %INIFILE%
      ECHO SCALESIZE=%SCALESIZE% >> %INIFILE%
      IF NOT "%SCLTYPE_UP%"=="" (
        ECHO SCLTYPE_UP=%SCLTYPE_UP% >> %INIFILE%
  
        IF NOT "%WEIGHFACTOR%"=="" (
          ECHO WEIGHFACTOR=%WEIGHFACTOR% >> %INIFILE%
        )
        IF NOT "%PERCENTILE%"=="" (
          ECHO PERCENTILE=%PERCENTILE% >> %INIFILE%
        )
      )
      IF NOT "%SCLTYPE_DOWN%"=="" (
        ECHO SCLTYPE_DOWN=%SCLTYPE_DOWN% >> %INIFILE%
  
        IF NOT "%BLOCK%"=="" (
          ECHO BLOCK=%BLOCK% >> %INIFILE%
        )
      )
      IF NOT "%WINDOW%"=="" (
        ECHO WINDOW=%WINDOW: =,% >> %INIFILE%
      )
      ECHO SOURCEIDF='%SOURCEPATH%\!IDFFILENAME!' >> %INIFILE%
      ECHO OUTFILE='%RESULTPATH%\!TARGETFILENAME!' >> %INIFILE%
  
      IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
        REM Remove previous result 
        IF EXIST "%RESULTPATH%\!TARGETFILENAME!" (
          ECHO "%DEL2BINEXE%" /E /F "%RESULTPATH%\!TARGETFILENAME!" >> %LOGFILE%
          "%DEL2BINEXE%" /E /F "%RESULTPATH%\!TARGETFILENAME!" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
      ) ELSE (
        IF NOT DEFINED DEL2BINNOTFOUND (
          ECHO Note: previous results not removed, Del2Bin.exe not found: !DEL2BINEXE:%ROOTPATH%\=!
          ECHO Note: previous results not removed, Del2Bin.exe not found: !DEL2BINEXE:%ROOTPATH%\=! >> %LOGFILE%
        )  
        SET DEL2BINNOTFOUND=1
      )

      ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
      "%IMODEXE%" %INIFILE% >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
      IF NOT EXIST "%RESULTPATH%\!TARGETFILENAME!" (
        ECHO ERROR: %RESULTPATH%\!TARGETFILENAME! has not been created!
        ECHO ERROR: %RESULTPATH%\!TARGETFILENAME! has not been created! >> %LOGFILE%
        GOTO error
      ) 
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO   copying !TARGETSUBPATH!!TARGETFILENAME! !MSGPOSTFIX!...
      ECHO   copying !TARGETSUBPATH!!TARGETFILENAME! !MSGPOSTFIX!... >> %LOGFILE%
      ECHO COPY /Y "%SOURCEPATH%\!IDFFILENAME!" "%RESULTPATH%\!TARGETFILENAME!" >> %LOGFILE%
      COPY /Y "%SOURCEPATH%\!IDFFILENAME!" "%RESULTPATH%\!TARGETFILENAME!" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  )
  
  IF "%ISCOPYOTHER%"=="1" (
    ECHO Copying other files (non-IDF^) recursively ...
    FOR %%G IN ("%SOURCEPATH%\*") DO (
      SET FILEEXT=%%~xG
      IF /I NOT "!FILEEXT!"==".IDF" (
        SET FILENAME=%%~nxG
        SET FULLFILENAME=%%G
        SET FILEPATH=%%~dpG
        SET TARGETSUBPATH=!FILEPATH:%SOURCEPATH%=!
        SET TARGETSUBPATH=!TARGETSUBPATH:~1!
        SET TARGETPATH=!FILEPATH:%SOURCEPATH%=%RESULTPATH%!
        SET TARGETPATH=!TARGETPATH:~0,-1!
        IF NOT EXIST "!TARGETPATH!" MKDIR "!TARGETPATH!"
        ECHO   Copying !TARGETSUBPATH!!FILENAME! ...
        ECHO   Copying !TARGETSUBPATH!!FILENAME! ... >> %LOGFILE%
        ECHO COPY /Y "!FULLFILENAME!" "!TARGETPATH!" >> %LOGFILE%
        COPY /Y "!FULLFILENAME!" "!TARGETPATH!" >> %LOGFILE%
      )
    )
  )
)
IF EXIST %INIFILE% DEL %INIFILE%

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

REM FUNCTION: Check if specified extents are equal. To use: "CALL :ISEQUALEXTENT <EXTENT1> <EXTENT2> with EXTENT1/EXTENT2 in the form "XLL,YLL,XUR,YUR"
REM Return values: environment variable ISEQUALEXTENT is set to 1 if extents are equal, 0 if different
REM                ERRORLEVEL is set to 1 in case of an error
:ISEQUALEXTENT
  REM Remove possible double quotes
  SET EXTENT1=%~1
  SET EXTENT2=%~2
  IF NOT DEFINED EXTENT1 (
    ECHO EXTENT1 is not defined
    EXIT /B 1
  )
  IF NOT DEFINED EXTENT2 (
    ECHO EXTENT2 is not defined
    EXIT /B 1
  )

  FOR /F "tokens=1,2,3* delims=," %%a IN ("%EXTENT1%") DO (
    SET CLIPXLL1=%%a
    SET CLIPYLL1=%%b
    SET CLIPXUR1=%%c
    SET CLIPYUR1=%%d
  ) 
  FOR /F "tokens=1,2,3* delims=," %%a IN ("%EXTENT2%") DO (
    SET CLIPXLL2=%%a
    SET CLIPYLL2=%%b
    SET CLIPXUR2=%%c
    SET CLIPYUR2=%%d
  ) 
  SET /A XLLSUM=CLIPXLL1 - CLIPXLL2
  SET /A YLLSUM=CLIPYLL1 - CLIPYLL2
  SET /A XURSUM=CLIPXUR1 - CLIPXUR2
  SET /A YURSUM=CLIPYUR1 - CLIPYUR2

  SET ISEQUALEXTENT=1
  IF !XLLSUM! NEQ 0 SET ISEQUALEXTENT=0
  IF !YLLSUM! NEQ 0 SET ISEQUALEXTENT=0
  IF !XURSUM! NEQ 0 SET ISEQUALEXTENT=0
  IF !YURSUM! NEQ 0 SET ISEQUALEXTENT=0
  
  EXIT /B 0

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
  IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
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
