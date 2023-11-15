@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * Cleanup.bat                            *
REM * DESCRIPTION                            *
REM *   Deletes files in temporary folder(s) *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.0                         *
REM * MODIFICATIONS                          *
REM *   2019-08-26 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM DELETEDPATHS:  Comma seperated list with names of (sub)directorie(s) to delete, surround with double quotes when paths contain spaces
REM DELETEDFILES:  Comma seperated list with (relative or absolute paths and) filenames/filters of files to delete, or leave empty to skip; surround with double quotes when paths/filenames contain spaces
REM RECURSIONPATH: Path from which specified DELETEDFILES are searched recursively, or leave empty to search directly under current path or in absolute paths if specified with DELETEDFILES
REM ISLOGDELETED:  Specify with value 1 that logfiles in current directory should be deleted
REM ISLNKDELETED:  Specify with value 1 that lnk-files (shortcuts to files/folders) should be deleted from current directory 
REM ISNOTRECYCLED: Specify with value 1 that deleted files and folders do NOT have to be placed in the recycle bin
SET DELETEDPATHS=tmp
SET DELETEDFILES=
SET RECURSIONPATH=
SET ISLOGDELETED=
SET ISLNKDELETED=
SET ISNOTRECYCLED=

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

IF NOT EXIST "%TOOLSPATH%\Del2Bin.exe" (
  IF NOT "%ISNOTRECYCLED%"=="1" (
    ECHO Del2Bin.exe not found in TOOLSPATH, use option ISNOTRECYCLED=1 to delete without recycling
    ECHO Del2Bin.exe not found in TOOLSPATH, use option ISNOTRECYCLED=1 to delete without recycling > %LOGFILE%
    GOTO error
  )
)

REM First delete old logfiles in current directory if requested
IF "%ISLOGDELETED%"=="1" (
  ECHO Deleting logfiles ...
  IF "%ISNOTRECYCLED%"=="1" (
    IF EXIST "*.log" DEL "*.log" >NUL 2>&1
    IF ERRORLEVEL 1 GOTO error
  ) ELSE (
    IF EXIST "*.log" "%TOOLSPATH%\Del2Bin.exe" /e "*.log" >NUL 2>&1
    IF ERRORLEVEL 1 GOTO error
  )
)

REM First delete old link files in current directory if requested
IF "%ISLNKDELETED%"=="1" (
  ECHO Deleting lnk-files ...
  IF "%ISNOTRECYCLED%"=="1" (
    IF EXIST "*.lnk" DEL "*.lnk" >NUL 2>&1
    IF ERRORLEVEL 1 GOTO error
  ) ELSE (
    IF EXIST "*.lnk" "%TOOLSPATH%\Del2Bin.exe" /e "*.lnk" >NUL 2>&1
    IF ERRORLEVEL 1 GOTO error
  )
)

SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF DEFINED DELETEDPATHS (
  FOR %%D IN (%DELETEDPATHS%) DO (
    SET DELETEDPATH=%%D
    SET DELETEDPATH=!DELETEDPATH:"=!

    IF "!DELETEDPATH!"=="%~dp0" (
      SET MSG=DELETEDPATH cannot be equal to current path %~dp0
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="%~dp0\" (
      SET MSG=DELETEDPATH cannot be equal to current path %~dp0\
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="." (
      SET MSG=DELETEDPATH cannot be equal to current path '.'
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"==".." (
      SET MSG=DELETEDPATH cannot be equal to previous path '..'
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="" (
      SET MSG=DELETEDPATH cannot be empty
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH:~1,1!" == ":" (
      SET ROOTDIR=!DELETEDPATH:~3!
      IF "!ROOTDIR:\=!"=="!ROOTDIR!" (
	REM No backslashes found after X:\ 
        SET MSG=DELETEDPATH cannot be equal to single directory under root 'X:\YYY'
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        GOTO error
      )
    )

    SET MSG=  removing !DELETEDPATH:%ROOTPATH%\=! ...
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    IF "%ISNOTRECYCLED%"=="1" (
      ECHO IF EXIST "!DELETEDPATH!" RMDIR /Q /S "!DELETEDPATH!" >> %LOGFILE%
      IF EXIST "!DELETEDPATH!" RMDIR /Q /S "!DELETEDPATH!" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO IF EXIST "!DELETEDPATH!" "%TOOLSPATH%\Del2Bin.exe" /e /s "!DELETEDPATH!" >> %LOGFILE%
      IF EXIST "!DELETEDPATH!" "%TOOLSPATH%\Del2Bin.exe" /e /s "!DELETEDPATH!" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    )
  )
)

SET RECURSIONOPTION=
IF DEFINED RECURSIONPATH (
  SET RECURSIONOPTION=/R "%RECURSIONPATH%"
)

IF DEFINED DELETEDFILES (
  FOR %RECURSIONOPTION% %%D IN (%DELETEDFILES%) DO (
    SET DELETEDFILE=%%D
    SET DELETEDFILE=!DELETEDFILE:"=!

    IF "!DELETEDFILE!"=="*" (
      SET MSG=DELETEDFILE cannot be equal to *
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDFILE!"=="*.*" (
      SET MSG=DELETEDFILE cannot be equal to *.*
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF NOT "!DELETEDFILE!"=="" (
      IF DEFINED RECURSIONPATH (
        SET MSG=  removing !DELETEDFILE:%RECURSIONPATH%\=! ...
      ) ELSE (
        SET MSG=  removing !DELETEDFILE! ...
      )
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      IF "%ISNOTRECYCLED%"=="1" (
        ECHO IF EXIST "!DELETEDFILE!" DEL /F /Q "!DELETEDFILE!" >> %LOGFILE%
        IF EXIST "!DELETEDFILE!" DEL /F /Q "!DELETEDFILE!" >> %LOGFILE% 2>&1
        IF ERRORLEVEL 1 GOTO error
     ) ELSE (
        ECHO IF EXIST "!DELETEDFILE!" "%TOOLSPATH%\Del2Bin.exe" /e /f "!DELETEDFILE!" >> %LOGFILE%
        IF EXIST "!DELETEDFILE!" "%TOOLSPATH%\Del2Bin.exe" /e /f "!DELETEDFILE!" >> %LOGFILE% 2>&1
        IF ERRORLEVEL 1 GOTO error
      )
    ) ELSE (
      SET MSG=DELETEDFILE cannot be empty
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )
  )
)

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
