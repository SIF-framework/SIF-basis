@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * IDFmerge.bat                           *
REM * DESCRIPTION                            *
REM *   Merges values in selected IDF-files  *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM *            Koen Jansen (Sweco)         *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-06-09 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM INPUTPATH:       Input path with IDF- or ASC-files
REM FILTER:          Filter for input IDF/ASC-file(s) (use wildcards, e.g. *.IDF), or comma seperated list of files in source path
REM RECURSIVE:       Specify if subdirectories in input path are checked recursively for input files (use 1 for recursion, 0 otherwise)
REM STATTYPE:        One of min, max, mean or sum (default)
REM GROUPBY:         Define group-substring for filename, as substring between (one-based) character indices i1 and i2 of filename
REM                    Valid values for i1 and i2:
REM                      > 0:  normal index, 1 refers to first character of filename
REM                      <= 0: backward index, 0 refers to last character in filename (without extension), -1 refers to character before last character, etc.
REM                    As a default the whole filename string is used (i1=1; i2=0)
REM ADDCOUNT:        Specify (with value 1) that IDF-file should be added with number of non-NoData cells in the source IDF-files
REM IGNORENODATA:    Specify (with value 1) that NoData-values should be skipped for calculation, otherwise ANY input NoData-value results in an output NoData-value
REM                  E.g. for STATTYPE mean this will only calculate mean over cells with an actual value, not including NoData-value cells 
REM NODATACALCVALUE: NoData-calculationvalue: value (english notation) to use instead of NoData-values. Cannot be combined with IGNORENODATA switched on
REM ADDPOSTFIX:      Specify (with value 1) that statistical method in output filename is added as postfix, e.g. mean
REM RESULTIDFFILE:   Specify result IDF filename, including (relative) path
SET INPUTPATH=input
SET FILTER=*.IDF
SET RECURSIVE=0
SET STATTYPE=mean
SET GROUPBY=
SET ADDCOUNT=1
SET IGNORENODATA=1
SET NODATACALCVALUE=
SET ADDPOSTFIX=1
SET RESULTIDFFILE=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET TEMPDIR=tmp
SET THISPATH=%~dp0

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Check that the specified paths exist
IF NOT EXIST "%INPUTPATH%" (
   ECHO The specified INPUTPATH does not exist: %INPUTPATH%
   ECHO The specified INPUTPATH does not exist: %INPUTPATH% > %LOGFILE% 
   GOTO error
)

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET ROPTION=
SET VOPTION=
SET GOPTION=
SET SOPTION=
SET COPTION=
SET POPTION=
SET IOPTION=
IF DEFINED NODATACALCVALUE SET VOPTION=/v:%NODATACALCVALUE%
IF DEFINED GROUPBY SET GOPTION=/g:"%GROUPBY%"
IF DEFINED STATTYPE SET SOPTION=/s:%STATTYPE%
IF "%RECURSIVE%"=="1" SET ROPTION=/r
IF "%ADDCOUNT%"=="1" SET COPTION=/c
IF "%ADDPOSTFIX%"=="1" SET POPTION=/p
IF "%IGNORENODATA%"=="1" SET IOPTION=/i

REM check if multiple input files have been specified instead of a filter
IF NOT "%FILTER:,=%"=="%FILTER%" (
  IF NOT EXIST "%TEMPDIR%\IDFSUM" MKDIR "%TEMPDIR%\IDFSUM"
  IF EXIST "%TEMPDIR%\IDFSUM\*.*" DEL /F /Q "%TEMPDIR%\IDFSUM\*.*" >> %LOGFILE% 2>&1
  FOR %%G IN (%FILTER%) DO (
    ECHO   selecting %%G ...
    ECHO COPY /Y "%INPUTPATH%\%%G" "%TEMPDIR%\IDFSUM" >> %LOGFILE% 2>&1
    COPY /Y "%INPUTPATH%\%%G" "%TEMPDIR%\IDFSUM" >> %LOGFILE% 2>&1
    IF ERRORLEVEL 1 GOTO error
  )
  SET INPUTPATH=%TEMPDIR%\IDFSUM
  SET FILTER=*.IDF
  SET FILTERSEL=1
)
ECHO:

SET MSG=Running IDFsum with filter '%FILTER%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

ECHO "%TOOLSPATH%\IDFmerge.exe" %ROPTION% %VOPTION% %GOPTION% %SOPTION% %COPTION% %POPTION% %IOPTION% "%INPUTPATH%" "%FILTER%" "%RESULTIDFFILE%" >> %LOGFILE% 
"%TOOLSPATH%\IDFmerge.exe" %ROPTION% %VOPTION% %GOPTION% %SOPTION% %COPTION% %POPTION% %IOPTION% "%INPUTPATH%" "%FILTER%" "%RESULTIDFFILE%" >> %LOGFILE% 
IF ERRORLEVEL 1 GOTO error

IF "%FILTERSEL%"=="1" (
  IF EXIST "%TEMPDIR%\IDFSUM\*.IDF" DEL /F /Q "%TEMPDIR%\IDFSUM\*.IDF" >> %LOGFILE% 2>&1
  IF ERRORLEVEL 1 GOTO error
  RMDIR "%TEMPDIR%\IDFSUM" > NUL 2>&1
  IF ERRORLEVEL 1 GOTO error
  REM try to remove tmp directory, but fail if other files are still present 
  RMDIR "%TEMPDIR%" > NUL 2>&1
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
IF NOT DEFINED NOPAUSE PAUSE