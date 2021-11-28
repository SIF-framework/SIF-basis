@ECHO OFF
REM ******************************************
REM * SIF-basis (Sweco)                      *
REM * Version 1.1.1 November 2021            *
REM *                                        *
REM * IPFreorder.bat                         *
REM * DESCRIPTION                            * 
REM *   Reorders or selects IPF-file columns *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * MODIFICATIONS                          *
REM *   2018-10-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH:     Specify path to input IPF-file(s)
REM IPFFILTER:   Input IPF-file(s), a commaseperated list with individual files, or a filter using wildcards * and/or ?
REM ISRECURSIVE: Specify with value 1 to search input path recursively for specified files
REM REORDERING:  Specify reordering as:  (<colidx>|<colidx>;<colname>|+<colname>;<colval>)
REM              (...)      - one or more of the given parameters, seperated by spaces
REM              <a>|<b>    - either parameter <a> or parameter <b>
REM              <colidx>   - a (one-based) columnindex in the original IPF-file
REM              <colname>  - a columnname of the corresponding colidx or columnvalue
REM              <colval>   - a constant value for the whole column or [ID] to create a unique integer ID-values
REM                           a '+'-prefix is prefixed to specify not an index but a name;value-pair.
REM              all parameters can be (partly) surrounded by "-characters to include spaces; leave empty copy all columns in orginal order
REM              e.g. 1;X 2;Y 3 +ZONE:1 +ID:[ID]
REM ASSCOLNR:    Column number (in new ordering) of column with associated files; use 0 for IPF-files without associated files, 
REM                or leave empty to correct an existing column number for associated files automatically when that column is copied to the new IPF-file.
REM RESULTPATH:  Path or filename to write output IPF-file
SET IPFPATH=tmp
SET IPFFILTER=KAL1_02KAL_ZONES100_pt5000_merged.IPF
SET ISRECURSIVE=1
SET REORDERING=1;X 2;Y +IPESTZone;[ID] 7;SourceZone
SET ASSCOLNR=
SET RESULTPATH=result\KAL1_02KAL_ZONES100_pt5000.IPF

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Started script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET ASSOPTION=
SET RECOPTION=
IF DEFINED ASSCOLNR SET ASSOPTION=/a:%ASSCOLNR%
IF DEFINED ISRECURSIVE SET RECOPTION=/r

REM Process all input files
CD "%IPFPATH%" > %LOGFILE%
CD "%IPFPATH%"
FOR %%G IN (%IPFFILTER%) DO (
  ECHO   processing %%G
  SET IPFFILENAME=%%~nxG
  IF NOT EXIST "%%G" (
    ECHO File %%G not found
    ECHO File %%G not found >> %LOGFILE%
    GOTO error
  )

  ECHO "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% "!IPFFILENAME!" "%THISPATH%%RESULTPATH%" %REORDERING% >> %LOGFILE%
  "%TOOLSPATH%\IPFreorder.exe" /o %ASSOPTION% %RECOPTION% "!IPFFILENAME!" "%THISPATH%%RESULTPATH%" %REORDERING% >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)
CD "%THISPATH%"

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
IF "%NOPAUSE%"=="" PAUSE
