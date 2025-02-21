@ECHO OFF
REM ************************************************************
REM * SIF-basis v2.1.0 (Sweco)                                 *
REM *                                                          *
REM * iMODValidator comparison.bat                             *
REM * DESCRIPTION                                              *
REM *   Runs iMODValidator modelcomparison for RUN/PRJ-file    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)                     *
REM * VERSION: 2.3.0                                           *
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
REM MODELNAME1:       Modelname of modified model as MODELREF1[_MODELREF2[_MODELREF3]] (without modelprefix), or leave empty to define RUN-filename via RUNFILEPATH1
REM MODELPATH1:       Path to RUN/PRJ-file of modified model, relative path from RUNFILES-folder to RUN/PRJ-file, do not add last backslash. Leave empty to search default location (RUNFILESPATH\MODELNAME\SUBMODELNAME\MODELPOSTFIX).
REM RUNFILEPATH1:     Full path and filename to RUN/PRJ-file of modified model if MODELNAME1 is not used. MODELPATH1 is ignored then.
REM MODELNAME2:       Modelname of reference model as MODELREF1[_MODELREF2[_MODELREF3]] (without modelprefix), or leave empty to define RUN-filename via RUNFILEPATH2
REM MODELPATH2:       Path to RUN/PRJ-file of reference model, relative path from RUNFILES-folder to RUN-file, do not add last backslash. Leave empty to search default location (RUNFILESPATH\MODELNAME\SUBMODELNAME\MODELPOSTFIX).
REM RUNFILEPATH2:     Full path and filename to RUN/PRJ-file of reference model if MODELNAME2 is not used. MODELPATH2 is ignored then.
REM COMP_IDFMETHOD:   Optionally, specify method for IDF-comparison: 0=automatically detect divide/subtract (default); 1=subtract
REM COMP_NODATAVALUE: Optionally, specify (floating point) NoData comparison value (default: 0); use NaN to get NoData in an output cell if one of both compared cells has a NoData-value
REM RESULTPATH:       Path to write results to, e.g. %WORKOUTPATH%\%MODELNAME:_=\%\validation\iMODValidator
REM OPENIMOD:         Specify if iMOD should be opened with resulting IMF-file after completion 0 = iMOD is NOT opened; 1 = iMOD is opened; or leave both OPENIMOD and OPENEXCEL empty to use XML-settings
REM OPENEXCEL:        Specify if Excel should be opened with resulting spreadsheet after completion 0 = Excel is NOT opened ; 1 = Excel is opened; or leave both OPENIMOD and OPENEXCEL empty to use XML-settings
REM SETTINGSFILE:     Path to XML-file with iMODValidator settings (background GEN-files, etc)
REM Note: Comparison is calculated as MODEL1 minus MODEL2, so for positive (green) differences the model #1 has higher values than model #2
SET MODELNAME1=SCEN1_STAT-MF6-UNCONF
SET MODELPATH1=
SET RUNFILEPATH1=
SET MODELNAME2=BASIS1_STAT-MF6-UNCONF
SET MODELPATH2=
SET RUNFILEPATH2=
SET COMP_IDFMETHOD=0
SET COMP_NODATAVALUE=0
SET RESULTPATH=result\comparison
SET OPENIMOD=1
SET OPENEXCEL=1
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

REM Retrieve RUN/PRJ-file path when RUNFILEPATH or MODELPATH are not defined
IF NOT DEFINED RUNFILEPATH2 (
  IF NOT DEFINED MODELPATH2 (
    SET RUNFILEPATH2=%RUNFILESPATH%\%MODELNAME2:_=\%\%RUNFILEPREFIX%_%MODELNAME2%.RUN
  ) ELSE (
    SET RUNFILEPATH2=%RUNFILESPATH%\%MODELPATH2%\%RUNFILEPREFIX%_%MODELNAME2%.RUN
  )
)

IF NOT DEFINED RUNFILEPATH1 (
  IF NOT DEFINED MODELPATH1 (
    SET RUNFILEPATH1=%RUNFILESPATH%\%MODELNAME1:_=\%\%RUNFILEPREFIX%_%MODELNAME1%.RUN
  ) ELSE (
    SET RUNFILEPATH1=%RUNFILESPATH%\%MODELPATH1%\%RUNFILEPREFIX%_%MODELNAME1%.RUN
  )
)

REM Check for existing RUN/PRJ-file paths and try PRJ instead of RUN
IF NOT EXIST "%RUNFILEPATH2%" (
  IF EXIST "%RUNFILEPATH2:.RUN=.PRJ%" (
    SET RUNFILEPATH2=%RUNFILEPATH2:.RUN=.PRJ%
  ) ELSE (
    SET MSG=Specified base RUN/PRJ-file not found: %RUNFILEPATH2%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)

IF NOT EXIST "%RUNFILEPATH1%" (
  IF EXIST "%RUNFILEPATH1:.RUN=.PRJ%" (
    SET RUNFILEPATH1=%RUNFILEPATH1:.RUN=.PRJ%
  ) ELSE (
    SET MSG=Specified modified RUN/PRJ-file not found: %RUNFILEPATH1%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)

SET SOPTION=
SET IOPTION=
SET COPTION=/c:"%RUNFILEPATH2%"
IF DEFINED SETTINGSFILE SET SOPTION=/s:"%SETTINGSFILE%"
IF NOT "%OPENIMOD%%OPENEXCEL%" == "" (
  IF NOT DEFINED OPENIMOD SET OPENIMOD=0
  IF NOT DEFINED OPENEXCEL SET OPENEXCEL=0
  SET IOPTION=/i:%OPENIMOD%,%OPENEXCEL%
)
IF NOT "%COMP_IDFMETHOD%%COMP_NODATAVALUE%"=="" (
  IF NOT DEFINED COMP_IDFMETHOD SET COMP_IDFMETHOD=0
  SET COPTION=%COPTION%,!COMP_IDFMETHOD!
  IF DEFINED COMP_NODATAVALUE SET COPTION=!COPTION!,%COMP_NODATAVALUE%
)

REM Start iMODValidator
ECHO   starting iMODValidator comparison ...
ECHO   starting iMODValidator comparison ... >> %LOGFILE%
ECHO "%IMODVALIDATOREXE%" %SOPTION% %IOPTION% %COPTION% "%RUNFILEPATH1%" "%RESULTPATH%" >> %LOGFILE%
"%IMODVALIDATOREXE%" %SOPTION% %IOPTION% %COPTION% "%RUNFILEPATH1%" "%RESULTPATH%" >> %LOGFILE%
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
