@ECHO OFF
REM ************************************************************
REM * SIF-basis v2.1.0 (Sweco)                                 *
REM *                                                          *
REM * iMODValidator validation.bat                             *
REM * DESCRIPTION                                              *
REM *   Runs iMODValidator modelvalidation for a RUN/PRJ-file. *
REM *   iMOD/Excel may be opened automically after validation. *
REM * AUTHOR(S): Koen van der Hauw (Sweco)                     *
REM * VERSION: 2.2.1                                           *
REM * MODIFICATIONS                                            *
REM *   2016-10-01 Initial version                             *
REM ************************************************************
CALL :Initialization
CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
CALL "%SETTINGSPATH%\SIF.Settings.Maps.bat"
CALL "%SETTINGSPATH%\SIF.Settings.Model.bat"
CALL "%SETTINGSPATH%\SIF.Settings.ModelRuns.bat"

REM ********************
REM * Script variables *
REM ********************
REM MODELNAME:    Base modelname as MODELNAME[_SUBMODELNAME[_MODELPOSTFIX]] (without modelprefix), or leave empty to define RUN-filename via RUNFILEPATH
REM MODELPATH:    Path to base modelrunfile, relative path from RUNFILES-folder to RUN-file, do not add last backslash. Leave empty to search default location (RUNFILESPATH\MODELNAME\SUBMODELNAME\MODELPOSTFIX).
REM RUNFILEPATH:  Full path and filename to RUN-file if MODELNAME is not used. MODELPATH is ignored then.
REM RESULTPATH:   Path to write results to, e.g. %WORKOUTPATH%\%MODELNAME:_=\%\validation\iMODValidator
REM OPENIMOD:     Specify if iMOD should be opened with resulting IMF-file after completion 0 = iMOD is NOT opened; 1 = iMOD is opened; or leave both OPENIMOD and OPENEXCEL empty to use XML-settings
REM OPENEXCEL:    Specify if Excel should be opened with resulting spreadsheet after completion 0 = Excel is NOT opened ; 1 = Excel is opened; or leave both OPENIMOD and OPENEXCEL empty to use XML-settings
REM SETTINGSFILE: Path to iMODValidator XML-settingsfile, or leave empty to use default settings
SET MODELNAME=
SET MODELPATH=
SET RUNFILEPATH=
SET RESULTPATH=result\validation
SET OPENIMOD=1
SET OPENEXCEL=0
SET SETTINGSFILE=%SETTINGSPATH%\SIF.Settings.iMODValidator.xml

REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET THISPATH=%THISPATH:~0,-1%
SET IMODVALIDATOREXE=%TOOLSPATH%\iMODValidator.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting iMODValidator validation ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
ECHO: 

IF NOT "%RESULTPATH:~1,1%" == ":" (
  IF NOT "%RESULTPATH:~0,2%" == "\\" SET RESULTPATH=%THISPATH%\%RESULTPATH%
)

IF NOT DEFINED RUNFILEPATH (
  IF DEFINED MODELNAME (
    IF "%MODELPATH%" == "" (
      SET RUNFILEPATH=%RUNFILESPATH%\%MODELNAME:_=\%\%RUNFILEPREFIX%_%MODELNAME%.RUN
    ) ELSE (
      SET RUNFILEPATH=%RUNFILESPATH%\%MODELPATH%\%RUNFILEPREFIX%_%MODELNAME%.RUN
    )
  ) 
)

SET SOPTION=
SET IOPTION=
IF DEFINED SETTINGSFILE SET SOPTION=/s:"%SETTINGSFILE%"
IF NOT "%OPENIMOD%%OPENEXCEL%" == "" (
  IF NOT DEFINED OPENIMOD SET OPENIMOD=0
  IF NOT DEFINED OPENEXCEL SET OPENEXCEL=0
  SET IOPTION=/i:!OPENIMOD!,!OPENEXCEL!
)

IF DEFINED RUNFILEPATH (
  IF NOT EXIST "%RUNFILEPATH%" (
    IF EXIST "%RUNFILEPATH:.RUN=.PRJ%" (
      SET RUNFILEPATH=%RUNFILEPATH:.RUN=.PRJ%
    ) ELSE (
      SET MSG=Specified RUN/PRJ-file not found: %RUNFILEPATH%
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )
  )

  IF EXIST "%TOOLSPATH%\Tee.exe" (
    ECHO "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% "!RUNFILEPATH!"  "%RESULTPATH%" >> %LOGFILE%
    "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% "!RUNFILEPATH!"  "%RESULTPATH%" | "%TOOLSPATH%\Tee.exe" /a /e %LOGFILE%
  ) ELSE (
    ECHO "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% "!RUNFILEPATH!"  "%RESULTPATH%" >> %LOGFILE%
    "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% "!RUNFILEPATH!"  "%RESULTPATH%" >> %LOGFILE%
  )
  IF ERRORLEVEL 1 GOTO error

  REM Check for issues in logfile
  IF EXIST %LOGFILE% (
    IF EXIST "%TOOLSPATH%\ReplaceText.exe" (
      REM Specify comma seperated list of words to check for in logfile, e.g. ERROR,WARNING
      SET CHECKEDWORDS=ERROR:
      ECHO "%TOOLSPATH%\ReplaceText" /x /f "" %LOGFILE% "(!CHECKEDWORDS:,=|!):" "XXX" > "LogfileChecks.log"
      "%TOOLSPATH%\ReplaceText" /x /f "" %LOGFILE% "(!CHECKEDWORDS:,=|!):" "XXX" >> "LogfileChecks.log"
      SET RESULT=!ERRORLEVEL!
      IF !RESULT! GEQ 0 (
        IF NOT "!RESULT!"=="0" (
          SET MSG=WARNING: !RESULT! issue^(s^) found, check logfile^^!
          ECHO !MSG!
        )  
      ) 
      DEL "LogfileChecks.log"
    )
  )

  ECHO   creating shortcut to results directory ...
  CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "iMODValidator %MODELNAME% - snelkoppeling.lnk" "%RESULTPATH%" >nul
  ECHO   creating shortcut to iMOD in results directory ...
  CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%RESULTPATH%\iMOD.exe - snelkoppeling.lnk" "%EXEPATH%\iMOD\iMOD.EXE" >nul
) ELSE (
  REM Start iMODValidator in GUI-mode without a RUN-file
  IF EXIST "%TOOLSPATH%\Tee.exe" (
    ECHO "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% >> %LOGFILE%
    "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% | "%TOOLSPATH%\Tee.exe" /a /e %LOGFILE%
  ) ELSE (
    ECHO "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% >> %LOGFILE%
    "%IMODVALIDATOREXE%" %SOPTION% %IOPTION%
  )
)

SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
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
