@ECHO OFF
REM ************************************************************
REM * SIF-basis v2.1.0 (Sweco)                                 *
REM *                                                          *
REM * iMODValidator comparison.bat                             *
REM * DESCRIPTION                                              *
REM *   Start iMODValidator comparison for RUN/PRJ-file        *
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
REM BASE_MODELNAME:       Base modelname as MODELNAME[_SUBMODELNAME[_MODELPOSTFIX]] (without modelprefix), or leave empty to define RUN-filename via BASE_RUNFILEPATH
REM BASE_MODELPATH:       Path to base modelrunfile, relative path from RUNFILES-folder to RUN-file, do not add last backslash. Leave empty to search default location (RUNFILESPATH\MODELNAME\SUBMODELNAME\MODELPOSTFIX).
REM BASE_RUNFILEPATH:     Full path and filename to base RUN-file if BASE_MODELNAME is not used. BASE_MODELPATH is ignored then.
REM MODIFIED_MODELNAME:   Modified modelname as MODELNAME[_SUBMODELNAME[_MODELPOSTFIX]] (without modelprefix), or leave empty to define RUN-filename via MODIFIED_RUNFILEPATH
REM MODIFIED_MODELPATH:   Path to base modelrunfile, relative path from RUNFILES-folder to RUN-file, do not add last backslash. Leave empty to search default location (RUNFILESPATH\MODELNAME\SUBMODELNAME\MODELPOSTFIX).
REM MODIFIED_RUNFILEPATH: Full path and filename to modified RUN-file if MODIFIED_MODELNAME is not used. MODIFIED_MODELPATH is ignored then.
REM RESULTPATH:           Path to write results to, e.g. %WORKOUTPATH%\%MODELNAME:_=\%\validation\iMODValidator
REM SETTINGSFILE:         Path to XML-file with iMODValidator settings (background GEN-files, etc)
SET BASE_MODELNAME=ORG_BAS
SET BASE_MODELPATH=
SET BASE_RUNFILEPATH=
SET MODIFIED_MODELNAME=ORG_BND-org
SET MODIFIED_MODELPATH=ORG\BAS
SET MODIFIED_RUNFILEPATH=
SET RESULTPATH=controle\iMODValidator
SET SETTINGSFILE=%SETTINGSPATH%\SIF.Settings.iMODValidator.xml

REM *********************
REM * Derived variables *
REM *********************
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

SET MSG=Starting '%SCRIPTNAME%' ... 
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT "%RESULTPATH:~1,1%" == ":" (
  IF NOT "%RESULTPATH:~0,2%" == "\\" SET RESULTPATH=%THISPATH%\%RESULTPATH%
)

IF NOT DEFINED BASE_RUNFILEPATH (
  IF "%BASE_MODELPATH%" == "" (
    SET BASE_RUNFILEPATH=%RUNFILESPATH%\%BASE_MODELNAME:_=\%\%RUNFILEPREFIX%_%BASE_MODELNAME%.RUN
  ) ELSE (
    SET BASE_RUNFILEPATH=%RUNFILESPATH%\%BASE_MODELPATH%\%RUNFILEPREFIX%_%BASE_MODELNAME%.RUN
  )
)

IF NOT DEFINED MODIFIED_RUNFILEPATH (
  IF "%MODIFIED_MODELPATH%" == "" (
    SET MODIFIED_RUNFILEPATH=%RUNFILESPATH%\%MODIFIED_MODELNAME:_=\%\%RUNFILEPREFIX%_%MODIFIED_MODELNAME%.RUN
  ) ELSE (
    SET MODIFIED_RUNFILEPATH=%RUNFILESPATH%\%MODIFIED_MODELPATH%\%RUNFILEPREFIX%_%MODIFIED_MODELNAME%.RUN
  )
)

SET SETTINGSOPTION=
IF NOT "%SETTINGSFILE%" == "" SET SETTINGSOPTION=/s:"%SETTINGSFILE%"

IF NOT EXIST "%BASE_RUNFILEPATH%" (
  SET MSG=Specified base RUN-file not found: %BASE_RUNFILEPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

IF NOT EXIST "%MODIFIED_RUNFILEPATH%" (
  SET MSG=Specified modified RUN-file not found: %MODIFIED_RUNFILEPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error

)
REM Start iMODValidator
ECHO   starting iMODValidator comparison ...
ECHO   starting iMODValidator comparison ... >> %LOGFILE%
ECHO "%IMODVALIDATOREXE%" %SETTINGSOPTION% /c:"%MODIFIED_RUNFILEPATH%" "%BASE_RUNFILEPATH%" "%RESULTPATH%" >> %LOGFILE%
"%IMODVALIDATOREXE%" %SETTINGSOPTION% /c:"%MODIFIED_RUNFILEPATH%" "%BASE_RUNFILEPATH%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

REM Check for issues in logfile
IF EXIST "%LOGFILE%" (
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
CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "%RESULTPATH%\iMOD.exe - snelkoppeling.lnk" "%IMODEXE%" >nul

:success
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
