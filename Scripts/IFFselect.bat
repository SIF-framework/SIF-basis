@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * IFFselect.bat                           *
REM * DESCRIPTION                             *
REM *    Selects IFF-pathlines inside/outside *
REM *    specified volume and/or period       *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2018-09-01 Initial version            *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IFFFILE: Input IFF-file
REM Specify clip/select-volume with a combination of GEN-file, Extent, TOP/BOT-level and/or traveltime
REM GENFILE:  GEN-file for definition of clip/select-volume, or leave empty
REM TOPLEVEL: TOP-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
REM BOTLEVEL: BOT-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
REM EXTENT:   Extent (xll,yll,xur,yur) for definition of clip/select-volume, or leave empty
REM TRAVELTIMEREVERSE: Specify if traveltime should be reversed before selection (use 1), after selection (use 2), or leave empty
REM MINTRAVELTIME:     Minimum traveltime in years
REM MAXTRAVELTIME:     Maximum traveltime in years
REM MINVELOCITY:       Minimum velocity in m/d
REM MAXVELOCITY:       Maximum velocity in m/d
REM Specify clip OR selection method (use value 1 to select one method, default is clip)
REM CLIPMETHOD: Clip IFF-pathlines as defined by the selection volume and c1 parameter:
REM             0) select all pathlines
REM             1) select only pathlines inside the specified volume (clip, the default)
REM             2) select only pathlines outside the specified volume (inverse clip)
REM             3) select only pathlines before the specified volume (start to just inside)
REM             4) select only pathlines before and inside the specified volume (start to inside)
REM Point selection: instead of clipping flowlines, select whole pathline as specified by s1 and s2:
REM SELECTTYPE: specifies the IFF-point type used for selection:. 
REM             1) evaluate only IFF-points that start inside/outside the specified volume
REM             2) evaluate only IFF-points, that pass through/outside the specified volume (midpoints)
REM             3) evaluate only IFF-points that end inside/outside the specified volume
REM             4) evaluate all IFF-points
REM SELECTTYPE: specifies the selection method or constraint (and may be left empty for the default):
REM             1) evaluate only specified IFF-points inside the specified volume (the default)
REM             2) evaluate only specified IFF-points outside the specified volume
REM         If one IFF-point is inside/outside the specified volume, the whole pathline is selected (!):
REM RESULTPATH: Result path or filename output IFF-file. If no filename is specified the source name with postfix _sel is used.
REM POSTFIX:    Optional postfix to add to outputfilenames    
SET IFFFILE=postprocessing\REF3_BAS_FW_HEAD_L1.IFF
SET GENFILE=%SHAPESPATH%\Oppervlaktewater\PlasX.GEN
SET TOPLEVEL=%DBASEPATH%\ORG\TOP\TOP_L1.IDF
SET BOTLEVEL=%DBASEPATH%\ORG\BOT\BOT_L3.IDF
SET EXTENT=
SET TRAVELTIMEREVERSE=
SET MINTRAVELTIME=0
SET MAXTRAVELTIME=15
SET MINVELOCITY=
SET MAXVELOCITY=
SET CLIPMETHOD=3
SET SELECTTYPE=
SET SELECTTYPE=
SET RESULTPATH=postprocessing
SET POSTFIX=_sel

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL ENABLEDELAYEDEXPANSION

TITLE SIF-basis: %SCRIPTNAME%

REM Build option strings
SET EXTENTOPTION=
SET GENFILEOPTION=
SET LEVELOPTION=
SET TIMEOPTION=
SET METHODOPTION=
SET REVERSEOPTION=
SET PFOPTION=
IF NOT "%EXTENT%"=="" SET EXTENTOPTION=/e:%EXTENT%
IF NOT "%GENFILE%"=="" SET GENFILEOPTION=/p:%GENFILE%
IF NOT "%TOPLEVEL%"=="" (
  SET LEVELOPTION=/l:%TOPLEVEL%
  IF NOT "%BOTLEVEL%"=="" (
    SET LEVELOPTION=/l:"%TOPLEVEL%","%BOTLEVEL%"
  )
)
IF NOT "%TRAVELTIMEREVERSE%"=="" (
  SET REVERSEOPTION=/r:%TRAVELTIMEREVERSE%
)
IF NOT "%MINTRAVELTIME%"=="" (
  IF NOT "%MAXTRAVELTIME%"=="" (
    SET TIMEOPTION=/t:%MINTRAVELTIME%,%MAXTRAVELTIME%
  ) ELSE (
    ECHO Specify both min- and max traveltime
    GOTO error
  )
) 
IF NOT "%MINVELOCITY%"=="" (
  IF NOT "%MAXVELOCITY%"=="" (
    SET VELOCITYOPTION=/v:%MINVELOCITY%,%MAXVELOCITY%
  ) ELSE (
    ECHO Specify both min- and max velocity
    GOTO error
  )
) 
IF NOT "%CLIPMETHOD%" == "" (
  SET METHODOPTION=/c:%CLIPMETHOD%
) ELSE (
  IF NOT "%SELECTTYPE%" == "" (
    SET METHODOPTION=/s:%SELECTTYPE%
    IF NOT "%SELECTTYPE%" == "" (
      SET METHODOPTION=/s:%SELECTTYPE%,%SELECTTYPE%
    )
  )
)
IF DEFINED POSTFIX SET PFOPTION=/pf:%PFOPTION%

SET MSG=Selecting pathlines ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO "%TOOLSPATH%\IFFselect.exe" %REVERSEOPTION% %METHODOPTION% %GENFILEOPTION% %LEVELOPTION% %EXTENTOPTION% %TIMEOPTION% %VELOCITYOPTION% %PFOPTION% "%IFFFILE%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IFFselect.exe" %REVERSEOPTION% %METHODOPTION% %GENFILEOPTION% %LEVELOPTION% %EXTENTOPTION% %TIMEOPTION% %VELOCITYOPTION% %PFOPTION% "%IFFFILE%" "%RESULTPATH%" >> %LOGFILE%
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
