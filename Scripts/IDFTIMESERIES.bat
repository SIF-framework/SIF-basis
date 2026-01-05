@ECHO OFF
REM ********************************************
REM * SIF-basis v2.1.0 (Sweco)                 *
REM *                                          *
REM * IDFTIMESERIE.bat                         *
REM * DESCRIPTION                              *
REM *   Runs iMOD-batchfunction IDFTIMESERIE   *
REM *   to retrieves timeseries from IDF-files *
REM * AUTHOR(S): Koen van der Hauw (Sweco)     *
REM * VERSION: 2.0.2                           *
REM * MODIFICATIONS                            *
REM *   2019-03-06 Initial version             *
REM ********************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH:          Path to input IPF-file(s)
REM IPFPREFIXES:      List of prefixes (comma seperated), before layernumber string '_Li', for IPF-files to process and retrieve timeseries for, e.g. 'meetreeksen'
REM XYCOLIDX:         X and Y columnindices (one-based), normally 1 and 2
REM IPFCOLUMNSTRINGS: Specify commaseperated list of other (one-based) columnindices or columnnames of columns to copy into result IPF-files, or leave empty to use source files completely
REM IPFMODELLAYERS:   List of (comma seperated) modellayer numbers of IPF-files to process. Note '_L' is added before the specified modellayer number i to find IPF-file named [IPFPREFIX]_L[i].IPF
REM IDFMODELLAYERS:   List of (comma seperated) modellayer numbers of IDF-files to process that correspond with IPFMODELLAYERS, or leave empty to use all IPFMODELLAYERS. These modellayers are selected in IDFPATH by IDFTIMESERIES-batchfunction
REM IDFPATH:          Path to IDF-files with modelresults
REM IDFPREFIX:        First part of the filename for all IDF-files that need to be used, e.g. HEAD. The IDFTIMESERIE-function will search for IDF-files that meet the name syntax requirement of {IDFPREFIX}_{yyyymmdd}_L{ILAY}.IDF.
REM S/EDATE:          Specify start and end date and time (yyyymmddhhmmss) for which IDF-files are processed, or leave empty to use first/last HEAD-file
REM LABELCOL:         Columnindex (one-based) to be used for labelling the associated text files, or leave empty to use default (LABELCOL=0) and filename 'ts_measure' 
REM RESULTPATH:       Path for writing scriptresults
REM POSTFIX:          Postfix for result IPF-file(s), before layernumber string '_Li', or leave empty
REM ISNODATABUGFIXED: Specify with value 1 that invalid "Calculated,0.0000000" definitions in the associated-files should be repaced by "Calculated,0.34028235E+39". This occurs at least in iMOD v5.2.
REM                     Note1: this will be done recursively for all TXT-files in RESULTPATH. 
REM                     Note2: this bug occurs when a new TXT-file is created; when adding to an existing TXT-file the NoData-value seems to be set correctly.
REM NODATAFIXVALUE:   NoData-value to use in TXT-values for values from IDF-files, or leave empty to retrieve from IDF-files
SET IPFPATH=..\00 IPFanalysis\result
SET IPFPREFIXES=kalibratieset
SET XCOLIDX=1
SET YCOLIDX=2
SET IPFCOLUMNSTRINGS=ID,filternr,top,bot,surfacelvl,LayerNr,LayerName
SET IPFMODELLAYERS=1,2,3,4,5,6
SET IDFMODELLAYERS=1,1,1,5,5,5
SET IDFPATH=%RESULTSPATH%\ORG\BAS-NS\head
SET IDFPREFIX=head
SET SDATE=
SET EDATE=
SET LABELCOL=
SET RESULTPATH=result\ts-IDF
SET POSTFIX=
SET ISNODATABUGFIXED=1
SET NODATAFIXVALUE=0.34028235E+39

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET IMODEXE=%EXEPATH%\iMOD\%IMODEXE%
SET REPLACETEXTEXE=%TOOLSPATH%\ReplaceText.exe

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SETLOCAL EnableDelayedExpansion

REM Check that the specified paths exist
IF NOT EXIST "%IPFPATH%" (
  SET MSG=IPFPATH is niet gevonden: %IPFPATH%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

REM Ensure results directories exist
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF NOT EXIST "%TEMPDIR%" MKDIR "%TEMPDIR%"

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT DEFINED IDFMODELLAYERS SET IDFMODELLAYERS=%IPFMODELLAYERS%

REM Create arrays for MODELLAYER-input
SET Nr1=0
FOR %%a in (%IPFMODELLAYERS%) do (
  SET IPFMODELLAYERS_ARR[!Nr1!]=%%a
  SET /A Nr1=Nr1+1
)
SET Nr2=0
FOR %%a in (%IDFMODELLAYERS%) do (
  SET IDFMODELLAYERS_ARR[!Nr2!]=%%a
  SET /A Nr2=Nr2+1
)
IF NOT %Nr1%==%Nr2% (
  SET MSG=Number of IPFMODELLAYERS is not equal to number of IDFMODELLAYERS
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)
SET /A Nr1=Nr1-1

REM Retrieve NoData-value of IDF-files when fix of IDFTIMESERIE-bug is requested.
IF "%ISNODATABUGFIXED%"=="1" (
  IF NOT DEFINED NODATAFIXVALUE (
    SET MSG=Retrieving NoData-value in IDF-files for fixing IDFTIMESERIE-bug ...
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
  
    REM Retrieve NoData-value of any of the specified IDF-files
    SET IDFFILENAME=
    FOR %%D IN ("%IDFPATH%\%IDFPREFIX%*.IDF") DO SET IDFFILENAME=%%D
  
    REM Retrieve NoData-value
    FOR /F "tokens=* delims=" %%a IN ('CALL "%TOOLSPATH%\IDFinfo.exe" /n "!IDFFILENAME!"') DO SET NODATAFIXVALUE=%%a
    ECHO   using NoData-value of IDF-files: !NODATAFIXVALUE!
  )
)

REM Start matching specified IPF-files with corresponding HEAD-fils
ECHO Processing HEAD-files with prefix '%IDFPREFIX%' in: %IDFPATH% ...
ECHO Processing HEAD-files with prefix '%IDFPREFIX%' in: %IDFPATH% ... >> %LOGFILE%

FOR %%G IN (%IPFPREFIXES%) DO (
  ECHO   Processing calibratieset %%G ...
  FOR /L %%i IN (0,1,%Nr1%) DO (
    SET IPFLAYER=!IPFMODELLAYERS_ARR[%%i]!
    SET IDFLAYER=!IDFMODELLAYERS_ARR[%%i]!

    SET IPFFILENAME1=%IPFPATH%\%%G_L!IPFLAYER!.IPF
    IF NOT EXIST "!IPFFILENAME1!" (
      ECHO     File not found and skipped: !IPFFILENAME1:%ROOTPATH%\=!
      ECHO     File not found and skipped: !IPFFILENAME1:%ROOTPATH%\=! >> %LOGFILE%
      REM GOTO error
    ) ELSE (
      ECHO     Processing IPF-file %%G_L!IPFLAYER!.IPF ...
      IF EXIST "%IDFPATH%\%IDFPREFIX%*_L!IDFLAYER!.IDF" (
        IF NOT "%IPFCOLUMNSTRINGS%"=="" (
          ECHO "%TOOLSPATH%\IPFreorder" /o "!IPFFILENAME1!" "%TEMPDIR%\%%G_L!IPFLAYER!.IPF" %XCOLIDX% %YCOLIDX% %IPFCOLUMNSTRINGS:,= % >> %LOGFILE%
          "%TOOLSPATH%\IPFreorder.exe" /o "!IPFFILENAME1!" "%TEMPDIR%\%%G_L!IPFLAYER!.IPF" %XCOLIDX% %YCOLIDX% %IPFCOLUMNSTRINGS:,= % >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
          SET IPFFILENAME1=%TEMPDIR%\%%G_L!IPFLAYER!.IPF
        )

        REM Create output filename
        SET IPFFILENAME2=%RESULTPATH%\%%G%POSTFIX%_L!IPFLAYER!.IPF

        REM Creating INI-file for IDFTIMESERIE
        ECHO FUNCTION=IDFTIMESERIE > %INIFILE%
        ECHO IPF1="!IPFFILENAME1!" >> %INIFILE%
        ECHO IPF2="!IPFFILENAME2!" >> %INIFILE%
        ECHO ILAY=!IDFLAYER! >> %INIFILE%
        ECHO SOURCEDIR="%IDFPATH%\%IDFPREFIX%" >> %INIFILE%
        IF NOT "%SDATE%"=="" (
          ECHO SDATE=%SDATE% >> %INIFILE%
        )
        IF NOT "%EDATE%"=="" (
          ECHO EDATE=%EDATE% >> %INIFILE%
        )
        IF NOT "%LABELCOL%"=="" (
          ECHO LABELCOL=%LABELCOL% >> %INIFILE%
        )

        ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
        "%IMODEXE%" %INIFILE% >> %LOGFILE%
        IF ERRORLEVEL 1 GOTO error
        IF NOT EXIST "!IPFFILENAME2!" GOTO error

        REM Delete temporary IPF-files that is created when column reordering was specified
        IF NOT "%IPFCOLUMNSTRINGS%"=="" (
          ECHO IF EXIST "!IPFFILENAME1!" DEL /Q "!IPFFILENAME1!" >> %LOGFILE%
          IF EXIST "!IPFFILENAME1!" DEL /Q "!IPFFILENAME1!" >> %LOGFILE%
        )
      ) ELSE (
        ECHO       no %IDFPREFIX%-files found for layer !IDFLAYER! and skipped: !IPFFILENAME1:%ROOTPATH%\=!
        ECHO       no %IDFPREFIX%-files found for layer !IDFLAYER! and skipped: !IPFFILENAME1! >> %LOGFILE%
      )
    )
  )
)

IF EXIST %INIFILE% DEL %INIFILE%
IF DEFINED TEMPDIR (
  ECHO IF EXIST "%TEMPDIR%" RMDIR /Q /S "%TEMPDIR%" >> %LOGFILE%
  IF EXIST "%TEMPDIR%" RMDIR /Q /S "%TEMPDIR%"
)

REM Fix IDFTIMESERIE-bug if requested
IF "%ISNODATABUGFIXED%"=="1" (
  SET MSG=  Fixing IDFTIMESERIE-bug with NoData-definition in associated files with NoData-value !NODATAFIXVALUE! ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
 
  ECHO "%REPLACETEXTEXE%" /m /l:%LOGFILE% /r "%RESULTPATH%" "*.TXT" "Calculated,0.0000000" "Calculated,!NODATAFIXVALUE!" >> %LOGFILE%
  "%REPLACETEXTEXE%" /m /l:%LOGFILE% /r "%RESULTPATH%" "*.TXT" "Calculated,0.0000000" "Calculated,!NODATAFIXVALUE!" >> %LOGFILE%
  SET RESULT=!ERRORLEVEL!
  IF !RESULT! GEQ 0 (
    IF !RESULT!==0 (
      ECHO     no matches found
      ECHO     no matches found >> %LOGFILE%
    ) ELSE (
      ECHO     number of matches found: !RESULT! 
      ECHO     number of matches found: !RESULT! >> %LOGFILE%
    )  
  ) ELSE (
    GOTO error
  )
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
