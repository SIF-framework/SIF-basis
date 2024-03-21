@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * ReplaceText.bat                         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * DESCRIPTION                             *
REM *   Replaces texts in one or more files   *
REM * VERSION: 2.0.1                          *
REM * MODIFICATIONS                           *
REM *   2019-10-14 Initial version            *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SEARCHPATH:   Path to start search
REM FILTER:       Filter to select files in the specified searchpath, e.g. *.run, or specify a filename in combination with empty path
REM TEXT1:        Replaced text, surround with double quotes if whitespace is present. For whole words, turn on REGEXP and use "\bWORD\b", or "\b(\w*WORDPART\w*)\b", where WORDPART is part of the word you're looking for, which can be combined with EXCLUDEPATTERNS to skip some words that contain WORDPART
REM TEXT2:        Replacement text, surround with double quotes if whitespace is present or if TEXT2 should be the empty string.
REM ISMATCHCASE:  Specify (with value 1) if case should match as well, or leave empty to ignore case
REM ISDATERESET:  Specify (with value 1) if (create, access and write) date and time of modified files should be reset to original date and time
REM ISREGEXP:     Specify (with value 1) if text1 and text2 are regular expressions
REM ISRECURSIVE:  Specify (with value 1) if subfolders should be processed recursively
REM ISFINDONLY:   Specify (with value 1) if matches should not be replaced, but return only the number of matches. TEXT2 is ignored with this option.
REM ISBINPROCESSED:  Specify (with value 1) if option 'b' should be used to process 'binary' files (or actually files containing nul-characters), or leave empty
REM EXCLUDEPATTERNS: Comma seperated list of text patterns to exclude from processing
SET SEARCHPATH=Een of andere directory
SET FILTER=*.bat
SET TEXT1="Een of andere IDFfileA"
SET TEXT2="Een of andere IDFfileB"
SET ISMATCHCASE=0
SET ISDATERESET=0
SET ISREGEXP=0
SET ISRECURSIVE=0
SET ISFINDONLY=1
SET ISBINPROCESSED=0
SET EXCLUDEPATTERNS=

REM *******************
REM * Tooldescription *
REM *******************
REM Replace strings in one or more (recursively) files specified by a wildcard filter. 
REM The use of regular expressions makes ReplaceText really powerful. Check the following internet sites for a full description and examples:
REM https://docs.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-language-quick-reference
REM http://download.microsoft.com/download/D/2/4/D240EBF6-A9BA-4E4F-A63F-AEB6DA0B921C/Regular%20expressions%20quick%20reference.pdf
REM 
REM A regular expression is a pattern that is attempted to match in input text. A pattern consists of one or more character literals, operators, or constructs. 
REM In regular expressions often symbols and characters are used that may be modified by the batchfile or string interpreter.
REM Note: For this, add the symbol @ before the full expression, or use escape characters. see for more info: https://www.robvanderwoude.com/escapechars.php. 
REM       Try first with simple expressions 
REM Here some examples are given.
REM - Remove commas at end of lines: 
REM   TEXT1: @",(\r\n|\n)"
REM   TEXT2: @"\r\n"
REM - Replace invalid characters with empty strings
REM   TEXT1: @"[^\w\.@-]"
REM   TEXT2: ""
REM - Replace dates that have the form mm/dd/yy with dates that have the form dd-mm-yy
REM   TEXT1: @\\b(?<month>\\d{1,2})/(?<day>\\d{1,2})/(?<year>\\d{2,4})\\b
REM   TEXT2: @"${day}-${month}-${year}"

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET TEMPDIR=TMP
SET REPLACETEXTEXE=%TOOLSPATH%\ReplaceText

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%SEARCHPATH%" (
  SET MSG=SEARCHPATH not found: %SEARCHPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

SET CASEOPTION=
SET DATEOPTION=
SET REGEXPOPTION=
SET RECURSIVEOPTION=
SET FINDOPTION=
SET BINOPTION=
SET EXCLUDEOPTION=
IF "%ISMATCHCASE%"=="1" SET CASEOPTION=/c
IF "%ISDATERESET%"=="1" SET DATEOPTION=/d
IF "%ISREGEXP%"=="1" SET REGEXPOPTION=/x
IF "%ISRECURSIVE%"=="1" SET RECURSIVEOPTION=/r
IF "%ISFINDONLY%"=="1" SET FINDOPTION=/f
IF "%ISBINPROCESSED%"=="1" SET BINOPTION=/b
IF NOT "%EXCLUDEPATTERNS%"=="" SET EXCLUDEOPTION=/e:%EXCLUDEPATTERNS%

REM Execute ReplaceText
ECHO "%REPLACETEXTEXE%" /m /l:%LOGFILE% %FINDOPTION% %CASEOPTION% %DATEOPTION% %REGEXPOPTION% %RECURSIVEOPTION% %BINOPTION% %EXCLUDEOPTION% "%SEARCHPATH%" "%FILTER%" %TEXT1% %TEXT2% >> %LOGFILE%
"%REPLACETEXTEXE%" /m /l:%LOGFILE% %FINDOPTION% %CASEOPTION% %DATEOPTION% %REGEXPOPTION% %RECURSIVEOPTION% %BINOPTION% %EXCLUDEOPTION% "%SEARCHPATH%" "%FILTER%" %TEXT1% %TEXT2%
SET RESULT=%ERRORLEVEL%
IF %RESULT% GEQ 0 (
  IF %RESULT%==0 (
    ECHO No matches found
    ECHO No matches found >> %LOGFILE%
  ) ELSE (
    ECHO Number of matches found: %RESULT% 
    ECHO Number of matches found: %RESULT% >> %LOGFILE%
  )  
) ELSE (
  GOTO error
)
ECHO: 

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
