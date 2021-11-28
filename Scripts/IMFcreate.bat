@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM * Version 1.1.0 December 2020            *
REM *                                        *
REM * IMFcreate.bat                          *
REM * DESCRIPTION                            * 
REM *   Creates IMF-file for REGIS-, and     *
REM *   layermodel files                     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2017-06-20 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM Note: an IMF-file is created with an INI definition file. See below for syntax and all possibilities.
REM       an existing INI-file can be used by setting CREATEINI=0, otherwise a new INI-file is created with the settings below. 
REM       the GEN-files as defined in the Sweco.iMOD.settings.bat file.
REM CREATEINI:       Use value 1 to create a new INI-file with settings below, or 0 or empty to use the current INI-file named %SCRIPTNAME%.INI
REM REGISPATH:       Path to REGIS IDF-files, or leave empty when no REGIS-files have to be used for IMF
REM REGISORDER:      Path to textfile with ordered REGIS prefixes in seperate lines (with a single prefix or multiple comma seperated values, with the prefix as the last value), or leave empty to use standard REGIS-order
REM REGISCOLORS:     Either TNO (for TNO REGIS-colors), AQF (or empty, for yellow/green colors for aquifers,aquitards) or a path to an Excelsheet with colordefinitions for IDF-files
REM MODELTOPBOTPATH: One or more (';' seperated) directories with modellayer TOP/BOT IDF-files to show as planes, or leave empty to skip
REM MODELLINESCOLOR: RGB colors for TOP- and BOT-lines seperated by a semicolon (e.g. 225,0,0;175,0,0) or leave empty
REM IMODFILES:       Comma seperated list of iMOD-files (or path with filter) to be added before REGIS-files. Use double quotes around filenames with spaces.
REM IMODLEGENDS:     Comma seperated list of iMOD-legends for one or more of the IDF-files/paths. The last legend is used for remaining IMODFILES. Use double quotes around filenames with spaces. Use "" to skip legend.
REM FILESELECTIONS:  Comma seperated list of 0/1-values to specified if iMOD-file/path should be selected/highlighted in IMF-file
REM EXTENT:          Extent of the IMF-file datafiles (llx,lly,urx,ury or llx lly urx ury)
REM ISADDCDTOIMF:    Use value 1 to add the name of the current subdirectory to the IMF-file
REM ISOPENIMOD:      Specify with value 1 if iMOD should be opened, use 0 otherwise
REM RESULTPATH:      Result path for IMF-file
REM IMFFILENAME:     Specify result filename for IMF-file
SET CREATEINI=1
SET REGISPATH=%ROOTPATH%\BASISDATA\REGIS\REGIS
SET REGISORDER=
SET REGISCOLORS=TNO
SET MODELTOPBOTPATHS=%DBASEPATH%\ORG\lagenmodel
SET MODELLINESCOLOR=25,25,25;100,100,100
SET IMODFILES="%DBASEPATH%\ORG\MODELGRENZEN\IBOUND_L1.IDF","%DBASEPATH%\ORG\maaiveld\mv_mipwa31_100x100.IDF"
SET IMODLEGENDS="%LEGENDPATH%\BND.leg","%LEGENDPATH%\MAAIVELD.leg"
SET FILESELECTIONS=1
SET EXTENT=%MODELEXTENT%
SET ISADDCDTOIMF=0
SET ISOPENIMOD=1
SET RESULTPATH=%IMFILESPATH%
SET IMFFILENAME=RESISII2_TNO-legend.IMF

REM IMODEXE:         path to iMOD-executable, or use %IMODEXE% to refer to iMOD-executable as defined in Sweco.iMOD.settings.bat
REM IMFCREATEEXE:    path to IMFcreate-executable
SET IMODEXE=%IMODEXE%
SET IMFCREATEEXE=%TOOLSPATH%\IMFcreate.exe

REM Note: GENFILEi, GENCOLOURi and GENTHICKNESSi for i=1 to 4 are read from %SETTINGSPATH%\Sweco.iMOD.settings.bat if existing, otherwise defined here
REM GENFILEi:      Path to GEN-file i
REM GENCOLOURi:    RGB-color for GEN-line i as r,g,b
REM GENTHICKNESSi: Linetichkess for GEN-line i as an integer value, starting with 1
IF NOT DEFINED GENFILE1 SET GENFILE1=
IF NOT DEFINED GENCOLOUR1 SET GENCOLOUR1=
IF NOT DEFINED GENTHICKNESS1 SET GENTHICKNESS1=

REM INI-file syntax
REM ---------------
REM The INI-file is divided into sections. A section is started with a keyword between brackets '[]'.
REM Each section consists of lines with key-value pairs seperated by an '=' symbol. The following sections are available:
REM 
REM [PARAMETERS]                    Mandatory section/keys that define general settings
REM EXTENT=minx,miny,maxx,maxy      This defines the extent at which the IMF file will open
REM OPENIMOD=<0|1>                  To open IMOD with created IMF choose 1, otherwise 0
REM IMFFILENAME=<filename>          Define a filename for the IMF file
REM IMODEXE=<filename>              Define the path to the iMOD executable for opening the IMF
REM 
REM [CROSSSECTION]                  Optional section/keys that define files/settings for 2D cross section tool
REM REGIS=<path>                    Define directory of REGIS IDF-files to load
REM REGISCOLORS=TNO|AQF|<filename>  Define Excel filename (XSLX) with colors per REGIS-layer with header in row 1 and
REM                                 rows with REGIS (sub)strings in column 1 and RGB (integer) values in columns 2 to 4
REM                                 Or use 'TNO' for TNO REGIS-colors, or 'AQF' for yellow/green hues for aquifer/aquitards
REM LAYERSASLINES=<paths>           Define one or more (';' seperated) directories with TOP/BOT IDF-files to show as lines
REM LINECOLOR=r1,g1,b1[;r2,g2;b2]   Define RGB (integer values) for color of TOP/BOT-line. As a default red hues are used
REM LAYERSASPLANES=<paths>          Define one or more (';' seperated) directories with TOP/BOT IDF-files to show as planes
REM                                 Colors are defined automatically with yellow for aquifers, green for aquitards
REM 
REM [MAPS]                          Optional section/keys that define paths/settings for map iMOD-files
REM FILE=<filename>                 For each iMOD-file specify the filename on a line and then specify optional settings
REM                                 If the file type is equal to type of previous file, the same settings are used
REM For IDF-files, the following optional keys are available to define settings:
REM LEGEND=<filename>               Define path of an iMOD legend (.LEG) file
REM SELECTED=<0|1>                  Use 1 to select the IDF-file, 0 if otherwise. Default is 0
REM LINECOLOR=r,g,b                 Define RGB color (integer values) for a line in the crosssection tool
REM FILLCOLOR=r,g,b                 Define RGB color (integer values) for a plane in the crosssection tool
REM 
REM For GEN-files, the following optional keys are available to define settings:
REM THICKNESS=<integer>             Define thickness of line as integer
REM REM COLOR=r,g,b                     Define RGB (3 integer values) for color of GEN-line
REM SELECTED=<0|1>                  Use 1 to select the GEN-file, 0 if otherwise. Default is 0
REM 
REM For IPF-files, the following optional keys are available to define settings:
REM LEGEND=<filename>               Define path of legend
REM COLUMN=<integer>                Define columnnumber to apply legend to, legend should be also specified
REM SELECTED=<0|1>                  Use 1 to select the IPF-file, 0 if otherwise. Default is 0
REM 
REM [OVERLAYS]                      Optional section/keys that define overlay GEN-files
REM For GEN-files, the following optional keys are available to define settings:
REM THICKNESS=<integer>             Define thickness of line as integer
REM COLOR=r,g,b                     Define RGB color (integer values) of GEN-line

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET THISPATH=%~dp0
SET TEMPDIR=TMP

REM ******************
REM * scriptcommands *
REM ******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Append current directoryname to IMF-filename
IF "%ISADDCDTOIMF%"=="1" (
  FOR %%I IN (.) DO SET DIRNAME=%%~nxI
  SET IMFFILENAME=%IMFFILENAME%_!DIRNAME: =_!.IMF
)

IF "%RESULTPATH%"=="" (
  ECHO RESULTPATH cannot be empty^^!
  ECHO RESULTPATH cannot be empty^^! >> %LOGFILE%
  GOTO error
)

REM Create arrays for IMODFILES and IMODLEGENDS input and check for equal lengths
REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
SET ASTERISK_TMP=$
SET IMODFILES_TMP=%IMODFILES:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!IMODFILES_TMP:~%IDX%,1!"=="*" SET IMODFILES_TMP=!IMODFILES_TMP:~0,%IDX%!%ASTERISK_TMP%!IMODFILES_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF NOT "!IMODFILES_TMP:~%IDX%,1!"=="" GOTO :loop1
SET Ni=0
FOR %%a in (%IMODFILES_TMP%) do (
  SET IMODFILES_ARR[!Ni!]=%%a
  SET /A Ni=Ni+1
)
SET Nl=0
FOR %%D in (%IMODLEGENDS%) DO (
  SET IMODLEGENDS_ARR[!Nl!]=%%D
  SET /A Nl=Nl+1
)
SET Ns=0
FOR %%A in (%FILESELECTIONS%) DO (
  SET FILESELECTIONS_ARR[!Ns!]=%%A
  SET /A Ns=Ns+1
)
IF %Ni% LSS %Nl% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of IMODLEGENDS (%Nl%^)
  GOTO error
)
IF %Ni% LSS %Ns% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of FILESELECTIONS (%Ns%^)
  GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

IF "%CREATEINI%"=="1" ( 
  SET MSG=  creating INI-file %SCRIPTNAME% ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  REM Create INI-file
  ECHO [PARAMETERS] > %INIFILE%
  ECHO EXTENT=%EXTENT% >> %INIFILE%
  ECHO OPENIMOD=%ISOPENIMOD% >> %INIFILE%
  ECHO IMFFILENAME=%RESULTPATH%\%IMFFILENAME:.IMF=%>> %INIFILE%
  ECHO IMODEXE=%iMODEXE% >> %INIFILE%
  ECHO: >> %INIFILE%

  IF !Ni! GTR 0 (
    ECHO [MAPS] >> %INIFILE%
    SET /A Ni=!Ni!-1
    SET /A Nl=!Nl!-1
    FOR /L %%i IN (0,1,!Ni!) DO (
      SET IMODFILE_TMP=!IMODFILES_ARR[%%i]:"=!
      REM Replace temporary wildcard symbols again
      SET IMODFILE=!IMODFILE_TMP:@=?!
      SET IMODFILE=!IMODFILE:$=*!

      IF NOT EXIST "!IMODFILE!" (
        ECHO   WARNING: IDF-file not found: !IMODFILE!
        ECHO   WARNING: IDF-file not found: !IMODFILE! >> %LOGFILE%
      ) ELSE (
        ECHO FILE=!IMODFILE! >> %INIFILE%
      )

      REM Add legend file if specified
      IF %%i LEQ !Nl! (
        SET IMODLEGEND=!IMODLEGENDS_ARR[%%i]:"=!
        IF NOT "!IMODLEGEND!"=="" (
          IF NOT EXIST "!IMODLEGEND!" (
            ECHO LEGEND-file not found: !IMODLEGEND!
            ECHO LEGEND-file not found: !IMODLEGEND! >> %LOGFILE%
            GOTO error
          )
          ECHO LEGEND=!IMODLEGEND! >> %INIFILE%
        )
      )

      REM Add selection keyword if specified
      IF %%i LEQ !Ns! (
        SET FILESELECTION=!FILESELECTIONS_ARR[%%i]!
        IF "!FILESELECTION!"=="1" (
          ECHO SELECTED=1 >> %INIFILE%
        ) ELSE (
          ECHO SELECTED=0 >> %INIFILE%
        )
      )
    )
    ECHO: >> %INIFILE%
  )

  ECHO [CROSSSECTION] >> %INIFILE%
  IF NOT "%REGISPATH%"=="" (
    ECHO REGIS=%REGISPATH% >> %INIFILE%
    IF NOT "%REGISORDER%"=="" ECHO REGISORDER=%REGISORDER% >> %INIFILE%
    IF NOT "%REGISCOLORS%"=="" ECHO REGISCOLORS=%REGISCOLORS%>> %INIFILE%
    IF NOT "%MODELTOPBOTPATHS%"=="" (
      ECHO LAYERSASLINES=%MODELTOPBOTPATHS% >> %INIFILE%
      IF NOT "%MODELLINESCOLOR%"=="" ECHO LINECOLOR=%MODELLINESCOLOR% >> %INIFILE%
    )
  ) ELSE (
    IF NOT "%MODELTOPBOTPATHS%"=="" ECHO LAYERSASPLANES=%MODELTOPBOTPATHS% >> %INIFILE%
  )
  ECHO: >> %INIFILE%
 
  IF NOT "%GENFILE1%%GENFILE2%%GENFILE3%%GENFILE4%" == "" (
    ECHO [OVERLAYS] >> %INIFILE%
  )
  IF NOT "%GENFILE1%" == "" (
    ECHO %GENFILE1% >> %INIFILE%
    ECHO THICKNESS=%GENTHICKNESS1% >> %INIFILE%
    ECHO COLOR=%GENCOLOR1% >> %INIFILE%
  )
  IF NOT "%GENFILE2%" == "" (
    ECHO %GENFILE2% >> %INIFILE%
    ECHO THICKNESS=%GENTHICKNESS2% >> %INIFILE%
    ECHO COLOR=%GENCOLOR2% >> %INIFILE%
  )
  IF NOT "%GENFILE3%" == "" (
    ECHO %GENFILE3% >> %INIFILE%
    ECHO THICKNESS=%GENTHICKNESS3% >> %INIFILE%
    ECHO COLOR=%GENCOLOR3% >> %INIFILE%
  )
  IF NOT "%GENFILE4%" == "" (
    ECHO %GENFILE4% >> %INIFILE%
    ECHO THICKNESS=%GENTHICKNESS4% >> %INIFILE%
    ECHO COLOR=%GENCOLOR4% >> %INIFILE%
  )
  IF NOT "%GENFILE1%%GENFILE2%%GENFILE3%%GENFILE4%" == "" (
    ECHO:	 >> %INIFILE%
  )
)

ECHO   starting IMFcreate ...
ECHO "%TOOLSPATH%\IMFcreate.exe" %INIFILE% "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IMFcreate.exe" %INIFILE% "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

:success
SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
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
