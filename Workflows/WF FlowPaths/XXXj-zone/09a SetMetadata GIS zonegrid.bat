@ECHO OFF
REM ********************************************
REM * SIF-basis v2.2.0 (Sweco)                 *
REM *                                          *
REM * SetMetadata.bat                          *
REM * DESCRIPTION                              *
REM *    Sets metadata strings in XML-template *
REM * AUTHOR(S): Koen van der Hauw (Sweco)     *
REM * VERSION: 2.0.0                           *
REM * MODIFICATIONS                            *
REM *   2018-10-01 Initial version             *
REM *   2024-01-12 Cleanup, move to SIF-basis  *
REM ********************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM XMLTEMPLATEFILE: Path of template file for metadata with below M-strings to be replaced
REM XMLPATH:         Path of resulting metadata XML-file
REM XMLFILE:         Filename of metadata XML-file to create
REM CURRENTDATE:     String with current/creation date of file that metadata corresponds with; note: if CMD-tool DATE is used, check language settings
REM MSTRINGLIST:     Specify M-strings to be replace in metadata template
SET XMLTEMPLATEFILE=%XMLTEMPLATEFILE%
SET XMLPATH=%RESULTPATH_GIS%
SET XMLFILE=%TYPESTRING%_FW_%MODELREF%_%SOURCEABBR%.ASC.XML
SET CURRENTDATE=%DATE:~-10,2%-%DATE:~-7,2%-%DATE:~-4,4%
SET MSTRINGLIST=M000,M001,M002,M003,M004,M005,M006,M007,M008,M009,M010,M011,M012,M013,M014,M015

REM M000: Filename of XML-file for metadata
REM M001: Creation date of file that metadata corresponds with
REM M002: Title for metada that describes file that metadata corresponds with
REM M003: Date of last modification of file that metadata corresponds with
REM M004: Edition/version of file that metadata corresponds with
REM M005: Summary of file that metadata corresponds with
REM M006: Purpose of file that metadata corresponds with
REM M007: Description of file that metadata corresponds with
REM M008: Organisation that created file
REM M009: Individual contactperson within organisation
REM M010: Email adress of individual contactperson
REM M011: Email adress of individual contactperson
REM M007: Description of file that metadata corresponds with
REM M008: Organisation that created file
REM M009: Individual contactperson within organisation
REM M010: Email adress of individual contactperson
REM M011: Email adress of individual contactperson
REM M012: Representative scale fraction of GIS-file 
REM M013: Alternative information (source)
REM M014: Completeness of data
REM M015: Format of file that metadata corresponds with
REM EXTENT: Extent with comma seperated coordinates (xll,yll,xur,yur)
SET M000=%XMLFILE%
SET M001=%CURRENTDATE%
SET M002=%TYPESTRING%
SET M003=%CURRENTDATE%
SET M004=v1.0
SET M005=%TYPESTRING% grid met reistijd in jaren tot aan winning %SOURCEABBR%
SET M006=Herberekening grondwaterbeschermingsgebied voor winning %SOURCEABBR%
SET M007=%TYPESTRING% grid met reistijd in jaren tot aan winning %SOURCEABBR% o.b.v. voorwaartse berekening vanuit bufferzone rondom terugwaarts berekende %TYPESTRING%. Startpunten tussen %ISFFW_TOPSTRING% en %ISFFW_BOTSTRING%, iedere %FPFW_ISDP_N1%x%FPFW_ISDP_N2%m en %FPFW_ISDP_VIN% punten per verticaal. Model voor stroombaanberekening is %MODELREF%.
SET M008=%CONTACTORG%
SET M009=%CONTACTPERSON%
SET M010=%CONTACTEMAIL%
SET M011=%CONTACTSITE%
SET M012=10000
SET M013=Zie de bijborende rapportage en workflow-scripts in de map '%~dp0'.
SET M014=De stroombaanberekeningen zijn uitgevoerd met het model 'MODELREF'. Zie de rapportage van het model voor meer informatie.
SET M015=ESRI ASC-grid
SET EXTENT=%MODELEXTENT%

REM *********************
REM * Derived variables *
REM *********************
SET THISPATH=%~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%XMLPATH%" MKDIR "%XMLPATH%"

SET MSG=  XML-template: !XMLTEMPLATEFILE:%ROOTPATH%\=!
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

REM Copy XML-template file
SET MSG=Copying XML-template ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
IF NOT EXIST "%XMLTEMPLATEFILE%" (
  SET MSG=XML-template not found: %XMLTEMPLATEFILE% 
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)
ECHO COPY /Y "%XMLTEMPLATEFILE%" "%XMLPATH%\%XMLFILE%" >> %LOGFILE%
COPY /Y "%XMLTEMPLATEFILE%" "%XMLPATH%\%XMLFILE%" >> %LOGFILE%

SET MSG=Replacing metadata template strings  ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Replace all M-occurrences in XML-template
FOR %%G IN (%MSTRINGLIST%) DO (
  ECHO   replacing %%G ...
  ECHO "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###%%G### "!%%G!" >> %LOGFILE%
  "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###%%G### "!%%G!" >> %LOGFILE%
)

IF NOT "%EXTENT%"=="" (
  FOR /F "tokens=1,2,3,4* delims=,_" %%a IN ("%EXTENT:,=_%") DO (
    SET XLL=%%a
    SET YLL=%%b
    SET XUR=%%c
    SET YUR=%%d
  ) 
  ECHO   replacing XLL ...
  ECHO "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###XLL### "!XLL!" >> %LOGFILE%
  "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###XLL### "!XLL!" >> %LOGFILE%
  ECHO   replacing YLL ...
  ECHO "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###YLL### "!YLL!" >> %LOGFILE%
  "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###YLL### "!YLL!" >> %LOGFILE%
  ECHO   replacing XUR ...
  ECHO "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###XUR### "!XUR!" >> %LOGFILE%
  "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###XUR### "!XUR!" >> %LOGFILE%
  ECHO   replacing YUR ...
  ECHO "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###YUR### "!YUR!" >> %LOGFILE%
  "%TOOLSPATH%\ReplaceText.exe" "%XMLPATH%" "%XMLFILE%" ###YUR### "!YUR!" >> %LOGFILE%
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
