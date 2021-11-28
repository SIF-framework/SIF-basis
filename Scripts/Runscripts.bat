@ECHO OFF
REM *****************************************************
REM * SIF-basis (Sweco)                                 *
REM * Version 1.1.0 December 2020                       *
REM *                                                   *
REM * Runscripts                                        *
REM * AUTHOR(S): Koen van der Hauw (Sweco)              *
REM * DESCRIPTION                                       * 
REM *   Runs all batchfiles from specified subdirectory *
REM *   Before running, first deletes existing logfiles *
REM * MODIFICATIONS                                     *
REM *   2017-10-25 Initial version                      *
REM *****************************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM BASEPATH:       Basepath to search specified SUBDIR-directory from, or leave empty to use current path with this script
REM SUBDIR:         Subdirectory to run batchfiles from, or leave empty to use filename of this batchfile minus Runscript-prefix (e.g. "Runscripts 01 XXX.bat" will call scripts in "01 XXX" subdirectory)
REM SKIPPEDSCRIPTS: Comma seperated list of substrings in scriptnames or subdirs that should be skipped, or leave empty to run all scripts. Surround with double quotes for spaces in paths. Note: adds to current SKIPPEDSCRIPTS to skip recursively 
REM ISRECURSIVE:    Specify (with value 1) that all batchfiles in all subdirectory's of the specified SUBDIR have to be run recursively. Other Runscrips are skipped in recursive runs.
REM ISSUBLOGSHOWN:  Specify (with value 1) that console messages of called lower level batchfiles should be written to the console and not to the logfile, this is not recursive
REM ISSKIPSHOWN:    Specify (with value 1) that messages for skipped batchfiles should be shown, or use 0 or leave empty otherwise
REM ISOLDLOGDEL:    Specify (with value 1) that all old logfiles in subdirectory SUBDIR should be deleted before running batchfiles
REM PREMSG:         Specify message to show before running scripts, or leave empty to skip
SET BASEPATH=
SET SUBDIR=
SET SKIPPEDSCRIPTS=
SET ISRECURSIVE=1
SET ISSUBLOGSHOWN=
SET ISSKIPSHOWN=1
SET ISOLDLOGDEL=1
SET PREMSG=

REM *********************
REM * Derived variables *
REM *********************
REM RUNSCRIPTPREFIX: Prefix of Runscripts-batchfiles, to determine SUBIR automatically and to skip executing Runscripts-batchfiles when ISRECURSIVE is set
REM DEFSETTINGFILE:  Name of a default settingsfile that is always skipped
SET RUNSCRIPTPREFIX=Runscripts 
SET SETTINGFILENAME=00 Settings
SET RUNSCRIPTNAME=%~n0
SET RUNSCRIPTPATH=%~dp0
SET RUNSCRIPTSLOGFILE="%RUNSCRIPTPATH%%RUNSCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %RUNSCRIPTNAME%

SET CURRENTSCRIPT=%RUNSCRIPTNAME%
SET CURRENTSCRIPTNAME=%RUNSCRIPTNAME%
SET CURRENTSCRIPTRELPATH=.

REM Note: messages are echoed to the console (via the standard error), to the logfile of this script and if this script is called
REM from a higher level Runscripts batchfile, also explicitly forced to the console to allow writing message both to a logfile and console

REM Check is this is a top-level script that is calling other RunScripts-batchfiles
REM For a top-level script HASTOPLEVELSCRIPT=1 and ISLOWLEVELSCRIPT=0
IF "%HASTOPLEVELSCRIPT%"=="1" (
  REM HASTOPLEVELSCRIPT has been set by previous RunScripts-call, so this must be a lower level RunScripts-call
  SET ISLOWLEVELSCRIPT=1
  SET INDENTATION=  %INDENTATION%
) ELSE (
  SET HASTOPLEVELSCRIPT=1
  SET INDENTATION=
)

REM If SUBDIR is empty, use default, i.e. the part after the RUNSCRIPTPREFIX in the current scriptname
IF "%SUBDIR%" == "" (
  SET SUBDIR=!RUNSCRIPTNAME:%RUNSCRIPTPREFIX%=!
)

REM Retrieve full basepath 
IF "%BASEPATH%"=="" SET BASEPATH=%RUNSCRIPTPATH%
CD "%BASEPATH%
SET BASEPATH=%CD%
IF NOT "%BASEPATH:~0,-1"=="\" SET BASEPATH=%BASEPATH%\

REM Check that specified subdir exists
IF NOT EXIST "%BASEPATH%%SUBDIR%" (
  SET MSG=Subdirectory '%SUBDIR%' does not exist 
  ECHO !MSG! 1>&2
  ECHO !MSG! > %RUNSCRIPTSLOGFILE%
  IF "%ISLOWLEVELSCRIPT%"=="1" ECHO !MSG! >CON
  GOTO error
)

SET RECURSIVESTRING=
IF "%ISRECURSIVE%"=="1" (
  SET RECURSIVESTRING= recursively
)

SET NOPAUSE=1

REM Write 'running'-message to console for toplevel scripts (via standard error) and only to logfile(s) for lower level scripts (toplevel logfile via standard error and local logfile directly) 
SET MSG=%INDENTATION%Running scripts in subdirectory '%SUBDIR%'%RECURSIVESTRING%: 
ECHO %MSG% 1>&2
ECHO %MSG% > %RUNSCRIPTSLOGFILE%

REM Show pre message if defined
IF DEFINED PREMSG (
  ECHO: >CON
  ECHO %PREMSG% >CON
  ECHO: >CON
)

REM Set recursively processed variabeles, check if RECURSIVE_SKIPPEDSCRIPTSTRING has been set
SET ISSKIPLISTMODIFIED=
IF DEFINED RECURSIVE_SKIPPEDSCRIPTSTRING (
  FOR %%D IN (%SKIPPEDSCRIPTS%) DO (
    IF "!RECURSIVE_SKIPPEDSCRIPTSTRING:%%D=!"=="!RECURSIVE_SKIPPEDSCRIPTSTRING!" (
      SET RECURSIVE_SKIPPEDSCRIPTSTRING=!RECURSIVE_SKIPPEDSCRIPTSTRING!,%%D
      SET ISSKIPLISTMODIFIED=1
    )
  )
) ELSE (
  SET RECURSIVE_SKIPPEDSCRIPTSTRING=%SKIPPEDSCRIPTS%
  IF DEFINED SKIPPEDSCRIPTS SET ISSKIPLISTMODIFIED=1
)

IF "%ISSKIPSHOWN%"=="1" (
  REM Write skipped strings if new strings were added.
  IF DEFINED ISSKIPLISTMODIFIED (
    SET MSG=%INDENTATION%  skipped scriptstrings: %RECURSIVE_SKIPPEDSCRIPTSTRING%
    ECHO !MSG! 1>&2
    ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
    IF "%ISLOWLEVELSCRIPT%"=="1" ECHO !MSG! >CON
  )
)

REM Create arrays for RECURSIVE_SKIPPEDSCRIPTSTRING and remove double quotes
SET Ns=0
FOR %%a in (%RECURSIVE_SKIPPEDSCRIPTSTRING%) do (
  SET SKIPPEDSTRING=%%a
  SET SKIPPEDSTRINGS_ARR[!Ns!]=!SKIPPEDSTRING:"=!
  SET /A Ns=Ns+1
)
SET /A Ns=Ns-1

REM GOTO specified scriptsfolder
CD "%BASEPATH%%SUBDIR%"

REM Remove old logfiles
IF EXIST "*.LOG" (
  IF "%ISOLDLOGDEL%"=="1" (
    ECHO DEL /Q *.LOG >> %RUNSCRIPTSLOGFILE%
    DEL /Q *.LOG >> %RUNSCRIPTSLOGFILE%
  )
)

SET RECURSIVEOPTION=
IF "%ISRECURSIVE%"=="1" SET RECURSIVEOPTION=/R

FOR %RECURSIVEOPTION% %%G IN (*.BAT) DO (
  SET CURRENTSCRIPT=%%G
  SET CURRENTSCRIPTNAME=%%~nG
  SET CURRENTSCRIPTRELPATH=%%~dpG
  SET CURRENTSCRIPTRELPATH=!CURRENTSCRIPTRELPATH:%BASEPATH%=!
  SET CURRENTSCRIPTRELPATH=!CURRENTSCRIPTRELPATH:~0,-1!
  SET ISSKIPPED=
  FOR /L %%L IN (0,1,%Ns%) DO (
    SET SKIPPEDSTRING=!SKIPPEDSTRINGS_ARR[%%L]!

    REM Remove skipped string in curentscript name and path to check. FOR-loop is used since double expansion does not work with delayed variables
    FOR /F "delims=" %%S IN ("!SKIPPEDSTRING!") DO SET CURRENTSCRIPTNAME2=!CURRENTSCRIPTNAME:%%S=!
    FOR /F "delims=" %%S IN ("!SKIPPEDSTRING!") DO SET CURRENTSCRIPTRELPATH2=!CURRENTSCRIPTRELPATH:%%S=!

    IF NOT "!CURRENTSCRIPTNAME2!"=="!CURRENTSCRIPTNAME!" SET ISSKIPPED=1
    IF NOT "!CURRENTSCRIPTRELPATH2!"=="!CURRENTSCRIPTRELPATH!" SET ISSKIPPED=1
  )
  IF "%ISRECURSIVE%"=="1" (
    REM Skip Runscript batchfile if recursive option has been specified
    IF NOT "!CURRENTSCRIPTNAME:%RUNSCRIPTPREFIX%=!"=="!CURRENTSCRIPTNAME!" SET ISSKIPPED=1
  )
  IF NOT "!CURRENTSCRIPTNAME:%SETTINGFILENAME%=!"=="!CURRENTSCRIPTNAME!" SET ISSKIPPED=1
  IF NOT "!ISSKIPPED!"=="1" (
    CD "%BASEPATH%!CURRENTSCRIPTRELPATH!"
    SET MSG=%INDENTATION%  Starting !CURRENTSCRIPTRELPATH!\!CURRENTSCRIPTNAME! ...
    ECHO !MSG! 1>&2
    ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
    IF "%ISLOWLEVELSCRIPT%"=="1" ECHO !MSG! >CON
    
    IF NOT "%ISSUBLOGSHOWN%"=="1" (
      IF NOT "!CURRENTSCRIPT:iMODValidator=!"=="!CURRENTSCRIPT!" (
        REM Do not log iMODValidator batchfile results, since iMOD locks the logfile
        CALL "%%G" >nul
      ) ELSE (
        IF "%ISLOWLEVELSCRIPT%"=="1" (
          REM This is a lower-level script, allow standard error to pass to higher level script
          CALL "%%G" >> %RUNSCRIPTSLOGFILE%
        ) ELSE (
          REM This is a top-level script, redirect standard error to logfile, since messages will be displayed on console as well
          CALL "%%G" >> %RUNSCRIPTSLOGFILE% 2>&1
        )
      )
    ) ELSE (
      REM Show all output of lower level script, but force standard output to logfile, since these messages will be displayed on console as well
      CALL "%%G" 2>> %RUNSCRIPTSLOGFILE%
    )
  ) ELSE (
    SET MSG=%INDENTATION%  Skipped !CURRENTSCRIPTRELPATH!\!CURRENTSCRIPTNAME!
    REM Write skip message if script is not a RunScripts-batchfile or the defined settingsfile
    IF "!CURRENTSCRIPTNAME:%RUNSCRIPTPREFIX%=!"=="!CURRENTSCRIPTNAME!" (
      IF "!CURRENTSCRIPTNAME:%SETTINGFILENAME%=!"=="!CURRENTSCRIPTNAME!" (
        IF "%ISSKIPSHOWN%"=="1" (
          ECHO !MSG! 1>&2
          IF "%ISLOWLEVELSCRIPT%"=="1" ECHO !MSG! >CON
        )
      )
    )
    ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
  )
  IF ERRORLEVEL 1 GOTO error
  IF "%SCRIPTERROR%"=="1" GOTO error
)

CD "%RUNSCRIPTPATH%"

:success
TITLE SIF-basis: %RUNSCRIPTNAME%
SET MSG=%INDENTATION%Script %RUNSCRIPTNAME% finished
ECHO !MSG!
ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
ECHO:
REM Set errorlevel 0 for higher level scripts
CMD /C "exit /B 0"
GOTO exit

:error
TITLE SIF-basis: %RUNSCRIPTNAME%
ECHO:
IF DEFINED CURRENTSCRIPTRELPATH (
  SET MSG=%INDENTATION%AN ERROR HAS OCCURRED IN '!CURRENTSCRIPTRELPATH!\!CURRENTSCRIPTNAME!.bat'
) ELSE (
  SET MSG=%INDENTATION%AN ERROR HAS OCCURRED IN '!CURRENTSCRIPT!.bat'
)
ECHO !MSG!
ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
SET MSG=%INDENTATION%Check logfile in '!RUNSCRIPTNAME:%RUNSCRIPTPREFIX%=!' for details.
ECHO !MSG!
ECHO !MSG! >> %RUNSCRIPTSLOGFILE%
ECHO:
GOTO exit

REM FUNCTION: Intialize script and search/call SETTINGS\SIF.Settings.Project.bat. To use: "CALL :Initialization", without arguments
:Initialization
  COLOR 70
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
                ECHO %INDENTATION%SETTINGS\SIF.Settings.Project.bat could not be found in the six parent directories^^!
              )
            )
          )
        )
      )
    )
  )
  GOTO:EOF

:exit
IF NOT "%ISLOWLEVELSCRIPT%"=="1" (
  IF "%HASTOPLEVELSCRIPT%"=="1" PAUSE
)
SET ISLOWLEVELSCRIPT=
