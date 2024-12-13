@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IMFcreate.bat                          *
REM * DESCRIPTION                            *
REM *   Creates IMF-file for REGIS-, and     *
REM *   layermodel files                     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.1.1                         *
REM * MODIFICATIONS                          *
REM *   2017-06-20 Initial version           *
REM ******************************************
CALL :Initialization
CALL :RetrieveModelReference

REM ********************
REM * Script variables *
REM ********************
REM Note: an IMF-file is created with an INI definition file. See below for syntax and all possibilities.
REM       an existing INI-file can be used by setting CREATEINI=0, otherwise a new INI-file is created with the settings below. 
REM CREATEINI: Use value 1 to create a new INI-file with settings below, or 0 or empty to use the current INI-file named %SCRIPTNAME%.INI
SET CREATEINI=1

REM Parameters of Map section1: part above REGIS/Modellayers
REM --------------------------------------------------------
REM Note: For modelreferences the following environment variables are available to use in defining paths: 
REM       - when a RUN/PRJ-file is present in the same folder: MODELREF, MODELREF1, MODELREF2 and MODELREF3
REM       - otherwise: MODELREF1, defined by the directoryname just below the WORKIN-folder
REM       Use empty string ("") to skip parameters for a Mapfile. 
REM IMODFILES:       Comma seperated list of iMOD-files (or path with filter) to be added before REGIS-files. Use double quotes around filenames with spaces.
REM IMODLEGENDS:     Comma seperated list of iMOD-legends for one or more of the IMODFILES. The last legend is used for remaining IMODFILES. Use double quotes around a filename with spaces. Use "" to skip legend.
REM IMODALIASES:     Comma seperated list of iMOD-alias definitions for one or more of the IMODFILES. The last alias is used for remaining IMODFILES. Use double quotes around an alias with spaces. Use "" to skip alias.
REM                  Currently each alias definition is used as prefix before the source filename, excluding extension; an underscore is added after the prefix.
REM CSLEGENDS:       Comma seperated list of DLF-legends for one or more of the IMODFILES. Use "" to skip for an IPF-file, or leave CSLEGENDS empty to skip completely.
REM FILESELECTIONS:  Comma seperated list of 0/1-values to specified if iMOD-file/path should be selected/highlighted in IMF-file
REM EXTRAPARLINES:   Comma seperated list (surround by double quotes) with extra parameter lines per Mapfile. Multiple parameter line can be specified by seperating with a semicolcon.
SET IMODFILES="%DBASEPATH%\%MODELREF1%\Maaiveld\MV_*.IDF","%DBASEPATH%\%MODELREF1%\KHV","%DBASEPATH%\%MODELREF1%\KVV"
SET IMODLEGENDS="%LEGENDPATH%\maaiveld_-10-100.leg","%LEGENDPATH%\kh-waarden.leg","%LEGENDPATH%\kv-waarden.leg"
SET IMODALIASES=BASISDATA,"%MODELREF1%",""
SET CSLEGENDS="","","%LEGENDPATH%\DLF\filter_legend.dlf"
SET FILESELECTIONS=0,1,0
SET EXTRAPARLINES="","COLUMN=15;TEXTSIZE=5;THICKNESS=2","COLOR=0,128,192"

REM Parameters of Cross section section: REGIS and/or Modellayers
REM -------------------------------------------------------------
REM REGISPATH:       Path to REGIS IDF-files, or leave empty when no REGIS-files have to be used for IMF
REM REGISORDER:      Path to textfile with ordered REGIS prefixes in seperate lines (with a single prefix or multiple comma seperated values, with the prefix as the last value), or leave empty to use standard REGIS-order
REM REGISCOLORS:     Either TNO (for TNO REGIS-colors), AQF (or empty, for yellow/green colors for aquifers,aquitards) or a path to an Excelsheet with colordefinitions for IDF-files
REM MODELTOPBOTPATH: One or more (';' seperated) directories with modellayer TOP/BOT IDF-files to show as planes, or leave empty to skip
REM MODELLINESCOLOR: RGB colors for TOP- and BOT-lines seperated by a semicolon (e.g. 225,0,0;175,0,0) or leave empty
SET REGISPATH=
SET REGISORDER=
SET REGISCOLORS=
SET MODELTOPBOTPATHS=%DBASEPATH%\BASIS1\TOP;%DBASEPATH%\BASIS1\BOT
SET MODELLINESCOLOR=25,25,25;100,100,100

REM Parameters of Map section2: part below REGIS/Modellayers
REM --------------------------------------------------------
REM IMODFILES2:      As IMODFILES, at bottom of Maplayer list, below REGIS- or TOP/BOT-files
REM IMODLEGENDS2:    As IMODLEGENDS, but for IMODFILES2
REM IMODALIASES2:    As IMODALIASES, but for IMODFILES2
REM CSLEGENDS2:      As CSLEGENDS, but for IMODFILES2
REM FILESELECTIONS2: As FILESELECTIONS, but for FILESELECTIONS2
REM EXTRAPARLINES2:  As EXTRAPARLINES, but for FILESELECTIONS2
SET IMODFILES2="%DBASEPATH%\%MODELREF1%\MAAIVELD\*.IDF","%RESULTSPATH%\%MODELREF:_=\%\head\*_L*.IDF"
SET IMODLEGENDS2="%LEGENDPATH%\maaiveld_stretched.leg","%LEGENDPATH%\maaiveld_stretched.leg"
SET IMODALIASES2=
SET CSLEGENDS2=
SET FILESELECTIONS2=0,0
SET EXTRAPARLINES2="","LINECOLOR=0,128,192;PRFTYPE=7"

REM Parameters of Overlay section, which contains background GEN-files
REM ------------------------------------------------------------------
REM GENFILES:       Comma seperated list of GEN-files (or path with filter) to be added to overlay section. Use double quotes around filenames with spaces.
REM GENCOLORS:      Semicolon (';') seperated list of RGBcolors, each RGB-color seperated by commas (r,g,b), for each of the GEN-files. E.g. 0,0,0;200,100,0
REM GENTHICKNESSES: Comma seperated list of line thicknesses for each of the GEN-files.
REM GENSELECTIONS:  Comma seperated list of 0/1-values to specified if GEN-file(s) should be selected in IMF-file
SET GENFILES="%GENFILE1%","%GENFILE2%","%GENFILE3%","%GENFILE4%","%GENFILE5%","%BASISDATAPATH%\Breuken\*.GEN"
SET GENCOLORS=%GENCOLOR1%;%GENCOLOR2%;%GENCOLOR3%;%GENCOLOR4%;%GENCOLOR5%;0,0,0
SET GENTHICKNESSES=%GENTHICKNESS1%,%GENTHICKNESS2%,%GENTHICKNESS3%,%GENTHICKNESS4%,%GENTHICKNESS5%,2
SET GENSELECTIONS=1,1,1,1,1,0

REM General parameters that define resulttype
REM -----------------------------------------
REM EXTENT:          Extent of the IMF-file datafiles (llx,lly,urx,ury or llx lly urx ury)
REM ISADDCDTOIMF:    Use value 1 to add the name of the current subdirectory to the IMF-file
REM ISOPENIMOD:      Specify with value 1 if iMOD should be opened, use 0 otherwise
REM RESULTPATH:      Result path for IMF-file
REM IMFFILENAME:     Specify result filename for IMF-file (including .IMF extension)
REM ISLINKCREATED: Specify (with value 1) if link to resulting IMF-file location should be created
SET EXTENT=%MODELEXTENT%
SET ISADDCDTOIMF=0
SET ISOPENIMOD=1
SET RESULTPATH=%IMFILESPATH%
SET IMFFILENAME=%MODELREF% - modelresults.IMF
SET ISLINKCREATED=1

REM IMODEXE:         path to iMOD-executable, or use %IMODEXE% to refer to iMOD-executable as defined in Sweco.iMOD.settings.bat
REM IMFCREATEEXE:    path to IMFcreate-executable
SET IMODEXE=%IMODEXE%
SET IMFCREATEEXE=%TOOLSPATH%\IMFcreate.exe

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
REM ALIAS=<aliasdefinition>         Defines an alias that can be shown in iMOD as an alternative for the filename;
REM                                 Currently <aliasdefinition> is used as prefix before the source filename, excluding extension; an underscore is added after the prefix
REM CSLEGEND=<filename>             Define path of an iMOD Drill File Legend (.DLF) file to visualizee file in cross sections
REM SELECTED=<0|1>                  Use 1 to select the IDF-file, 0 if otherwise. Default is 0
REM LINECOLOR=r,g,b                 Define RGB color (integer values) for a line in the crosssection tool
REM FILLCOLOR=r,g,b                 Define RGB color (integer values) for a plane in the crosssection tool
REM PRFTYPE=<integer>               Define PRF-type as a combination of indidual values: 1=Active, 3=Line, 4=Points, 8=Fill, 64=Legend
REM 
REM For GEN-files, the following optional keys are available to define settings:
REM THICKNESS=<integer>             Define thickness of line as integer
REM REM COLOR=r,g,b                 Define RGB (3 integer values) for color of GEN-line
REM SELECTED=<0|1>                  Use 1 to select the GEN-file, 0 if otherwise. Default is 0
REM 
REM For IPF-files, the following optional keys are available to define settings:
REM LEGEND=<filename>               Define path of legend
REM COLUMN=<integer>                Define columnnumber (one-based) to apply legend to, legend should be also specified
REM TEXTSIZE=<integer>              Define size of labelled text as an integer (use 0 to hide text)
REM COLOR=r,g,b                     Define RGB (3 integer values) for color of GEN-line
REM THICKNESS=<integer>             Define thickness of line as integer
REM PRFTYPE=<integer>               Define PRF-type as a combination of indidual values: 1=Active, 2=Ass.File, 64=Legend
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

SET MSG=Starting script '%SCRIPTNAME%' ...
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

REM As a default do not open iMOD
IF NOT DEFINED ISOPENIMOD SET ISOPENIMOD=0

REM Create arrays for IMODFILES, IMODLEGENDS, IMODALIASES and other input and check for equal lengths
SET MSG=  parsing settings ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Use workaround for wildcard symbols in list items of iMODFILES (? becomes @, and * becomes $)
REM Replace per character: first replace rootpath of filenames, to reduce number of iterations.
SET ASTERISK_TMP=$
IF DEFINED IMODFILES SET IMODFILES_TMP=!IMODFILES:%ROOTPATH%=###!
IF DEFINED IMODFILES SET IMODFILES_TMP=%IMODFILES_TMP:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!IMODFILES_TMP:~%IDX%,1!"=="*" SET IMODFILES_TMP=!IMODFILES_TMP:~0,%IDX%!%ASTERISK_TMP%!IMODFILES_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF DEFINED IMODFILES_TMP IF NOT "!IMODFILES_TMP:~%IDX%,1!"=="" GOTO :loop1
SET Ni=0
FOR %%a IN (%IMODFILES_TMP%) DO (
  SET IMODFILE=%%a
  SET IMODFILE=!IMODFILE:"=!
  IF "!IMODFILE:~0,3!"=="###" SET IMODFILE=%ROOTPATH%!IMODFILE:~3!
  SET IMODFILES_ARR[!Ni!]=!IMODFILE!
  SET /A Ni=Ni+1
)
SET Nl=0
FOR %%D IN (%IMODLEGENDS%) DO (
  SET IMODLEGENDS_ARR[!Nl!]=%%D
  SET /A Nl=Nl+1
)
SET Na=0
FOR %%D IN (%IMODALIASES%) DO (
  SET ALIAS_ARR[!Na!]=%%D
  SET /A Na=Na+1
)
SET Nd=0
FOR %%D IN (%CSLEGENDS%) DO (
  SET CSLEGENDS_ARR[!Nd!]=%%D
  SET /A Nd=Nd+1
)
SET Ns=0
FOR %%A IN (%FILESELECTIONS%) DO (
  SET FILESELECTIONS_ARR[!Ns!]=%%A
  SET /A Ns=Ns+1
)
SET Ne=0
FOR %%A IN (%EXTRAPARLINES%) DO (
  SET EXTRAPARLINES_ARR[!Ne!]=%%A
  SET /A Ne=Ne+1
)
IF %Ni% LSS %Nl% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of IMODLEGENDS (%Nl%^)
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of IMODLEGENDS (%Nl%^) >> %LOGFILE%
  GOTO error
)
IF %Ni% LSS %Na% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of IMODALIASES (%Na%^)
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of IMODALIASES (%Na%^) >> %LOGFILE%
  GOTO error
)
IF %Ni% LSS %Ns% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of FILESELECTIONS (%Ns%^)
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of FILESELECTIONS (%Ns%^) >> %LOGFILE%
  GOTO error
)
IF %Ni% LSS %Nd% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of CSLEGENDS (%Nd%^)
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of CSLEGENDS (%Nd%^) >> %LOGFILE%
 GOTO error
)
IF %Ni% LSS %Ne% (
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of EXTRAPARLINES (%Ne%^)
  ECHO Ensure that number of IMODFILES (%Ni%^) is greater than or equal to number of EXTRAPARLINES (%Ne%^) >> %LOGFILE%
  GOTO error
)

REM Create arrays for IMODFILES2 and IMODLEGENDS2 input and check for equal lengths
REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
IF DEFINED IMODFILES2 SET IMODFILES2_TMP=!IMODFILES2:%ROOTPATH%=###!
IF DEFINED IMODFILES2 SET IMODFILES2_TMP=%IMODFILES2_TMP:?=@%
SET IDX=0
:loop2
    SET /A plusone=%IDX%+1
    IF "!IMODFILES2_TMP:~%IDX%,1!"=="*" SET IMODFILES2_TMP=!IMODFILES2_TMP:~0,%IDX%!%ASTERISK_TMP%!IMODFILES2_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF DEFINED IMODFILES2_TMP IF NOT "!IMODFILES2_TMP:~%IDX%,1!"=="" GOTO :loop2
SET Ni2=0
FOR %%a IN (%IMODFILES2_TMP%) DO (
  SET IMODFILE=%%a
  SET IMODFILE=!IMODFILE:"=!
  IF "!IMODFILE:~0,3!"=="###" SET IMODFILE=%ROOTPATH%!IMODFILE:~3!
  SET IMODFILES2_ARR[!Ni2!]=!IMODFILE!
  SET /A Ni2=Ni2+1
)
SET Nl2=0
FOR %%D IN (%IMODLEGENDS2%) DO (
  SET IMODLEGENDS2_ARR[!Nl2!]=%%D
  SET /A Nl2=Nl2+1
)
SET Na2=0
FOR %%D IN (%IMODALIASES2%) DO (
  SET ALIAS2_ARR[!Na2!]=%%D
  SET /A Na2=Na2+1
)
SET Ns2=0
FOR %%A IN (%FILESELECTIONS2%) DO (
  SET FILESELECTIONS2_ARR[!Ns2!]=%%A
  SET /A Ns2=Ns2+1
)
SET Nd2=0
FOR %%D IN (%CSLEGENDS2%) DO (
  SET CSLEGENDS2_ARR[!Nd2!]=%%D
  SET /A Nd2=Nd2+1
)
SET Ne2=0
FOR %%A IN (%EXTRAPARLINES2%) DO (
  SET EXTRAPARLINES2_ARR[!Ne2!]=%%A
  SET /A Ne2=Ne2+1
)
IF %Ni2% LSS %Nl2% (
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of IMODLEGENDS2 (%Nl2%^)
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of IMODLEGENDS2 (%Nl2%^) >> %LOGFILE%
  GOTO error
)
IF %Ni% LSS %Na2% (
  ECHO Ensure that number of IMODFILES (%Ni2%^) is greater than or equal to number of IMODALIASES2 (%Na2%^)
  ECHO Ensure that number of IMODFILES (%Ni2%^) is greater than or equal to number of IMODALIASES2 (%Na2%^) >> %LOGFILE%
  GOTO error
)
IF %Ni2% LSS %Ns2% (
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of FILESELECTIONS2 (%Ns2%^)
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of FILESELECTIONS2 (%Ns2%^) >> %LOGFILE%
  GOTO error
)
IF %Ni2% LSS %Nd2% (
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of CSLEGENDS2 (%Nd2%^)
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of CSLEGENDS2 (%Nd2%^) >> %LOGFILE%
  GOTO error
)
IF %Ni2% LSS %Ne2% (
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of EXTRAPARLINES2 (%Ne2%^)
  ECHO Ensure that number of IMODFILES2 (%Ni2%^) is greater than or equal to number of EXTRAPARLINES2 (%Ne2%^) >> %LOGFILE%
  GOTO error
)

REM Create arrays for GENFILES input and check for equal lengths
REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
IF DEFINED GENFILES SET GENFILES_TMP=!GENFILES:%ROOTPATH%=###!
IF DEFINED GENFILES SET GENFILES_TMP=%GENFILES_TMP:?=@%
SET IDX=0
:loop3
    SET /A plusone=%IDX%+1
    IF "!GENFILES_TMP:~%IDX%,1!"=="*" SET GENFILES_TMP=!GENFILES_TMP:~0,%IDX%!%ASTERISK_TMP%!GENFILES_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF DEFINED GENFILES_TMP IF NOT "!GENFILES_TMP:~%IDX%,1!"=="" GOTO :loop3
SET Ngf=0
FOR %%a IN (%GENFILES_TMP%) DO (
  SET GENFILE=%%a
  SET GENFILE=!GENFILE:"=!
  IF "!GENFILE:~0,3!"=="###" SET GENFILE=%ROOTPATH%!GENFILE:~3!
  SET GENFILES_ARR[!Ngf!]=!GENFILE!
  SET /A Ngf=Ngf+1
)
SET Ngc=0
SET GENCOLORS_TMP=%GENCOLORS:,=$%
SET GENCOLORS_TMP=%GENCOLORS_TMP:;=,%
FOR %%D IN (%GENCOLORS_TMP%) DO (
  SET GENCOLOR=%%D
  SET GENCOLORS_ARR[!Ngc!]=!GENCOLOR:$=,!
  SET /A Ngc=Ngc+1
)
SET Ngt=0
FOR %%A IN (%GENTHICKNESSES%) DO (
  SET GENTHICKNESSES_ARR[!Ngt!]=%%A
  SET /A Ngt=Ngt+1
)
SET Ngs=0
FOR %%A IN (%GENSELECTIONS%) DO (
  SET GENSELECTIONS_ARR[!Ngs!]=%%A
  SET /A Ngs=Ngs+1
)
IF %Ngf% NEQ %Ngc% (
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENCOLORS (%Ngc%^)
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENCOLORS (%Ngc%^) >> %LOGFILE%
  GOTO error
)
IF %Ngf% NEQ %Ngt% (
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENTHICKNESSES (%Ngt%^)
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENTHICKNESSES (%Ngt%^) >> %LOGFILE%
  GOTO error
)
IF %Ngf% NEQ %Ngs% (
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENSELECTIONS (%Ngs%^)
  ECHO Ensure that number of GENFILES (%Ngf%^) is equal to number of GENSELECTIONS (%Ngs%^) >> %LOGFILE%
  GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

IF "%CREATEINI%"=="1" ( 
  SET MSG=  creating INI-file '%SCRIPTNAME%.INI' ...
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
        IF DEFINED IMODLEGENDS_ARR[%%i] (
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
      )

      REM Add alias if specified
      IF %%i LEQ !Na! (
        IF DEFINED ALIAS_ARR[%%i] (
          SET ALIAS=!ALIAS_ARR[%%i]:"=!
          ECHO ALIAS=!ALIAS! >> %INIFILE%
        )
      )

      REM Add cross section legend file if specified
      IF %%i LEQ !Nd! (
        IF DEFINED CSLEGENDS_ARR[%%i] (
          SET CSLEGEND=!CSLEGENDS_ARR[%%i]:"=!
          IF NOT "!CSLEGEND!"=="" (
            IF NOT EXIST "!CSLEGEND!" (
              ECHO DLF-file not found: !CSLEGEND!
              ECHO DLF-file not found: !CSLEGEND! >> %LOGFILE%
              GOTO error
            )
            ECHO CSLEGEND=!CSLEGEND! >> %INIFILE%
          )
        )
      )

      REM Add selection keyword if specified
      IF %%i LEQ !Ns! (
        IF DEFINED FILESELECTIONS_ARR[%%i] (
          SET FILESELECTION=!FILESELECTIONS_ARR[%%i]!
          IF "!FILESELECTION!"=="1" (
            ECHO SELECTED=1 >> %INIFILE%
          ) ELSE (
            ECHO SELECTED=0 >> %INIFILE%
          )
        )
      )

      REM Add extra parameter keywords if specified
      IF %%i LEQ !Ns! (
        IF DEFINED EXTRAPARLINES_ARR[%%i] (
          SET PARLINE=!EXTRAPARLINES_ARR[%%i]:"=!
          IF DEFINED PARLINE (
            FOR %%A IN ("!PARLINE:;=","!") DO (
              SET PARSUBLINE=%%A
              SET PARSUBLINE=!PARSUBLINE:"=!
              ECHO !PARSUBLINE! >> %INIFILE%
            )
          )
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

  REM Add lower set of Map files
  IF !Ni2! GTR 0 (
    ECHO [MAPS] >> %INIFILE%
    SET /A Ni2=!Ni2!-1
    SET /A Nl2=!Nl2!-1
    FOR /L %%i IN (0,1,!Ni2!) DO (
      SET IMODFILE_TMP=!IMODFILES2_ARR[%%i]:"=!
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
      IF %%i LEQ !Nl2! (
        IF DEFINED IMODLEGENDS2_ARR[%%i] (
          SET IMODLEGEND=!IMODLEGENDS2_ARR[%%i]:"=!
          IF NOT "!IMODLEGEND!"=="" (
            IF NOT EXIST "!IMODLEGEND!" (
              ECHO LEGEND-file not found: !IMODLEGEND!
              ECHO LEGEND-file not found: !IMODLEGEND! >> %LOGFILE%
              GOTO error
            )
            ECHO LEGEND=!IMODLEGEND! >> %INIFILE%
          )
        )
      )
	  
      REM Add alias if specified
      IF %%i LEQ !Na2! (
        IF DEFINED ALIAS2_ARR[%%i] (
          SET ALIAS2=!ALIAS2_ARR[%%i]:"=!
          ECHO ALIAS=!ALIAS2! >> %INIFILE%
        )
      )

      REM Add cross section legend file if specified
      IF %%i LEQ !Nd2! (
        IF DEFINED CSLEGENDS2_ARR[%%i] (
          SET CSLEGEND2=!CSLEGENDS2_ARR[%%i]:"=!
          IF NOT "!CSLEGEND2!"=="" (
            IF NOT EXIST "!CSLEGEND2!" (
              ECHO DLF-file not found: !CSLEGEND2!
              ECHO DLF-file not found: !CSLEGEND2! >> %LOGFILE%
              GOTO error
            )
            ECHO CSLEGEND=!CSLEGEND2! >> %INIFILE%
          )
        )
      )

      REM Add selection keyword if specified
      IF %%i LEQ !Ns2! (
        IF DEFINED FILESELECTIONS2_ARR[%%i] (
          SET FILESELECTION=!FILESELECTIONS2_ARR[%%i]!
          IF "!FILESELECTION!"=="1" (
            ECHO SELECTED=1 >> %INIFILE%
          ) ELSE (
            ECHO SELECTED=0 >> %INIFILE%
          )
        )
      )

      REM Add extra parameter keywords if specified
      IF %%i LEQ !Ns2! (
        IF DEFINED EXTRAPARLINES2_ARR[%%i] (
          SET PARLINE=!EXTRAPARLINES2_ARR[%%i]:"=!
          IF DEFINED PARLINE (
            FOR %%A IN ("!PARLINE:;=","!") DO (
              SET PARSUBLINE=%%A
              SET PARSUBLINE=!PARSUBLINE:"=!
              ECHO !PARSUBLINE! >> %INIFILE%
            )
          )
        )
      )
    )
    ECHO: >> %INIFILE%
  )

  REM Add GEN-files in overlay section
  IF !Ngf! GTR 0 (
    ECHO [OVERLAYS] >> %INIFILE%
    SET /A Ngf=!Ngf!-1
    SET /A Ngc=!Ngc!-1
    SET /A Ngt=!Ngt!-1
    FOR /L %%i IN (0,1,!Ngf!) DO (
      SET GENFILE_TMP=!GENFILES_ARR[%%i]:"=!
      REM Replace temporary wildcard symbols again
      SET GENFILE=!GENFILE_TMP:@=?!
      SET GENFILE=!GENFILE:$=*!

      IF NOT EXIST "!GENFILE!" (
        ECHO   WARNING: GEN-file not found: !GENFILE!
        ECHO   WARNING: GEN-file not found: !GENFILE! >> %LOGFILE%
      ) ELSE (
        ECHO !GENFILE! >> %INIFILE%
        ECHO THICKNESS=!GENTHICKNESSES_ARR[%%i]! >> %INIFILE%
        ECHO COLOR=!GENCOLORS_ARR[%%i]! >> %INIFILE%
        ECHO SELECTED=!GENSELECTIONS_ARR[%%i]! >> %INIFILE%
      )
    )
    ECHO: >> %INIFILE%
  )
)

ECHO   starting IMFcreate ...
ECHO "%IMFCREATEEXE%" %INIFILE% "%RESULTPATH%" >> %LOGFILE%
"%IMFCREATEEXE%" %INIFILE% "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

IF "%ISLINKCREATED%"=="1" (
  REM Create link to resulting IMF-file
  IF EXIST "%TOOLSPATH%\CreateLink.vbs" (
    ECHO   creating shortcut to result path ...
    SET NAME=%IMFFILENAME:.IMF=.lnk%.lnk
    ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "!NAME!" "%RESULTPATH%" >> %LOGFILE%
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "!NAME!" "%RESULTPATH%" >NUL
  )
)

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
  CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
  CALL "%SETTINGSPATH%\SIF.Settings.Maps.bat"
  CALL "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat"
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

REM FUNCTION: Retrieve and defines modelreferences MODELREF1-3 from RUN-filename. To use: "CALL :RetrieveModelReference", without arguments
:RetrieveModelReference
  SETLOCAL EnableDelayedExpansion

  REM Select last RUN/PRJ-file in directory
  FOR %%D IN ("*.RUN") DO (
    SET RUNFILE=%%~nD
  )
  IF NOT DEFINED RUNFILE (
    FOR %%D IN ("*.PRJ") DO (
      SET RUNFILE=%%~nD
    )
  )

  IF DEFINED RUNFILE (
    REM Parse RUN/PRJ-filename: get filename without extension, remove runfile prefix and retrieve and store parameters seperated by '_'
    SET RUNPARS=!RUNFILE:%RUNFILEPREFIX%_=!
    IF "!RUNPARS!" == "!RUNFILE!" (
      ECHO Runfile prefix "%RUNFILEPREFIX%_" not found for !RUNFILE!, ensure that the RUN-filename starts with this prefix
      ECHO: 
    )
  ) ELSE (
    REM Retrieve MODELREF1 from directoryname below WORKIN
    FOR /F "tokens=1,* delims=\" %%a IN ("!CD:%ROOTPATH%\WORKIN\=!") DO (
      SET MODELREF1=%%a
    )

    REM Ensure some name is defined to prevent later errors 
    IF NOT DEFINED RUNFILE SET RUNFILE=UNDEFINED
  )

  REM Check for underscores in last part of RUN-file and split if it contains underscores
  FOR /F "tokens=1,2,3* delims=_" %%a IN ("!RUNPARS!") DO (
    SET MODELREF1=%%a
    SET MODELREF2=%%b
    SET MODELREF3=%%c
  ) 
  SET MODELREF=!MODELREF1!
  IF DEFINED MODELREF2 SET MODELREF=!MODELREF!_!MODELREF2!
  IF DEFINED MODELREF3 SET MODELREF=!MODELREF!_!MODELREF3!
  
  REM Ensure variables are available outside function call
  ENDLOCAL & SET MODELREF=%MODELREF% & SET MODELREF1=%MODELREF1% & SET MODELREF2=%MODELREF2% & SET MODELREF3=%MODELREF3%
  SET MODELREF=%MODELREF: =%
  SET MODELREF1=%MODELREF1: =%
  SET MODELREF2=%MODELREF2: =%
  SET MODELREF3=%MODELREF3: =%
  GOTO:EOF

:exit
ECHO:
IF NOT DEFINED NOPAUSE PAUSE
