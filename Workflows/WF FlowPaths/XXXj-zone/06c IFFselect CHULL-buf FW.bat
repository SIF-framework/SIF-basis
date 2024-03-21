@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * IFFselect.bat                           *
REM * DESCRIPTION                             * 
REM *    Selects IFF-pathlines inside/outside *
REM *    specified volume and/or period       *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.1                          *
REM * MODIFICATIONS                           *
REM *   2018-09-01 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ********************
REM * Description      *
REM ********************
REM The IFFselect-tool can select IFF-lines. There are basically to methods: 1) clip/select lineparts or 2) select lines that contain specific IFF-point
REM Both methods select IFF-lines relative to a specified volume. The volume can be defined by the combination of a GEN-file, an extent, a TOP- and BOT-level.
REM Method 1 can clip IFF-lines that are either inside the volume, outside the volume, start before the volume or start before or inside the volume
REM Method 2 can select complete IFF-lines that contain one or more IFF-points of the specified type inside (or outside) the volume. Possible types are startpoints, midpoints, endpoints or all points. 
REM Also IFF-line(parts) can be selected via a travel time range or a velocity range

REM ********************
REM * Script variables *
REM ********************
REM IFFPATH: Path to input IFF-file(s)
REM IFFFILE: Filter or filename for input IFF-file(s)
SET IFFPATH=%RESULTPATH_RUNS%\FW_CHULLBUFFER
SET IFFFILE=%MODELREF%_FW_CHULLBUFFER.IFF

REM Specify clip/select-volume with a combination of GEN-file, extent, TOP/BOT-level and/or traveltime
REM GENFILE:       GEN-file for definition of clip/select-volume, or leave empty
REM TOPLEVEL:      TOP-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
REM BOTLEVEL:      BOT-level IDF-file or values (floating point, english notation) for definition of clip/select-volume, or leave empty
REM EXTENT:        Extent (xll,yll,xur,yur) for definition of clip/select-volume, or leave empty
REM REVERSETIME:   Specify if traveltime should be reversed before selection (use 1), after selection (use 2), or leave empty to leave travel time as it is
REM MINTRAVELTIME: Minimum traveltime in years; note both MINTRAVELTIME and MAXTRAVELTIME have to be specified
REM MAXTRAVELTIME: Maximum traveltime in years
REM MINVELOCITY:   Minimum velocity in m/d; note both MINTRAVELTIME and MAXTRAVELTIME have to be specified
REM MAXVELOCITY:   Maximum traveltime in years
SET GENFILE=tmp\%SOURCE_IPFFILE:.IPF=%_RECT%FPFW_ISD_RECTSIZE%.GEN
SET TOPLEVEL=%FPFW_SEL_TOP%
SET BOTLEVEL=%FPFW_SEL_BOT%
SET EXTENT=
SET REVERSETIME=2
SET MINTRAVELTIME=0
SET MAXTRAVELTIME=%FPFW_SEL_MAXY%
SET MINVELOCITY=
SET MAXVELOCITY=

REM Specify etiher CLIPMETHOD or SELECTTYPE/SELECTMETHOD that defines the IFF-line to select, related to the specified volume
REM CLIPMETHOD:    Clip IFF-pathlines as defined by the selection volume and one of the following CLIPMETHOD values:
REM                  0) select all pathlines
REM                  1) select only pathlines inside the specified volume (clip, the default)
REM                  2) select only pathlines outside the specified volume (inverse clip)
REM                  3) select only pathlines before the specified volume (start to just inside)
REM                  4) select only pathlines before and inside the specified volume (start to inside)
REM Point selection: instead of clipping flowlines, select whole pathline as specified by SELECTTYPE and SELECTMETHOD:
REM SELECTTYPE:    Use location of IFF-point(s) to select IFF-lines. Specify one of the following IFF-point types (start, mid, end or all) used for selection:
REM                  1) evaluate only IFF-points that start inside/outside the specified volume
REM                  2) evaluate only IFF-points, that pass through/outside the specified volume (midpoints)
REM                  3) evaluate only IFF-points that end inside/outside the specified volume
REM                  4) evaluate all IFF-points
REM                Note: if one IFF-point is inside/outside the specified volume, the whole pathline is selected:
REM SELECTMETHOD: Specify the selection method or constraint for specified SELECTTYPE, or leave empty for default (1):
REM                  1) evaluate only specified IFF-points inside the specified volume (the default)
REM                  2) evaluate only specified IFF-points outside the specified volume
SET CLIPMETHOD=4
SET SELECTTYPE=
SET SELECTMETHOD=

REM RESULTPATH: Result path or filename output IFF-file. If no filename is specified the source name with postfix _sel is used.
REM POSTFIX:    Optional postfix to add to outputfilenames    
SET RESULTPATH=%RESULTPATH_ZONE%\%FLOWLINE_PREFIX%%TYPESTRING%_FW_%MODELREF%_%SOURCEABBR%.IFF
SET POSTFIX=

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

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF DEFINED CLIPMETHOD IF DEFINED SELECTTYPE (
  ECHO Specify either CLIPMETHOD or SELECTTYPE/SELECTMETHOD, not both^^!
  ECHO Specify either CLIPMETHOD or SELECTTYPE/SELECTMETHOD, not both^^! >> %LOGFILE%
  GOTO error
)

REM Build option strings
SET EXTENTOPTION=
SET GENFILEOPTION=
SET LEVELOPTION=
SET TOPTION=
SET METHODOPTION=
SET REVERSEOPTION=
SET PFOPTION=
IF NOT "%EXTENT%"=="" SET EXTENTOPTION=/e:%EXTENT%
IF NOT "%GENFILE%"=="" SET GENFILEOPTION=/p:%GENFILE%
IF NOT "%TOPLEVEL%%BOTLEVEL%"=="" SET LEVELOPTION=/l:"%TOPLEVEL%","%BOTLEVEL%"
IF DEFINED REVERSETIME SET REVERSEOPTION=/r:%REVERSETIME%
IF NOT "%MINTRAVELTIME%%MAXTRAVELTIME%"=="" SET TOPTION=/t:%MINTRAVELTIME%,%MAXTRAVELTIME%
IF NOT "%MINVELOCITY%%MAXVELOCITY%"=="" SET VOPTION=/v:%MINVELOCITY%,%MAXVELOCITY%
IF DEFINED CLIPMETHOD (
  SET METHODOPTION=/c:%CLIPMETHOD%
) ELSE (
  IF DEFINED SELECTTYPE (
    IF DEFINED SELECTMETHOD (
      SET METHODOPTION=/s:%SELECTTYPE%,%SELECTMETHOD%
    ) ELSE (
      SET METHODOPTION=/s:%SELECTTYPE%
    )
  )
)
IF DEFINED POSTFIX SET PFOPTION=/pf:%PFOPTION%

SET MSG=Selecting pathlines ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%TOOLSPATH%\IFFselect.exe" %REVERSEOPTION% %METHODOPTION% %GENFILEOPTION% %LEVELOPTION% %EXTENTOPTION% %TOPTION% %VOPTION% %PFOPTION% "%IFFPATH%" "%IFFFILE%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IFFselect.exe" %REVERSEOPTION% %METHODOPTION% %GENFILEOPTION% %LEVELOPTION% %EXTENTOPTION% %TOPTION% %VOPTION% %PFOPTION% "%IFFPATH%" "%IFFFILE%" "%RESULTPATH%" >> %LOGFILE%
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
IF NOT DEFINED NOPAUSE PAUSE
