@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * SHP2GEN.bat                            *
REM * DESCRIPTION                            *
REM *   Converts shapefile(s) to GEN-file(s) *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2018-05-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SHPPATH:     Path to shapefiles
REM SHPFILTER:   Filter for shapefiles to convert (wildcards * and ? allowed), e.g. *.shp
REM EXTENT:      Extent (llx,lly,urx,ury) or leave empty
REM ISRECURSIVE: Specify (wih value 1) that subdirectories of input path should be processed recursively 
REM ISIDRENUM:   Specify (wih value 1) that IDs should be renumbered with integer values (i.e. to fix duplicates IDs)
REM ISIDCHECKED: Specify (wih value 1) that an  error should be thrown on duplicate IDs in GEN or DAT-file, otherwise duplicates are allowed in GEN-files, and for DAT-files rows with duplicate IDs are ignored
REM RESULTPATH:  Result path for GEN-files
SET SHPPATH=shapes
SET SHPFILTER=*.shp
SET EXTENT=
SET ISRECURSIVE=0
SET ISIDRENUM=0
SET ISIDCHECKED=0
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Converting shapefile(s^) '%SHPFILTER%' to GEN-file ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
SET EXTENTOPTION=
SET RECURSEOPTION=
SET IDFIXOPTION=
SET IDCHECKOPTION=
IF NOT "%EXTENT%" == "" SET EXTENTOPTION=/c:%EXTENT%
IF "%ISRECURSIVE%"=="1" SET RECURSEOPTION=/r
IF "%ISIDRENUM%"=="1" SET IDFIXOPTION=/f
IF "%ISIDCHECKED%"=="1" SET IDCHECKOPTION=/c
ECHO "GENSHPconvert.exe" %EXTENTOPTION% %RECURSEOPTION% %IDFIXOPTION% %IDCHECKOPTION% "%SHPPATH%" "%SHPFILTER%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\GENSHPconvert.exe" %EXTENTOPTION% %IDFIXOPTION% %RECURSEOPTION% %IDCHECKOPTION% "%SHPPATH%" "%SHPFILTER%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

ECHO: 
ECHO: >> %LOGFILE%

:success
ECHO:
ECHO: >> %LOGFILE%
SET MSG=Script finished, see '%~n0.log'
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
