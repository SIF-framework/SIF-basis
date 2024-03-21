@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * ExcelMapper.bat                         *
REM * DESCRIPTION                             *
REM *   Maps Excel template rows to textfile  *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.1                          *
REM * MODIFICATIONS                           *
REM *   2021-05-31 Initial version            *
REM *******************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM ExcelMapper converts rows from an Excelsheet to a textfile. Rows are processed topdown or bottomup.
REM For each row a basestring template, that refers to columnvalues, is applied and written to the output.
REM This basestring is a string or a filename (with one or more strings). The following rules are followed when parsing the template
REM - '{i}'-substrings with i an integer (one based) or an alphabetic column character, are replaced with the row value in column i
REM - '{A1}'-substrings with A1 an absolute cell address, are replaced with the cell value
REM - '{A1x}'-substrings with A1 an absolute cell address and x one of '^','v','>','<', are replaced with
REM   the last non-empty cell in the direction specified (i.e. up, down, right, left), starting from cell {A1}
REM - when a filename is not used: add newlines with \n
REM - when any of the specified {}-substrings in a line refers to an empty cell, the line for that row is skipped
REM - when the basestring is an empty string, the contents of the first column are simply exported
REM Optionally, apart from the basestring which is processed for each row, an inserted or appended templatestring can be specified.

REM *****************
REM * Preprocessing *
REM *****************
REM SCRIPTNAME: Automatically derived name of this script to be used in parameters below
SET SCRIPTNAME=%~n0

REM ********************
REM * Script variables *
REM ********************
REM EXCELFILE:    Filename of Excel (xlsx) file to process
REM SHEETNR:      Number of Excel sheet to process (first sheet has number 1)
REM STARTROW:     Number of row in specified sheet to start with (first row has number 1)
REM INSERTSTRING: String or filename with text to insert in output before processing rows in Excel, or leave empty to skip
REM BASESTRING:   String or filename with text to use as template for each row in Excelsheet (see tool info for details)
REM APPENDSTRING: String or filename with text to append to output after processing rows in Excel, or leave empty to skip
REM REPLACESTRS:  Comma seperated list of multiple replaced,replacement-strings, or leave empty to skip
REM ISMERGED:     Use value 1 to merge result with existing RESULTFILE, otherwise use 0 or leave empty to overwrite an existing result file
REM ISBOTTOMUP:   Use value 1 to process rows bottom upwards upto STARTROW, or leave 0 to process topdown to first empty row
REM RESULTFILE:   Result (relative) path and filename
SET EXCELFILE=%REGISDEF_PATHCORR%\%REGISDEF_FILECORR%
SET SHEETNR=%REGISDEF_SHEETNR%
SET STARTROW=%REGISDEF_STARTROW%
SET INSERTSTRING=%~n0_insertstring.TXT
SET BASESTRING=%~n0_basestring.TXT
SET APPENDSTRING=
SET REPLACESTRS=
SET ISMERGED=
SET ISBOTTOMUP=
SET RESULTFILE=%SCRIPTNAME:a ExcelMapper=b IDFexp%.INI

REM *********************
REM * Derived variables *
REM *********************
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
SET MSG=  Excelfile: %EXCELFILE%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

IF NOT "%INSERTSTRING%"=="" (
  ECHO   Insert string: "%INSERTSTRING%"
  ECHO   Insert string: "%INSERTSTRING%" >> %LOGFILE%
)
ECHO   Base string: "%BASESTRING%"
ECHO   Base string: "%BASESTRING%" >> %LOGFILE%

ECHO   Output file: %RESULTFILE%
ECHO   Output file: %RESULTFILE% >> %LOGFILE%

IF NOT EXIST "%EXCELFILE%" (
  ECHO Excelfile not found: %EXCELFILE%
  ECHO Excelfile not found: %EXCELFILE% >> %LOGFILE%
)

ECHO: >> %LOGFILE%

SET INSERTOPTION=
SET APPENDOPTION=
SET ROWOPTION=
SET SHEETOPTION=
SET MERGEOPTION=
SET BOTTOMUPOPTION=
SET REPLACEOPTION=
IF NOT "%INSERTSTRING%"=="" SET INSERTOPTION=/i:"%INSERTSTRING%"
IF NOT "%APPENDSTRING%"=="" SET APPENDOPTION=/a:"%APPENDSTRING%"
IF NOT "%STARTROW%"=="" SET ROWOPTION=/r:%STARTROW%
IF NOT "%SHEETNR%"=="" SET SHEETOPTION=/s:%SHEETNR%
IF NOT "%ISMERGED%"=="" SET MERGEOPTION=/m
IF NOT "%ISBOTTOMUP%"=="" SET BOTTOMUPOPTION=/u
IF NOT "%REPLACESTRS%"=="" SET REPLACEOPTION=/p:"%REPLACESTRS%"

ECHO "%TOOLSPATH%\ExcelMapper.exe" %MERGEOPTION% %BOTTOMUPOPTION% %REPLACEOPTION% %SHEETOPTION% %ROWOPTION% %INSERTOPTION% %APPENDOPTION% "%EXCELFILE%" "%BASESTRING%" "%RESULTFILE%" >> %LOGFILE%
"%TOOLSPATH%\ExcelMapper.exe" %MERGEOPTION% %BOTTOMUPOPTION% %REPLACEOPTION% %SHEETOPTION% %ROWOPTION% %INSERTOPTION% %APPENDOPTION% "%EXCELFILE%" "%BASESTRING%" "%RESULTFILE%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

ECHO:
ECHO: >> %LOGFILE%

:success
SET MSG=Script '%SCRIPTNAME%' is finished
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
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
