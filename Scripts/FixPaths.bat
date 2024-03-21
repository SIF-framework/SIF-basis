@ECHO OFF
REM ********************************************
REM * SIF-basis v2.1.0 (Sweco)                 *
REM *                                          *
REM * FixPaths.bat                             *
REM * DESCRIPTION                              *
REM *   Corrects absolute paths to current     *
REM *   directory in a selection of iMOD-files *
REM * AUTHOR(S): Koen van der Hauw (Sweco)     *
REM * VERSION: 2.0.1                           *
REM * MODIFICATIONS                            *
REM *   2017-02-03 Initial version             *
REM ********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM FIXFILTERS:  Path and file filter (seperated by a backslash). Several combinations can be specified (seperated by comma's)
REM              The path (full or partly) should be specified relative to the directory that the tool is started from. Each file filter should contain at least one wildcard.
REM ISRECURSIVE: Specify (with value 1) that subdirectories from the specified path's should be searched recursively, or leave empty
REM ISADDQUOTES: Specify (with value 1) that double quotes should be added in PRF- and RUN-files around filenames if not yet present
REM IS_BACKEDUP: Specify (with value 1) if a backup should be made of the selected files
REM EXCLUDEDMATCH_PATTERNS: Comma seperated list of regular expression patterns for matches to exclude, or leave empty. Do NOT surround with double quotes. 
REM SKIPPEDFILE_PATTERNS:   Comma seperated list of regular expression patterns for files to exclude, or leave empty. Do NOT surround with double quotes.
REM Note: For patterns use regular expression syntax, so \\ instead of \, see ReplaceText documentation for more information.
SET FIXFILTERS=IMFILES\*.IMF,SETTINGS\*.TXT,EXE\iMOD\*.PRF,RUNFILES\*.RUN,RUNFILES\*.PRJ
SET ISRECURSIVE=1
SET ISADDQUOTES=1
SET IS_BACKEDUP=1
SET EXCLUDEDMATCH_PATTERNS=
SET SKIPPEDFILE_PATTERNS=

REM *********************
REM * Derived variables *
REM *********************
SET THISPATH=%CD%\
SET SCRIPTNAME=%~n0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"
SET CURRENTDATE=%date:~-10,2%-%date:~-7,2%-%date:~-4,4%
SET ISROOTPATHCHECKED=1
SET ISIMODLINKCREATED=1

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=FixPaths
ECHO %MSG% > %LOGFILE%
SET MSG=--------
ECHO %MSG% >> %LOGFILE%
ECHO:

SET UNCPATH=%~dp0
IF "%UNCPATH:~0,2%"=="\\" (
  ECHO This script should be called from a mapped drive, iMOD does not handle UNC-paths properly.
  ECHO UNCPATH=%UNCPATH%
  ECHO UNCPATH=%UNCPATH% >> %LOGFILE%
  GOTO exit
)

ECHO This script replaces paths in all files that match the following filters: 
ECHO %FIXFILTERS%
ECHO:
ECHO In these files strings are replaced by the paths as defined in SETTINGS\SIF.Settings.Project.bat,
ECHO for all lines that have matches with one of the following regular expressions: 
ECHO ".:.+BASISDATA", ".:.+DBASE", ".:.+RESULTS", ".:.+SHAPES", ".:.+WORKIN", ".:.+WORKOUT", ".:.+EXE\\PLUGINS"
ECHO:

IF "%ISADDQUOTES%"=="1" (
  ECHO Double quotes will be placed around filenames, except for IMF-files and inp-files in RUN/PRJ-files
  ECHO:
)

IF DEFINED EXCLUDEDMATCH_PATTERNS (
  ECHO Strings will NOT be replaced when the line has a match with one of the following regular expressions: %EXCLUDEDMATCH_PATTERNS%
  ECHO:
)
IF DEFINED SKIPPEDFILE_PATTERNS (
  ECHO Files will be skipped when the filename matches one of the following regular expressions: %SKIPPEDFILE_PATTERNS%
  ECHO:
)

IF "%IS_BACKEDUP%"=="1" (
  SET BACKUPPATH=%THISPATH%backup_%CURRENTDATE%
  REM For logging use the UNC-path, instead of path with temporary PUSHD-drive 
  SET BACKUPPATH2=%~dp0backup_%CURRENTDATE%
  IF EXIST "!BACKUPPATH!" (
    SET BACKUPPATH=!BACKUPPATH!_%time:~0,2%.%time:~3,2%.%time:~6,2%
    SET BACKUPPATH2=!BACKUPPATH2!_%time:~0,2%.%time:~3,2%.%time:~6,2%
  )
  SET MSG=Backups will be stored in: !BACKUPPATH2!
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
)
ECHO: 
IF NOT DEFINED NOPAUSE PAUSE
ECHO: 

IF "%ISROOTPATHCHECKED%"=="1" (
  IF NOT EXIST "%~dp0SETTINGS\SIF.Settings.Project.bat" (
    ECHO This script should be called from the Model-rootpath that contains 'SETTINGS\SIF.Settings.Project.bat'
    GOTO error
  )
)

SET MSG=Starting FixPaths. Replacements will be reported.
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO: 

IF "%IS_BACKEDUP%"=="1" (
  IF NOT EXIST "!BACKUPPATH!" (
    ECHO MKDIR "!BACKUPPATH!" >> %LOGFILE%
    MKDIR "!BACKUPPATH!" >> %LOGFILE%
  )
)
 
REM Retrieve ReplaceText options
IF DEFINED EXCLUDEDMATCH_PATTERNS (
  SET EXCLUDEMATCH_OPTION=/e:"%EXCLUDEDMATCH_PATTERNS%"
  ECHO   Strings will NOT be replaced when matching one of the following regular expressions: %EXCLUDEDMATCH_PATTERNS% >> %LOGFILE%
)
IF DEFINED SKIPPEDFILE_PATTERNS (
  SET SKIPFILE_OPTION=/s:"%SKIPPEDFILE_PATTERNS%"
  ECHO   Files will be skipped when matching one of the following regular expressions: %SKIPPEDFILE_PATTERNS% >> %LOGFILE%
)
ECHO: >> %LOGFILE%

REM Use workaround for wildcard symbols in filters with for elements (? becomes @, and * becomes $)
SET ASTERISK_TMP=$
SET FIXFILTERS_TMP=%FIXFILTERS:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!FIXFILTERS_TMP:~%IDX%,1!"=="*" SET FIXFILTERS_TMP=!FIXFILTERS_TMP:~0,%IDX%!%ASTERISK_TMP%!FIXFILTERS_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF NOT "!FIXFILTERS_TMP:~%IDX%,1!"=="" GOTO :loop1

IF "%ISRECURSIVE%"=="1" (
  SET RECURSE_OPTION=/R
) ELSE (
  SET RECURSE_OPTION=
)

REM Now it's possible to loop through the filters before they are actually processed by windows
FOR %%G IN (!FIXFILTERS_TMP!) DO (
  REM Split defined filter in path part and file filter part. 
  SET FILTERPATH=%%~dpG
  SET FILTER=%%~nG%%~xG

  REM Replace temporary wildcard symbols again
  SET FILTER=!FILTER:@=?!
  SET FILTER=!FILTER:$=*!
  IF EXIST "!FILTERPATH!" (
    CD "!FILTERPATH!"
    FOR %RECURSE_OPTION% %%F IN (!FILTER!) DO (
      SET CURRENTFILE=%%F
      IF "!CURRENTFILE:backup_=!"=="!CURRENTFILE!" (
        SET MSG=Processing file %%~nF%%~xF ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        REM Create backup of original file
        IF "%IS_BACKEDUP%" == "1" (
          SET FILEPATH=!BACKUPPATH!\!CURRENTFILE:%THISPATH%=!
          SET FOLDERPATH=!FILEPATH:%%~nF%%~xF=!
          REM ECHO BACKUP to !FOLDERPATH!
          ECHO XCOPY /Y "%%F" "!FOLDERPATH!" >> %LOGFILE%
          XCOPY /Y "%%F" "!FOLDERPATH!" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        )
        
        SET CURRENTPATH=%%~dpF
        SET CURRENTPATH=!CURRENTPATH:~0,-1!
        REM Replace possible references to an old DBASE-path with the current DBASEPATH
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\DBASE(?^<rest^>\\[^^""\r\n,]*)" "%DBASEPATH%${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\DBASE(?^<rest^>\\[^^""\r\n,]*)" "%DBASEPATH%${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%

        REM Replace possible references to an old BASISDATA-path with the current BASISDATA-path
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\BASISDATA(?^<rest^>\\[^^""\r\n,]*)" "%ROOTPATH%\BASISDATA${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\BASISDATA(?^<rest^>\\[^^""\r\n,]*)" "%ROOTPATH%\BASISDATA${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%

        REM Replace possible references to an old RESULTS-path with the current RESULTS-path
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\RESULTS(?^<rest^>\\[^^""\r\n,]*)" "%RESULTSPATH%${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\RESULTS(?^<rest^>\\[^^""\r\n,]*)" "%RESULTSPATH%${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%
    
        REM Replace possible references to an old SHAPES-path with the current SHAPES-path
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\SHAPES(?^<rest^>\\[^^""\r\n]*)" "%SHAPESPATH%${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\SHAPES(?^<rest^>\\[^^""\r\n]*)" "%SHAPESPATH%${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%

        REM Replace possible references to an old WORKIN-path with the current WORKIN-path
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\WORKIN(?^<rest^>\\[^^""\r\n,]*)" "%WORKINPATH%${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\[^^"",\r\n]+\\WORKIN(?^<rest^>\\[^^""\r\n,]*)" "%WORKINPATH%${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%
  
        REM Replace possible references to an old WORKOUT-path with the current WORKOUT-path
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\WORKOUT(?^<rest^>\\[^^""\r\n]*)" "%WORKOUTPATH%${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\WORKOUT(?^<rest^>\\[^^""\r\n]*)" "%WORKOUTPATH%${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%
        
        REM For IMF and PRF-files replace PLUGIN-path as well
        ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\EXE\\PLUGINS(?^<rest^>\\[^^""\r\n]*)" "%EXEPATH%\PLUGINS${rest}" >> %LOGFILE%
        "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" ".:\\.+\\EXE\\PLUGINS(?^<rest^>\\[^^""\r\n]*)" "%EXEPATH%\PLUGINS${rest}"
        IF ERRORLEVEL 1 GOTO error
        ECHO: >> %LOGFILE%

        IF "%ISADDQUOTES%"=="1" (
          REM Surround filenames with double quotes, except for IMF-files as iMOD does not allow these; first replace single quotes by double quotes
          IF /I NOT "%%~xF"==".IMF" (
            ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "^'" """" >> %LOGFILE%
            "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "^'" """" 
            IF ERRORLEVEL 1 GOTO error
            ECHO: >> %LOGFILE%
            
            IF DEFINED EXCLUDEMATCH_OPTION (
              SET EXCLUDEMATCH_OPTION2=%EXCLUDEMATCH_OPTION%,.inp
            ) ELSE (
              SET EXCLUDEMATCH_OPTION2=/e:.inp
            )

            ECHO ReplaceText /x /b /d /l:%LOGFILE% !EXCLUDEMATCH_OPTION2! %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "(((?<^!"").:\\[^^,\r\n]+\.[a-zA-Z0-9]{3,4})|((?<^!"").:\\([^^"",\r\n]+\\)*[^^,\.\r\n]+))" """$1""" >> %LOGFILE%
            "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% !EXCLUDEMATCH_OPTION2! %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "(((?<^!"").:\\[^^,\r\n]+\.[a-zA-Z0-9]{3,4})|((?<^!"").:\\([^^"",\r\n]+\\)*[^^,\.\r\n]+))" """$1"""
            IF ERRORLEVEL 1 GOTO error
            ECHO: >> %LOGFILE%

            REM Remove quotes around inp-files (for MetaSWAP)
            ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" """(.:\\.+\.inp)""" ""$1"" >> %LOGFILE%
            "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" """(.:\\.+\.inp)""" ""$1""
            IF ERRORLEVEL 1 GOTO error
            ECHO: >> %LOGFILE%
          ) 
        )

        SET ISPRFEXTENSION=
        IF /I "%%~xF"==".PRF" (
          SET ISPRFEXTENSION=1
        )
        IF "!ISPRFEXTENSION!"=="1" (
          REM For some parameters in PRF-files ".:\*\Model"-like strings, so without subdirectory, are replaced, since in the PRF-file also absolute paths may be present
          FOR %%N IN (USER) DO (
            SET PRFPAR=%%N
            REM Replace all strings between optional quotes in lines that start with USER, upto the end-of-line
            SET REGEXP=^(?^<=!PRFPAR!\s+^)""?^(.:\\^|\.\.\\^).+""?[ \t]*
            SET REPSTRING=%ROOTPATH%
            IF "%ISADDQUOTES%"=="1" (
              SET REPSTRING=""!REPSTRING!""
            )
            ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "!REGEXP!" "!REPSTRING!" >> %LOGFILE%
            "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "!REGEXP!" "!REPSTRING!"
            IF ERRORLEVEL 1 GOTO error
            ECHO: >> %LOGFILE%
          )

          REM For other parameters in PRF-files replace until known subdir
          FOR %%N IN (DBASE,MODFLOW,PLUGIN1,PLUGIN2) DO (
            SET PRFPAR=%%N
            REM Replace all strings between optional quotes in lines that start with specified string, upto the end-of-line
            FOR %%M IN (EXE,DBASE) DO (
              SET REGEXP=^(?^<=!PRFPAR!\s+^)?^(.:\\^|\.\.\\^).+\\%%M?[ \t]*
              SET REPSTRING=%ROOTPATH%\%%M
              ECHO ReplaceText /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "!REGEXP!" "!REPSTRING!" >> %LOGFILE%
              "%TOOLSPATH%\ReplaceText" /x /b /d /l:%LOGFILE% %EXCLUDEMATCH_OPTION% %SKIPFILE_OPTION% "!CURRENTPATH!" "%%~nxF" "!REGEXP!" "!REPSTRING!"
              IF ERRORLEVEL 1 GOTO error
              ECHO: >> %LOGFILE%
            )
          )
        )
      )
      ECHO: >> %LOGFILE%
    )
    CD "%THISPATH%"
  ) ELSE (
    ECHO Path '!FILTERPATH:%ROOTPATH%\=!' not found, filter '!FILTERPATH:%ROOTPATH%\=!!FILTER!' is skipped.
  )
)

IF "%ISIMODLINKCREATED%"=="1" (
  IF EXIST "%EXEPATH%\%iMOD\iMOD.exe" (
    ECHO:
    ECHO: >> %LOGFILE%
    ECHO Creating shortcut to iMOD executable ...
     ECHO Creating shortcut to iMOD executable ... >> %LOGFILE%
    ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "iMOD.exe - Snelkoppeling.lnk" "%EXEPATH%\iMOD\iMOD.exe" >> %LOGFILE%
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "iMOD.exe - Snelkoppeling.lnk" "%EXEPATH%\iMOD\iMOD.exe" >nul
  ) ELSE (
    REM iMOD.exe not found, use last iMOD*.exe in EXE\iMOD
    SET iMODEXE=
    FOR %%G IN ("%EXEPATH%\iMOD\iMOD*.exe") DO (  
      SET iMODEXE=%%~nxG
    )
    IF NOT "!iMODEXE!"=="" (
      ECHO Creating shortcut to iMOD executable ...
      ECHO Creating shortcut to iMOD executable ... >> %LOGFILE%
      ECHO CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "iMOD.exe - Snelkoppeling.lnk" "%EXEPATH%\iMOD\!iMODEXE!" >> %LOGFILE%
      CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "iMOD.exe - Snelkoppeling.lnk" "%EXEPATH%\iMOD\!iMODEXE!" >nul
    )
  )
)

ECHO:
ECHO: >> %LOGFILE%

SET MSG=Fixing paths is finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel 0 for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:error
ECHO:
SET MSG=AN ERROR HAS OCCURRED^^! Check logfile "%~n0.log"
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
CD "%THISPATH%"
GOTO exit

REM FUNCTION: Intialize script and call SIF.Settings.Project.bat. To use: "CALL :Initialization", without arguments
:Initialization
  COLOR 70
  PUSHD %~dp0
  REM FixPaths should be run from ROOTPATH, so project settings are searched relative to FixPaths-path
  IF EXIST "%~dp0SETTINGS\SIF.Settings.Project.bat" CALL "%~dp0SETTINGS\SIF.Settings.Project.bat"
  GOTO:EOF

REM FUNCTION: Intialize script and search/call 'SETTINGS\SIF.Settings.Project.bat' and '00 Settings.bat'. To use: "CALL :Initialization", without arguments
:Initialization
  COLOR 70
  REM FixPaths is normally run from ROOTPATH, so project settings are first searched relative to FixPaths-path
  IF EXIST "%~dp0SETTINGS\SIF.Settings.Project.bat" (
    CALL "%~dp0SETTINGS\SIF.Settings.Project.bat"
  ) ELSE (
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
