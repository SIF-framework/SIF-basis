@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * ExcelSelect.bat                        *
REM * DESCRIPTION                            *
REM *   Selection of rows in Excel file      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2018-07-01 Initial version           *
REM ******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM SOURCEPATH:     Path to Excel file(s)
REM EXCELFILTER:    Specify filter for Excel files to process
REM EXCELSHEETS:    Comma seperated list of Excel sheetnumbers to select, or leave empty to select/copy all
REM STARTROW:       Index (one based) of first row to process (default 1), or leave empty    
REM FILESELCOLIDX:  Index (one based) of column with filename to use for selection: rows with existing files are selected
REM FILESELDEFEXT:  Default extension for files without extension in file selection 
REM FILESELPATHDEF: Basepath definition: either a path string or an index (one based) of a column with a path
REM RESULTPATH:     Path to (sub)directory where scriptresults are stored
REM ISRECURSIVE:    Use value 1 for recursion in which case all subdirectories of the SOURCEPATH will be searched for IDFFILTER-files to scale, or leave empty to process only the SOURCEPATH directory
SET SOURCEPATH=%REGISDEF_PATH%
SET EXCELFILTER=%REGISDEF_FILE%
SET EXCELSHEETS=1
SET STARTROW=%REGISDEF_STARTROW%
SET FILESELCOLIDX=3
SET FILESELDEFEXT=IDF
SET FILESELPATHDEF=%REGISPATH_TOPBOT%
SET RESULTPATH=result
SET ISRECURSIVE=

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-plus: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

REM Check that the specified paths exist
IF NOT EXIST "%SOURCEPATH%" (
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH%
   ECHO The specified SOURCEPATH does not exist: %SOURCEPATH% > %LOGFILE%
   GOTO error
)

IF "%SOURCEPATH%" == "%RESULTPATH%"  (
   ECHO SOURCEPATH should not be equal to RESULTPATH: %SOURCEPATH%
   ECHO SOURCEPATH should not be equal to RESULTPATH: %SOURCEPATH% > %LOGFILE%
   GOTO error
)

REM Create result drectory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

REM Retrieve absolute path for SOURCEPATH
PUSHD %SOURCEPATH%
SET SOURCEPATH=%CD%
POPD

SET SHEETOPTION=
SET ROWOPTION=
SET FILESELOPTION=
IF DEFINED EXCELSHEETS SET SHEETOPTION=/s:%EXCELSHEETS%
IF DEFINED STARTROW SET ROWOPTION=/r:%STARTROW%
IF DEFINED FILESELCOLIDX (
  SET FILESELOPTION=/f:%FILESELCOLIDX%
  IF DEFINED FILESELPATHDEF (
    SET FILESELOPTION=!FILESELOPTION!,"%FILESELPATHDEF%"
    IF DEFINED FILESELDEFEXT SET FILESELOPTION=!FILESELOPTION!,%FILESELDEFEXT%
  )
)

REM Selecting Excelsheets
IF "%ISRECURSIVE%"=="1" (
  SET MSG=Processing ExcelSelect recursively ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  FOR /R "%SOURCEPATH%" %%G IN (%EXCELFILTER%) DO (
    SET EXCELFILENAME=%%~nxG
    SET EXCELFILEPATH=%%G
    SET EXCELPATH=%%~dpG

    REM Remove first part of path in message for readability 
    SET TARGETSUBPATH=!EXCELPATH:%SOURCEPATH%=!
    SET TARGETSUBPATH=!TARGETSUBPATH:~1!
    SET TARGETPATH=!EXCELPATH:%SOURCEPATH%=%RESULTPATH%!
    SET TARGETPATH=!TARGETPATH:~0,-1!
    ECHO   processing !TARGETSUBPATH!!EXCELFILENAME! ...
    ECHO   processing !TARGETSUBPATH!!EXCELFILENAME! ... >> %LOGFILE%

    IF NOT EXIST "!TARGETPATH!" MKDIR "!TARGETPATH!"

    ECHO "%TOOLSPATH%\ExcelSelect.exe" %SHEETOPTION% %ROWOPTION% %FILESELOPTION% "!EXCELPATH!\!EXCELFILENAME!" "!TARGETPATH!\!EXCELFILENAME!" >> %LOGFILE%
    "%TOOLSPATH%\ExcelSelect.exe" %SHEETOPTION% %ROWOPTION% %FILESELOPTION% "!EXCELPATH!\!EXCELFILENAME!" "!TARGETPATH!\!EXCELFILENAME!" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  ) 
) ELSE (
  SET MSG=Processing ExcelSelect ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%

  FOR %%G IN ("%SOURCEPATH%\%EXCELFILTER%") DO (
    SET EXCELFILENAME=%%~nxG
    ECHO   processing !EXCELFILENAME! ...
    ECHO   processing !EXCELFILENAME! ... >> %LOGFILE%

    ECHO "%TOOLSPATH%\ExcelSelect.exe" %SHEETOPTION% %ROWOPTION% %FILESELOPTION% "%SOURCEPATH%\!EXCELFILENAME!" "%RESULTPATH%\!EXCELFILENAME!" >> %LOGFILE%
    "%TOOLSPATH%\ExcelSelect.exe" %SHEETOPTION% %ROWOPTION% %FILESELOPTION% "%SOURCEPATH%\!EXCELFILENAME!" "%RESULTPATH%\!EXCELFILENAME!" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
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
IF NOT DEFINED NOPAUSE PAUSE
