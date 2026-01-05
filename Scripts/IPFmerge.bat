@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IPFmerge.bat                           *
REM * DESCRIPTION                            * 
REM *   Merges points of IPF-files           *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.1.1                         *
REM * MODIFICATIONS                          *
REM *   2018-09-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH1:   Path to first set of IPF-files to be merged
REM IPFFILES1:  Comma seperated list of IPF-files or a single filter (with use of wildcards) for selected files in in IPFPATH1
REM IPFPATH2:   Path to second set of IPF-files to be merged with first set, or leave empty to only merge files in first set
REM IPFFILES2:  Comma seperated list of IPF-files or a single filter (with use of wildcards) for selected files in in IPFPATH1, or leave empty
REM GROUPSPEC:  Group specifier string for merging each group of files with equal prefix seperately; the prefix is defined as the substring immediately before GROUPSPEC (e.g. '_L'), or leave empty to ignore
REM RESULTPATH: Path and filename for resulting merged IPF-file, or specify only path for default filename(s)
SET IPFPATH1=tmp3
SET IPFFILES1=*.IPF
SET IPFPATH2=
SET IPFFILES2=
SET GROUPSPEC=_L
SET RESULTPATH=tmp4

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET LOGFILE="%THISPATH%\%SCRIPTNAME%.log"
REM TEMPPATH: Relative path to temporary folder that can be emptied before and afterwards
SET TEMPPATH=tmp-merge

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Start script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF "%TEMPPATH%" == "" (
  ECHO TEMPPATH cannot be empty
  ECHO TEMPPATH cannot be empty >> %LOGFILE%
  GOTO error
)

IF "%TEMPPATH:~0,1%"=="\" (
  ECHO TEMPPATH should be a relative path to prevent erroneous deletions on root- or network drives.
  ECHO TEMPPATH=%TEMPPATH%
  ECHO TEMPPATH=%TEMPPATH% >> %LOGFILE%
  GOTO exit
)

SET GOPTION=
IF DEFINED GROUPSPEC SET GOPTION=/g:%GROUPSPEC%

IF NOT DEFINED IPFPATH2 IF "%IPFFILES1%"=="%IPFFILES1:,=%" (
  REM No second path is defined and only a single file/filter is defined; just 
  ECHO "%TOOLSPATH%\IPFmerge.exe" %GOPTION% "%IPFPATH1%" "%IPFFILES1%" "%RESULTPATH%" >> %LOGFILE%
  "%TOOLSPATH%\IPFmerge.exe" %GOPTION% "%IPFPATH1%" "%IPFFILES1%" "%RESULTPATH%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error

  ECHO: 
  ECHO: >> %LOGFILE%
  GOTO success
)

IF NOT EXIST "%TEMPPATH%" MKDIR "%TEMPPATH%"
IF EXIST "%TEMPPATH%\*.*" DEL /Q /S "%TEMPPATH%\*.*" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

REM Copy first set of input files: use iMODclip to copy timeseries as well
ECHO   copying input files from IPF-path1: !IPFPATH1:%ROOTPATH%\=!\%IPFFILES1% ... 
ECHO   copying input files from IPF-path1: %IPFPATH1%\%IPFFILES1% ... >> %LOGFILE%
ECHO CD /D "%IPFPATH1%" >> %LOGFILE%
CD /D "%IPFPATH1%"
FOR %%G IN (%IPFFILES1%) DO (
  SET IPFFILENAME=%%~nxG
  IF NOT EXIST "%%G" (
    ECHO File %%G not found
    ECHO File %%G not found >> %LOGFILE%
    GOTO error
  )
  ECHO "%TOOLSPATH%\iMODclip.exe" "%%G" "%THISPATH%%TEMPPATH%\01-%%G" >> %LOGFILE%
  "%TOOLSPATH%\iMODclip.exe" "%%G" "%THISPATH%%TEMPPATH%\01-%%G" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)
ECHO CD /D "%THISPATH%" >> %LOGFILE%
CD /D "%THISPATH%" >> %LOGFILE%

REM Copy optional second set of input files
IF NOT "%IPFPATH2%" == "" (
  ECHO   copying input files from IPF-path2: !IPFPATH2:%ROOTPATH%\=!\%IPFFILES2% ... 
  ECHO   copying input files from IPF-path2: %IPFPATH2%\%IPFFILES2% ... >> %LOGFILE%
  ECHO CD /D "%IPFPATH2%" >> %LOGFILE%
  CD /D "%IPFPATH2%" >> %LOGFILE%
  SET FULLIPFPATH2=%CD%
  FOR %%G IN (%IPFFILES2%) DO (
    SET IPFFILENAME=%%~nxG
    IF NOT EXIST "%%G" (
      ECHO File %%G not found
      ECHO File %%G not found >> %LOGFILE%
      GOTO error
    )
    
    ECHO "%TOOLSPATH%\iMODclip.exe" "%%G" "%THISPATH%%TEMPPATH%\02-%%G" >> %LOGFILE%
    "%TOOLSPATH%\iMODclip.exe" "%%G" "%THISPATH%%TEMPPATH%\02-%%G" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  )
)

CD "%THISPATH%"
ECHO Merging files ...
ECHO Merging files ... >> %LOGFILE%
FOR %%G IN ("%TEMPPATH%\*.IPF") DO (
  ECHO   %%~nxG
  ECHO   %%~nxG >> %LOGFILE%
)

REM Start actual merge
ECHO "%TOOLSPATH%\IPFmerge.exe" %GOPTION% "%TEMPPATH%" *.IPF "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IPFmerge.exe" %GOPTION% "%TEMPPATH%" *.IPF "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error
IF NOT EXIST "%RESULTPATH%" GOTO error

ECHO IF EXIST "%TEMPPATH%" RMDIR /Q /S "%TEMPPATH%" >> %LOGFILE%
IF EXIST "%TEMPPATH%" RMDIR /Q /S "%TEMPPATH%" 2>&1 >> %LOGFILE%

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
