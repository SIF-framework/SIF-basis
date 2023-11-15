@ECHO OFF
REM ********************************************
REM * SIF-basis v2.1.0 (Sweco)                 *
REM *                                          *
REM * iMODdel.bat                              *
REM * DESCRIPTION                              *
REM *   Delete iMOD-files in specified path(s) *
REM *   selectively (e.g. empty files)         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)     *
REM * VERSION: 2.0.0                           *
REM * MODIFICATIONS                            *
REM *   2019-08-26 Initial version             *
REM ********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM DELETEDPATHS:  Comma seperated list with names of (sub)directorie(s) to delete. Note: surround a path with double quotes if it contains spaces.
REM FILTER:        File filter (using wildcards * and/or ?)for files to delete
REM ZEROMARGIN:    Specify a floating pointvalue to use as a margin around 0 to handle cells with a value less than this margin around 0, also as an empty cell.
REM                Leave empty to only check for NoData-values. Use value 0 to handle only cells with a value equal to 0 as empty.
REM ZEROVALUE:     Specify a floating point value to use instead of 0 when ZEROMARGIN is specified. If ZEROMARGIN is empty this parameter is ignored.
REM ISRECURSIVE:   Specify with value 1 that files should also be searched in subdirectories of specified paths
REM ISNOTRECYCLED: Specify with value 1 that deleted files and folders do NOT have to be placed in the recycle bin
SET DELETEDPATHS=result
SET FILTER=*.IDF
SET ZEROMARGIN=
SET ZEROVALUE=0
SET ISRECURSIVE=0
SET ISNOTRECYCLED=0

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%CD%

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT DEFINED DELETEDPATHS (
  SET MSG=DELETEDPATHS cannot be empty
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF "%FILTER%"=="" (
  SET MSG=FILTER cannot be empty
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

SET NOTRECYCLEDOPTION=
SET RECURSIVEOPTION=
SET ZEROOPTION=
IF "%ISNOTRECYCLED%"=="1" SET NOTRECYCLEDOPTION=/b
IF "%ISRECURSIVE%"=="1" SET RECURSIVEOPTION=/r
IF NOT "%ZEROMARGIN%"=="" (
  SET ZEROOPTION=/0:%ZEROMARGIN%
  IF "%ZEROVALUE%"=="" SET ZEROOPTION=/0:%ZEROMARGIN%,%ZEROVALUE%
)

FOR %%D IN (%DELETEDPATHS%) DO (
  SET DELETEDPATH=%%D
  SET DELETEDPATH=!DELETEDPATH:"=!
  SET MSG=  processing path !DELETEDPATH:%ROOTPATH%\=! ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  ECHO "%TOOLSPATH%\iMODdel.exe" %ZEROOPTION% %NOTRECYCLEDOPTION% %RECURSIVEOPTION% "!DELETEDPATH!" "%FILTER%" >> %LOGFILE% 
  "%TOOLSPATH%\iMODdel.exe" %ZEROOPTION% %NOTRECYCLEDOPTION% %RECURSIVEOPTION% "!DELETEDPATH!" "%FILTER%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
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
IF "%NOPAUSE%"=="" PAUSE
