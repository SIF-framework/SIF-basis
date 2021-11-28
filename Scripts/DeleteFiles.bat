@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM * Version 1.1.0 December 2020            *
REM *                                        *
REM * DeleteFiles.bat                        *
REM * DESCRIPTION                            *
REM *   Deletes files to recycle bin         *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2019-12-04 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM BASEPATH:    The name of the base directory from where the specified subdirectories are found
REM SUBDIRS:     Comma seperated list of subdirectory names (seperated by a comma), under the BASEPATH, that should be checked for files to be deleted
REM FILTERS:     Comma seperated list of filename filters for each of the SUBDIRS, to select files to be deleted (? and *-characters can be used as wildcards) (use * to avoid using a filter)
REM ISRECURSIVE: Specify 1 for recursive search in subdirectories, or 0 otherwise
REM ISBINSKIP:   Specify 1 to skip move to recycle bin for faster deletions
SET BASEPATH=tmp\BND\100
SET SUBDIRS=.,.,.,.
SET FILTERS=*L0.IDF,*.MET,*LAGEN.IDF,*HEADS.IDF
SET ISRECURSIVE=0
SET ISBINSKIP=0

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET RECURSIVEOPTION=
SET BINSKIPOPTION=
IF "%ISRECURSIVE%" == "1" (
  SET RECURSIVEOPTION=/S
)
IF "%ISBINSKIP%" == "1" (
  SET BINSKIPOPTION=/B
)

REM Create arrays for package input
SET Np=0
FOR %%a in (%SUBDIRS%) do (
  SET SUBDIR_ARR[!Np!]=%%a
  SET /A Np=Np+1
)

REM Use workaround for wildcard symbols in for elements (? becomes @, and * becomes $)
SET ASTERISK_TMP=$
SET FILTERS_TMP=%FILTERS:?=@%
SET IDX=0
:loop1
    SET /A plusone=%IDX%+1
    IF "!FILTERS_TMP:~%IDX%,1!"=="*" SET FILTERS_TMP=!FILTERS_TMP:~0,%IDX%!%ASTERISK_TMP%!FILTERS_TMP:~%plusone%!
    SET /A IDX=%IDX%+1
    IF NOT "!FILTERS_TMP:~%IDX%,1!"=="" GOTO :loop1
SET Nf=0
FOR %%a in (%FILTERS_TMP%) do (
  SET FILTER_ARR[!Nf!]=%%a
  SET /A Nf=Nf+1
)
SET /A N=%Np%-1
IF NOT "%Np%" == "%Nf%" (
  ECHO Ensure equal number of elements for parameters SUBDIRS (%Np%^) and FILTERS (%Nf%^) 
  GOTO error
)

ECHO Delete files started with BASEPATH: %BASEPATH%
ECHO '%SCRIPTNAME%' started with BASEPATH: %BASEPATH% > %LOGFILE%

SET NDELCOUNT=0
FOR /L %%i IN (0,1,%N%) DO (
  SET SUBDIR=!SUBDIR_ARR[%%i]!
  SET FILTER_TMP=!FILTER_ARR[%%i]!

  IF "%BASEPATH:~1,1%"==":" (
    SET SEARCHPATH=%BASEPATH%\!SUBDIR!
  ) ELSE (
    SET SEARCHPATH=%THISPATH%%BASEPATH%\!SUBDIR!
  )

  REM Replace temporary wildcard symbols again
  SET FILTER=!FILTER_TMP:@=?!
  SET FILTER=!FILTER:$=*!

  SET MSG=  deleting files in !SUBDIR!-subdirectory with filter '!FILTER!' ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  IF NOT EXIST "!SEARCHPATH!" (
    SET MSG=Directory not found: !SEARCHPATH!
    ECHO !MSG! 1>&2
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )

  ECHO "%TOOLSPATH%\Del2Bin.exe" %BINSKIPOPTION% %RECURSIVEOPTION% "!SEARCHPATH!\!FILTER!" >> %LOGFILE%
  "%TOOLSPATH%\Del2Bin.exe" %BINSKIPOPTION% %RECURSIVEOPTION% "!SEARCHPATH!\!FILTER!" >> %LOGFILE% 2>&1
  IF "!ERRORLEVEL!"=="-1" GOTO error
  IF !ERRORLEVEL! == 0 (
    SET MSG=    WARNING: no match for '!FILTER!'-files in: !SEARCHPATH:%THISPATH%=!
    ECHO !MSG! 1>&2
    ECHO !MSG! >> %LOGFILE%
  )
  SET /A NDELCOUNT=NDELCOUNT+!ERRORLEVEL!
) 
ECHO:
ECHO: >> %LOGFILE%

:success
SET MSG=Script finished, %NDELCOUNT% file(s^)/directorie(s^) deleted, see "%~n0.log"
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
