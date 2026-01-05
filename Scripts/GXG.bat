@ECHO OFF
REM ******************************************
REM * SIF-basis v2.1.0 (Sweco)               *
REM *                                        *
REM * GxG.bat                                *
REM * DESCRIPTION                            *
REM *   Calculates GxG from transient head   *
REM *   IDF-files with iMOD-batchfunction.   *
REM * AUTHOR(S): Koen van der Hauw (Sweco)   *
REM * VERSION: 2.0.3                         *
REM * MODIFICATIONS                          *
REM *   2018-05-01 Initial version           *
REM ******************************************
CALL :Initialization
IF EXIST "%SETTINGSPATH%\SIF.Settings.iMOD.bat" CALL "%SETTINGSPATH%\SIF.Settings.iMOD.bat"

REM ********************
REM * Script variables *
REM ********************
REM IDFPATH:     Path to IDF-files
REM IDFPREFIX:   Prefix of filename for all files that need to be used, e.g. HEAD. This means that the GXG function will search for IDF-files that meet the name syntax requirement of HEAD_{yyyymmdd}_L{ILAY}.IDF.
REM ILAYER:      One of more (comma separated) layers to be used in the calculation
REM SURFACEIDF:  Path with filename of IDF-file to be used for the surface level
REM *YEAR:       Specify start and end year (yyyy) for which IDF-files are used
REM STARTMONTH:  Start month from the which the hydrological year starts, default is 4.
REM ISEL:        Code for the area to be processed: ISEL=1 will compute the entire region; ISEL=2 will compute within given polygons; ISEL=3 will compute for those cells in the given IDF-file that are not equal to the NoDataValue of that IDF-file.
REM GENNAME:     Path with GEN-filename for polygon(s) for which mean values need to be computed. This keyword is obliged whenever ISEL=2.
REM IDFNAME:     Path with IDF-filename for which mean values will be computed for those cells in the IDF-file that are not equal to the NoDataValue of that IDF-file. This keyword is compulsory whenever ISEL=3
REM HGLG3:       Indicates whether or not the HG3 and LG3 also need to be written as output per year
REM IMODEXE:     Path and filename of iMOD-executable to use. Note: until at least iMOD 5.5, the GVG is calculated with a formula based on the GHG/GVG and a different formula is used when SURFACEIDF is used.
REM ISDELRESULT: Specify (with value 1) that all old results should be deleted (to recycle bin) from RESULTPATH 
REM RESULTPATH:  Name of subdirectory where the scriptresults are stored
SET IDFPATH=%RESULTSPATH%\BASIS1\KHx5\HEAD
SET IDFPREFIX=HEAD
SET ILAYER=1
SET SURFACEIDF=%DBASEPATH%\ORG\MAAIVELD\MAAIVELDxxx.IDF
SET SYEAR=1997
SET EYEAR=2011
SET STARTMONTH=4
SET ISEL=1
SET GENNAME= 
SET IDFNAME=
SET HGLG3=0
SET IMODEXE=%IMODEXE%
SET ISDELRESULT=0
SET RESULTPATH=result

REM *********************
REM * Derived variables *
REM *********************
SET TEMPDIR=tmp
SET THISPATH=%~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET INIFILE="%SCRIPTNAME%.INI"
SET IMODEXE=%IMODEXE%

REM *******************
REM * Script commands *
REM *******************
TITLE SIF-basis: %SCRIPTNAME%

SETLOCAL EnableDelayedExpansion

REM Check that the specified paths exist
IF NOT EXIST "%IDFPATH%" (
  SET MSG=The specified IDFPATH does not exist: %IDFPATH%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

IF NOT EXIST "%IMODEXE%" (
  SET MSG=The specified IMODEXE does not exist: %IMODEXE%
  ECHO !MSG!
  ECHO !MSG! > %LOGFILE%
  GOTO error
)

REM Create empty result directory
IF "%ISDELRESULT%"=="1" (
  IF EXIST "%RESULTPATH%\*" (
    IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
      ECHO "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE%
      "%TOOLSPATH%\Del2Bin.exe" /E /S "%RESULTPATH%" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO Del2Bin.exe not found, deleting permanently ... >> %LOGFILE%
      ECHO DEL /Q "%RESULTPATH%\*" >> %LOGFILE%
      DEL /Q "%RESULTPATH%\*" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  ) 
)

REM Log settings
SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%
SET MSG=IDFPATH: %IDFPATH%
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
ECHO:

IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"

SET MSG=Calculating GxG ...
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%

ECHO FUNCTION=GXG > %INIFILE%
ECHO ILAYER=%ILAYER% >> %INIFILE%
ECHO NDIR=1 >> %INIFILE%
ECHO SOURCEDIR1=%IDFPATH%\%IDFPREFIX% >> %INIFILE%
IF DEFINED SURFACEIDF ECHO SURFACEIDF=%SURFACEIDF% >> %INIFILE%
ECHO SYEAR=%SYEAR% >> %INIFILE%
ECHO EYEAR=%EYEAR% >> %INIFILE%
ECHO STARTMONTH=%STARTMONTH% >> %INIFILE%
ECHO ISEL=%ISEL% >> %INIFILE%
IF "%ISEL%"=="2" (
  ECHO GENFILE=%GENNAME% >> %INIFILE%
)
IF "%ISEL%"=="3" (
  ECHO IDFNAME=%IDFNAME% >> %INIFILE%
)
IF NOT "%HGLG3%" == "" (
  ECHO HGLG3=%HGLG3% >> %INIFILE%
)
ECHO OUTPUTFOLDER1=%RESULTPATH% >> %INIFILE%

ECHO "%IMODEXE%" %INIFILE% >> %LOGFILE%
"%IMODEXE%" %INIFILE% >> %LOGFILE%
IF NOT EXIST "%RESULTPATH%\*.IDF" GOTO error
IF EXIST %INIFILE% DEL %INIFILE%

FOR %%G IN ("%RESULTPATH%\*.IDF") DO (
  ECHO   creating metadata for %%~nxG ...
  ECHO   creating metadata for %%~nxG ... >> %LOGFILE%
  ECHO   "iMODmetadata.exe" /o "%RESULTPATH%\%%~nG.MET" "" "" 1 "%MODELREF0%" "GXG layer(s) %ILAYER%, %SYEAR%-%EYEAR%" "%CONTACTORG%" IDF "" "" ="%IDFPATH%\!IDFPREFIX!" "See !THISPATH:%ROOTPATH%\=!%~nx0; iMOD-batchfunction GXG(ILAYER=%ILAYER%, %SYEAR%-%EYEAR%, MV=!SURFACEIDF:%ROOTPATH%\=!); iMOD: !iMODEXE:%ROOTPATH%\=!" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  "%TOOLSPATH%\iMODmetadata.exe" /o "%RESULTPATH%\%%~nG.MET" "" "" 1 "%MODELREF0%" "GXG layer(s) %ILAYER%, %SYEAR%-%EYEAR%" "%CONTACTORG%" IDF "" "" ="%IDFPATH%\!IDFPREFIX!" "See !THISPATH:%ROOTPATH%\=!%~nx0; iMOD-batchfunction GXG(ILAYER=%ILAYER%, %SYEAR%-%EYEAR%, MV=!SURFACEIDF:%ROOTPATH%\=!); iMOD: !iMODEXE:%ROOTPATH%\=!" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" "%CONTACTEMAIL%" >> %LOGFILE%
  IF ERRORLEVEL 1 GOTO error
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
ECHO !MSG!
ECHO !MSG! >> %LOGFILE%
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
