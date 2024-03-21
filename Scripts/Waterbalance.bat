@ECHO OFF
REM ******************************************
REM * SIF-basis v2.2.0 (Sweco)               *
REM *                                        *
REM * Maak waterbalans.bat                   *
REM * DESCRIPTION                            *
REM *   Create waterbalance for BDG-files    *
REM *   with iMOD-batchfunction WBALANCE and *
REM *   formats results in Excelsheet.       *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2016-05-01 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"
IF EXIST "%SETTINGSPATH%\SIF.Settings.Model.bat" CALL "%SETTINGSPATH%\SIF.Settings.Model.bat"

REM This script creates a waterbalance Excelsheet for specified steady state model result in the following two steps:
REM 1) use iMOD to create CSV-file with waterbalance terms and values based on BDG*.IDF-files that are part of the model results.
REM 2) use Sweco's iMODWBalFormat-tool to format the contents of the CSV-file into an Excelfile with a summary and sheets per zone

REM ********************
REM * Script variables *
REM ********************
REM MODELNAME:    Full name of model (as MODELNAME[_SUBMODELNAME[_POSTFIX]]), to define the DBASE-map that files should be copied to
REM WBAL_FNAME:   Balance filename (without CSV-extension). If SKIPIMOD=1 a path can be specified as well, otherwise specify just the filename without an extension
REM SKIPIMOD:     Specify (with value 1) that the creation of the waterbalance CSV-file with iMOD can be skipped and use an existing WBAL_FNAME CSV-file, or leave empty to do use iMOD to create CSV-file
REM WBAL_GENFILE: GEN-file with features to calculate waterbalance(s) for (ignored if SKIPIMOD=1)
REM WBAL_LAYERS:  Comma seperated list of layersnumbers to be included in waterbalance per zone (ignored if SKIPIMOD=1)
REM WBAL_SYSTEMS: Comma seperated list of systems to be included in the waterbalance CSV-file for OLF, ISG, RIV and DRN-packages if corresponding BDGxxx_SYSi IDF-files exist, or leave empty to not add SYS-files
REM IDCOLIDX:     Column index (zero-based) of the zone ID-column in the GEN-file which is specified in the CSV-file, or leave empty to use a sequence number for each zone
REM ISMF6:        Specify (with value 1) that a MF6-model is analysed
REM RESULTPATH:   Path where Excelfile will be written. The name of the Excelfile will be as specified by WBAL_FNAME
SET MODELNAME=ORG_BAS
SET WBAL_FNAME=WBALANCE_%MODELNAME% - bufferextent
SET SKIPIMOD=
SET WBAL_GENFILE=%SHAPESPATH%\MODELEXTENT.gen
SET WBAL_LAYERS=%MODELLAYERS%
SET WBAL_SYSTEMS=1,2,5,6
SET IDCOLIDX=
SET ISMF6=1
SET RESULTPATH=result

REM Specify metadata
SET METADATA_DATASOURCE=%MODELNAME%; %WBAL_GENFILE%
SET METADATA_PROCESSDESCRIPTION=Zie logboek XXX

REM *********************
REM * Derived variables *
REM *********************
SETLOCAL ENABLEDELAYEDEXPANSION
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET MODELPATH=%MODELNAME:_=\%
SET INIFILE="%SCRIPTNAME%.INI"
SET TEMPPATH=tmp
SET THISPATH=%~dp0
SET iMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

IF NOT "%SKIPIMOD%"=="1" (
  IF NOT EXIST "%TEMPPATH%" MKDIR "%TEMPPATH%"

  REM Note: somehow the waterbalance function doesn't work when BDGRCH or BDGISG is added to the balance, but not saved for the modelrun
  REM Because of this BDGRCH and RBGISG are only added when present in the resultsfolder
  SET NBAL=8
  SET NBALTMP=!NBAL!
  IF EXIST "%RESULTSPATH%\%MODELPATH%\bdgrch" (
    SET /A NBAL=NBAL+1
  ) ELSE (
    IF EXIST "%RESULTSPATH%\%MODELPATH%\BDGRCH_SYS1" (
      SET /A NBAL=NBAL+1
    )
  )
  IF EXIST "%RESULTSPATH%\%MODELPATH%\bdgisg" (
    SET /A NBAL=NBAL+1
  )

  ECHO FUNCTION=WBALANCE > %INIFILE%
  ECHO NBAL=!NBAL! >> %INIFILE%
  ECHO BAL1=BDGBND >> %INIFILE%
  ECHO BAL2=BDGFLF >> %INIFILE%
  ECHO BAL3=BDGFRF >> %INIFILE%
  ECHO BAL4=BDGFFF >> %INIFILE%
  ECHO BAL5=BDGOLF >> %INIFILE%
  IF NOT "%WBAL_SYSTEMS%"=="" (
    REM Check which BDGOLF SYS-files exist
    SET BAL5ISYS=
    FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgolf_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgolf
      )
      IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgolf_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
        SET BAL5ISYS=!BAL5ISYS!,%%D
      )
    )
    IF NOT "!BAL5ISYS!"=="" (
      SET BAL5ISYS=!BAL5ISYS:~1!
      ECHO BAL5ISYS=!BAL5ISYS! >> %INIFILE%
    )
  )
  ECHO BAL6=BDGRIV >> %INIFILE%
  IF NOT "%WBAL_SYSTEMS%"=="" (
    REM Check which BDGRIV SYS-files exist
    SET BAL6ISYS=
    FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgriv_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgriv
      )
      IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgriv_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
        SET BAL6ISYS=!BAL6ISYS!,%%D
      )
    )
    IF NOT "!BAL6ISYS!"=="" (
      SET BAL6ISYS=!BAL6ISYS:~1!
      ECHO BAL6ISYS=!BAL6ISYS! >> %INIFILE%
    )
  )
  ECHO BAL7=BDGDRN >> %INIFILE%
  IF NOT "%WBAL_SYSTEMS%"=="" (
    REM Check which BDGDRN SYS-files exist
    SET BAL7ISYS=
    FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgdrn_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgdrn
      )
      IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgdrn_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
        SET BAL7ISYS=!BAL7ISYS!,%%D
      )
    )
    IF NOT "!BAL7ISYS!"=="" (
      SET BAL7ISYS=!BAL7ISYS:~1!
      ECHO BAL7ISYS=!BAL7ISYS! >> %INIFILE%
    )
  )
  ECHO BAL8=BDGWEL >> %INIFILE%
  IF NOT "%WBAL_SYSTEMS%"=="" (
    REM Check which BDGDRN SYS-files exist
    SET BAL8ISYS=
    FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgwel_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgwel
      )
      IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgwel_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
        SET BAL8ISYS=!BAL8ISYS!,%%D
      )
    )
    IF NOT "!BAL8ISYS!"=="" (
      SET BAL8ISYS=!BAL8ISYS:~1!
      ECHO BAL8ISYS=!BAL8ISYS! >> %INIFILE%
    )
  )
  
  IF "%ISMF6%"=="1" (
    SET BDGPATH=bdgrch_%iMODFLOW_SYSTEM_SUBSTRING%1
  ) ELSE (
    SET BDGPATH=bdgrch
  )
  IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!" (
    SET /A NBALTMP=NBALTMP+1
    ECHO BAL!NBALTMP!=BDGRCH >> %INIFILE%
    FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgrch_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgrch
      )
      IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgrch_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
        SET BAL9ISYS=!BAL9ISYS!,%%D
      )
    )
    IF NOT "!BAL9ISYS!"=="" (
      SET BAL9ISYS=!BAL9ISYS:~1!
      ECHO BAL!NBALTMP!ISYS=!BAL9ISYS! >> %INIFILE%
    )
  )
  IF EXIST "%RESULTSPATH%\%MODELPATH%\bdgisg" (
    SET /A NBALTMP=NBALTMP+1
    ECHO BAL!NBALTMP!=BDGISG >> %INIFILE%
    IF NOT "%WBAL_SYSTEMS%"=="" (
      REM Check which BDGISG SYS-files exist
      SET BALISYS=
      FOR %%D IN (%WBAL_SYSTEMS%) DO (
      IF "%ISMF6%"=="1" (
        SET BDGPATH=bdgisg_%iMODFLOW_SYSTEM_SUBSTRING%%%D
      ) ELSE (
        SET BDGPATH=bdgisg
      )
        IF EXIST "%RESULTSPATH%\%MODELPATH%\!BDGPATH!\bdgisg_%iMODFLOW_SYSTEM_SUBSTRING%%%D_*.IDF" (
          SET BALISYS=!BALISYS!,%%D
        )
      )
      IF NOT "!BALISYS!"=="" (
        ECHO BAL!NBALTMP!ISYS=!BALISYS:~1! >> %INIFILE%
      )
    )
  )

  REM Correct for relative path
  IF NOT "%WBAL_GENFILE:~1,2%"==":\" SET WBAL_GENFILE=%THISPATH%%WBAL_GENFILE%
  
  REM ECHO BALx=BDGGHB >> %INIFILE%
  ECHO ILAYER=%WBAL_LAYERS% >> %INIFILE%
  ECHO NDIR=1 >> %INIFILE%
  ECHO SOURCEDIR1="%RESULTSPATH%\%MODELPATH%" >> %INIFILE%
  ECHO OUTPUTNAME1="%TEMPPATH%\%WBAL_FNAME%.CSV" >> %INIFILE%
  ECHO ISEL=2 >> %INIFILE%
  ECHO GENFILE="%WBAL_GENFILE%" >> %INIFILE%
  
  SET MSG=  MODEL='%MODELNAME%' 
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET MSG=  LAYERS=%WBAL_LAYERS%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  SET MSG=  SHAPE=%WBAL_GENFILE%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO:
  ECHO: >> %LOGFILE%
  
  REM Remove old csv outputfile
  IF EXIST "%TEMPPATH%\%WBAL_FNAME%.CSV" DEL "%TEMPPATH%\%WBAL_FNAME%.CSV"
  IF EXIST "%TEMPPATH%\%WBAL_FNAME%.XLSX" DEL "%TEMPPATH%\%WBAL_FNAME%.XLSX"
  
  SET MSG=Running WBALANCE iMOD-BATCH ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  IF NOT EXIST "%IMODEXE%" (
    SET MSG=iMOD executable not found: %IMODEXE%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
  ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
  "%IMODEXE%" %INIFILE% >> %LOGFILE%
  IF NOT EXIST "%TEMPPATH%\%WBAL_FNAME%.CSV" GOTO error

  REM IF EXIST %INIFILE% DEL %INIFILE%
  
) ELSE (
  ECHO Using existing CSV-file: %WBAL_FNAME%.CSV ...
  ECHO Using existing CSV-file: %WBAL_FNAME%.CSV ... >> %LOGFILE%
)

SET IDOPTION=
IF NOT "%IDCOLIDX%"=="" SET IDOPTION=/i:%IDCOLIDX%

SET MSG=Reformatting iMOD-BATCH CSV-file ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "iMODWBalFormat.exe" %IDOPTION% "%TEMPPATH%" "%WBAL_FNAME%.CSV" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\iMODWBalFormat.exe" %IDOPTION% "%TEMPPATH%" "%WBAL_FNAME%.CSV" "%RESULTPATH%" >> %LOGFILE%

IF ERRORLEVEL 1 GOTO error

REM If resultpath is different from CSV-path move XLSX to resultpath
SET FULL_WBAL_FNAME=%TEMPPATH%\%WBAL_FNAME%
IF "!FULL_WBAL_FNAME:%RESULTPATH%=!" == "!FULL_WBAL_FNAME!" (
  IF EXIST "%FULL_WBAL_FNAME%.XLSX" MOVE /Y "%FULL_WBAL_FNAME%.XLSX" "%RESULTPATH%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

:success
ECHO:
ECHO: >> %LOGFILE%
SET MSG=Script finished, see '%~n0.log'
ECHO %MSG%
ECHO %MSG% >> !LOGFILE!
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
