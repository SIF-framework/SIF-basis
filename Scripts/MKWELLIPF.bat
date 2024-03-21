@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * MKWELLIPF.bat                          *
REM * DESCRIPTION                            *
REM *   Runs iMOD-batchfunction MKWELLIPF    *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.1                         *
REM * MODIFICATIONS                          *
REM *   2017-06-20 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM WELID:      Code/name/Id for output
REM IPFPATH:    Path to IPF-files
REM IPFFILES:   Comma separated list of IPF-files in IPFPATH
REM X/YCOL:     Specify columnnumbers (one based)
REM IQCOL:      Column number (one based) in the IPF-file that represents the extraction rate of the well. By default IQCOL=3.
REM ITCOL:      Column number (one based) in the IPF file that represents the top of the well screen, or leave empty. By default ITCOL=4.
REM IBCOL:      Column number (one based) in the IPF file that represents the bottom of the well screen, or leave empty. By default ITCOL=5.
REM FNODATA:    NoData-value for the top and bottom of the well screen, denoted by ITCOL and IBCOL. 
REM             By default FNODATA=-99999.0, values equal to this will be discarded. Leave empty to use default
REM IMIDF:      IMIDF-flag. Whenever IMIDF=0, the mid of a well screen is computed by the top and bottom screen heights if both available (not equal to the parameter NODATA). 
REM             Whenever IMODF=1, the mid of the screen is equal to the top of the screen whenever the bottom height might be absent, and equal to the bottom whenever the top is absent. 
REM             If both are available, the computation of the mid of the well screen is equal to the method described by IMIDF=0. By default IMIDF=0.
REM ISS:        ISS-flag determines whether a time average extraction volume needs to be computed for a specified period of time, for that case ISS need to be 1.
REM             By default ISS=0 and an average value is computed for the time series as a whole.
REM S/EDATE:    Start and end dates (yyyymmdd), if ISS=1
REM NLAY:       Number of layers from which well may be organized, or leave empty to skip 
REM *PATHS:     Specify paths if NLAY is greater than zero, or leave empty to skip
REM RESULTPATH: Name of the subdirectory where the scriptresults are stored
SET WELID=WML
SET IPFPATH=%ROOTPATH%\..\..\IBv21\Model\WORKIN\WEL\input\VERSION_2\%WELID%
SET IPFFILES=NOORD.IPF,ZUID.IPF
SET XCOL=1
SET YCOL=2
SET IQCOL=3
SET ITCOL=4
SET IBCOL=5
SET FNODATA=-9999
SET IMIDF=
SET ISS=1
SET SDATE=19940101
SET EDATE=20111231
SET NLAY=19
SET TOPPATH=%DBASEPATH%\ORG\TOP\VERSION_1\100
SET BOTPATH=%DBASEPATH%\ORG\BOT\VERSION_1\100
SET KDPATH=%WORKINPATH%\REF6\01 Bepalen kD-waarden\Controle\iMODValidator\analysis-imodfiles\KDW
SET CPATH=%WORKINPATH%\REF6\01 Bepalen kD-waarden\Controle\iMODValidator\analysis-imodfiles\VCW
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET INIFILE="%SCRIPTNAME%.INI"
REM IMODEXE:    Path and filename of iMOD-executable to use
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SETLOCAL EnableDelayedExpansion

REM Check that the specified paths exist
IF NOT EXIST "%IPFPATH%" (
   ECHO The specified IPFPATH does not exist: %IPFPATH%
   ECHO The specified IPFPATH does not exist: %IPFPATH% > %LOGFILE%
   GOTO error
)
IF NOT EXIST "%IMODEXE%" (
   ECHO The specified iMOD-executable does not exist: %IMODEXE%
   ECHO The specified iMOD-executable does not exist: %IMODEXE% > %LOGFILE%
   GOTO error
)

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Creating INI-file
ECHO FUNCTION=MKWELLIPF > %INIFILE%
IF NOT "%NLAY%"=="" (
  ECHO NLAY=%NLAY% >> %INIFILE%
  FOR /L %%a IN (1,1,19) DO (
    IF NOT "%TOPPATH%"=="" (
      ECHO TOPIDF%%a="%TOPPATH%\TOP_L%%a.IDF" >> %INIFILE%
    )
    IF NOT "%BOTPATH%"=="" (
      ECHO BOTIDF%%a="%BOTPATH%\BOT_L%%a.IDF" >> %INIFILE%
    )
  )
  IF NOT "%KDPATH%"=="" (
    FOR /L %%a IN (1,1,19) DO (
      ECHO KDIDF%%a="%KDPATH%\KD_L%%a.IDF" >> %INIFILE%
    )
  )
  IF NOT "%CPATH%"=="" (
    FOR /L %%a IN (1,1,18) DO (
      ECHO CIDF%%a="%CPATH%\C_L%%a.IDF" >> %INIFILE%
    )
  )
)
ECHO MINKHT=1.0 >> %INIFILE%
ECHO IXCOL=%XCOL% >> %INIFILE%
ECHO IYCOL=%YCOL% >> %INIFILE%
IF NOT "%ITCOL%"=="" ECHO ITCOL=%ITCOL% >> %INIFILE%
IF NOT "%IBCOL%"=="" ECHO IBCOL=%IBCOL% >> %INIFILE%
ECHO IQCOL=%IQCOL% >> %INIFILE%                          
ECHO ISS=%ISS% >> %INIFILE%
ECHO FNODATA=-9999 >> %INIFILE%
ECHO SDATE=%SDATE% >> %INIFILE%
ECHO EDATE=%EDATE% >> %INIFILE%
IF NOT "%FNODATA%"=="" ECHO FNODATA=%FNODATA% >> %INIFILE%
IF NOT "%IMIDF%"=="" ECHO IMIDF=%IMIDF% >> %INIFILE%
SET IDX=0
FOR %%D IN (%IPFFILES%) DO (
  SET /A IDX=IDX+1
  IF EXIST "%IPFPATH%\%%~nD" (
    ECHO WARNING: MKWELLIPF-outputpath already exists, press j+Enter to continue, or remove output to run script correctly: %%~nD
    ECHO WARNING: MKWELLIPF-outputpath already exists, press j+Enter to continue, or remove output to run script correctly: %%~nD >> %LOGFILE%
    CSCRIPT "%TOOLSPATH%\CreateLink.vbs" "WEL outputpath %%~nD - snelkoppeling.lnk" "%IPFPATH%\%%~nD" >nul
  )
)
ECHO NIPF=%IDX% >> %INIFILE%
SET MSG=Creating INI-file for IPF-files ... 
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
SET IDX=1
FOR %%D IN (%IPFFILES%) DO (
  SET MSG=   %%D
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  ECHO IPF!IDX!="%IPFPATH%\%%D" >> %INIFILE%
  SET /A IDX=IDX+1
)

SET MSG=Running iMOD-batch MKWELLIPF ... 
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

SET MSG=Moving results ... 
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
FOR %%D IN (%IPFFILES%) DO (
  SET SUBDIR=%%~nD
  SET MSG=   !SUBDIR!
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  IF NOT EXIST "%RESULTPATH%\%WELID%" MKDIR "%RESULTPATH%\%WELID%"
  IF EXIST "%RESULTPATH%\%WELID%\!SUBDIR!" RMDIR /Q /S "%RESULTPATH%\%WELID%\!SUBDIR!"
  ECHO MOVE /Y "%IPFPATH%\!SUBDIR!" "%RESULTPATH%\%WELID%" >> %LOGFILE%
  MOVE /Y "%IPFPATH%\!SUBDIR!" "%RESULTPATH%\%WELID%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
)

IF ERRORLEVEL 1 GOTO error
REM IF EXIST %INIFILE% DEL %INIFILE%

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
