@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IPFsplit.bat                           *
REM * DESCRIPTION                            *
REM *   Splits IPF-files based on values in  *
REM *   specified column                     *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-09-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH:     Path to input IPF-files
REM IPFFILTER:   Filter, with use of wildcards, for filenames of input IPF-files, or a single filename
REM SPLITCOLIDX: Column name or index (one based) to split IPF-files on
REM SPLITPREFIX: Prefix for outputfilename before splitvalue. Before this prefix an underscore is added by the tool
REM RESULTPATH:  Specify result path
SET IPFPATH=result
SET IPFFILTER=ZTP_WINFILTERS.IPF
SET SPLITCOLIDX=8
SET SPLITPREFIX=L
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET MSG=Running IPFsplit
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET PREFIXOPTION=
IF DEFINED SPLITPREFIX SET PREFIXOPTION=/p:"%SPLITPREFIX%"

FOR %%G IN ("%IPFPATH%\%IPFFILTER%") DO (
  SET IPFFILENAME=%%~nxG
  ECHO   splitting !IPFFILENAME! ...
  ECHO   splitting !IPFFILENAME! ... >> %LOGFILE%
  ECHO "IPFsplit.exe" %PREFIXOPTION% "%IPFPATH%" "!IPFFILENAME!" %SPLITCOLIDX% "%RESULTPATH%"  >> %LOGFILE%
  "%TOOLSPATH%\IPFsplit.exe" %PREFIXOPTION% "%IPFPATH%" "!IPFFILENAME!" %SPLITCOLIDX% "%RESULTPATH%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

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
