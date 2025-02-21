@ECHO OFF
REM ********************************************
REM * SIF-basis v2.1.0 (Sweco)                 *
REM *                                          *
REM * IPFsample.bat                            *
REM * DESCRIPTION                              * 
REM *   Samples IDF-files for given IPF-points *
REM * AUTHOR(S): Koen van der Hauw (Sweco)     *
REM * VERSION: 2.0.3                           *
REM * MODIFICATIONS                            *
REM *   2017-03-01 Initial version             *
REM ********************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM Sample IDF-file(s) with specified IPF-file(s) in one of the following ways:
REM 1) Use multiple IPF-files and a single IDF-file (1:n match) 
REM 2) Use multiple IPF-files and a set of IDF-files, that correspond to the IPF-files (n:n match)
REM 3) Define match pairs of IDF-IPF matches explictly (this allows for n:m or m:n matches)

REM ********************
REM * Script variables *
REM ********************
REM IPFPATH: Path to input IPF-file(s) with points to sample with
REM IDFPATH: Path to input IDF-file(s) with rasters to sample
SET IPFPATH=result
SET IDFPATH=%DBASEPATH%\BASIS0\MAAIVELD\25

REM Option 1: use of a single IDF-file
REM IPFFILTER:  Filter to IPF-file(s) in IPFPATH, with points to sample. Wildcards * and ? are allowed. Or leave empty if option 2 is used.
REM IDFFILE:    Filename of a single IDF-file in IPDFPATH to sample all IPF-files for. Or leave empty if option 2 is used.
SET IPFFILTER=kalibratieset_stat_totaal_ALL.IPF
SET IDFFILE=AHN25m.IDF

REM Option 2: Specify IPF- and IDF-files by a prefix and postfix (wildcards allowed). IPF-filenames should have the form: [IPFPATH]\[IPFPREFIX]*[POSTFIX].IPF. Likewise for IDF-files.
REM           corresponding IPF- and IDF-filenames match in all but the defined PREFIX/POSTFIX-strings. Note that for this option a wildcard is used between prefix and postfix.
REM Option 3: Specify substrings that should match for each pair of IDF/IDF-files. The IPF-filename of IDF/IPF-pair i then has the form: [IPFPATH]\[IPFPREFIX][SUBSTRING][POSTFIX].IPF
REM           with this method an IDF-file can be used for several IPF-files, or vice versa. Note that for this option no wildcards are used.
REM IPFPREFIX:     First part of IPF-filename to select IPF-files with
REM IPFPOSTFIX:    Last part of IPF-filename to select IPF-files with (excluding file extension), or leave empty if not relevant
REM IPFSUBSTRINGS: Comma-seperated list of substrings in selected IPF-filenames, between IPFPREFIX and IPFPOSTFIX, or leave empty if not used and select only with PRE-/POSTFIX-filters
REM IDPREFIX:      First part of IDF-filename to select corresponding IDF-files with
REM IDFPOSTFIX:    Last part of IDF-filename to select corresponding IDF-files with (excluding file extension), or leave empty if not relevant
REM IPFSUBSTRINGS: Comma-seperated list of substrings in selected, corresponding IDF-filenames, between IPFPREFIX and IPFPOSTFIX, or leave empty if not used and select only with PRE-/POSTFIX-filters
SET IPFPREFIX=
SET IPFPOSTFIX=
SET IPFSUBSTRINGS=
SET IDFPREFIX=
SET IDFPOSTFIX=
SET IDFSUBSTRINGS=

REM IPFCOLUMN:       Optional columnindex (zero based) or column name in IPF-file (or leave empty to skip) with value to compare with IDF-value and calculate statistics for (which are saved in IPF-file and in CSV-file ipfsamplerstats.csv
REM ISINTERPOLATED:  Specify (with value 1) that grid values should be interpolated bilinearly (based on 4 surrounding gridvalues) to location of point in grid-cell; otherwise no interpolation is performed and the gridvalues is returned.
REM ISSKIPNODATA:    Specify (with value 1) that points in NoData-cells for the specified IDF-file should be skipped from the results
REM ISSKIPNAN:       Specify (with value 1) that points with invalid measurement values (e.g. NaN) in a specified IPF-file should be skipped from the results
REM ISSKIPOUTSIDE:   Specify (with value 1) that points outside the IDF-extent should be skipped from the results
REM ISMETADATAADDED:      Specify with (value 1) to add metadata file for each resulting IPF-file, or leave empty to skip
REM METADATA_DESCRIPTION: Metadata description to be addded to metadata of output IPF-file. The metadata source is added automatically
REM RESULTPATH:      Path to write result file(s) to
REM RESULTFILE:      When IPFFILTER is defined and is a single file, a single resultfilename can be specified
REM RESULTPOSTFIX:   Optional postfix (if RESULTFILE is not defined) to add to output IPF-filename(s) and to extra columnnames in IPF-file with statistics: RES and ABSRES, for residual/difference and absolute residual. Setting IPFCOLUMN is obligatory then. Otherwise, leave empty.
SET IPFCOLUMN=6
SET ISINTERPOLATED
SET ISSKIPNODATA=1
SET ISSKIPNAN=1
SET ISSKIPOUTSIDE=1
SET ISMETADATAADDED=
SET METADATA_DESCRIPTION=Geprikt en geinterpoleerd
SET RESULTPATH=result
SET RESULTFILE=
SET RESULTPOSTFIX=

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check valid input combinations
SET IPFPREPOSTFIX=%IPFPREFIX%%IPFPOSTFIX%
IF DEFINED IPFFILTER IF DEFINED IPFPREPOSTFIX (
  SET MSG=ERROR: Specify either IPFFILTER/IDFFILE or IPFPREFIX/IDFPREFIX-combination
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)
IF NOT DEFINED IPFFILTER IF NOT DEFINED IPFPREPOSTFIX (
  SET MSG=ERROR: Specify either IPFFILTER/IDFFILE or IPFPREFIX/IDFPREFIX-combination
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

REM Check that the specified paths exist
IF NOT EXIST "%IPFPATH%" (
  SET MSG=ERROR: The specified IPFPATH does not exist: %IPFPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)
IF DEFINED IDFPATH IF NOT EXIST "%IDFPATH%" (
  SET MSG=ERROR: The specified IDFPATH does not exist: %IDFPATH%
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)
IF DEFINED IDFFILE (
  SET MSG=
  IF DEFINED IDFPATH (
    IF NOT EXIST "%IDFPATH%\%IDFFILE%" (
      SET MSG=ERROR: The specified IDFFILE does not exist: %IDFPATH%\%IDFFILE%
    )
  ) ELSE (
    IF NOT EXIST "%IDFFILE%" (
      SET MSG=ERROR: The specified IDFFILE does not exist: %IDFFILE%
    )
  )
  IF DEFINED MSG (
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)

REM Create arrays for IPFSUBSTRINGS and IDFSUBSTRINGS input and check for equal lengths
SET Np=0
FOR %%D in (%IPFSUBSTRINGS%) DO (
  SET IPFSUBSTRINGS_ARR[!Np!]=%%D
  SET /A Np=Np+1
)
SET Nd=0
FOR %%D in (%IDFSUBSTRINGS%) DO (
  SET IDFSUBSTRINGS_ARR[!Nd!]=%%D
  SET /A Nd=Nd+1
)
IF NOT %Np%==%Nd% (
  ECHO Ensure that number of IPFSUBSTRINGS (%Np%^) equals the number of IDFSUBSTRINGS (%Nf%^)
  GOTO error
)
SET /A Np=!Np!-1
SET /A Nd=!Nd!-1

SET SOPTION=
SET IOPTION=
SET NOPTION=
SET XOPTION=
SET EOPTION=
IF NOT "%IPFCOLUMN%"=="" (
  IF NOT "%RESULTPOSTFIX%"=="" (
    SET SOPTION=/s:%IPFCOLUMN%,"%RESULTPATH%\ipfsamplerstats.csv",%RESULTPOSTFIX% 
  ) ELSE (
    SET SOPTION=/s:%IPFCOLUMN%,"%RESULTPATH%\ipfsamplerstats.csv"
  )
)
IF "%ISINTERPOLATED%"=="1" SET IOPTION=/i
IF "%ISSKIPNODATA%"=="1" SET NOPTION=/n
IF "%ISSKIPNAN%"=="1" SET XOPTION=/x
IF "%ISSKIPOUTSIDE%"=="1" SET EOPTION=/e

SET RESULTFILE_ORG=%RESULTFILE%
IF DEFINED IPFFILTER (
  SET MSG=Sampling IPF-files with %IPFFILTER% ...
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  IF DEFINED IDFPATH (
    SET IDFFILE=%IDFPATH%\%IDFFILE%
  )
  FOR %%G IN ("%IPFPATH%\%IPFFILTER%") DO (
    SET MSG=  sampling %%~nxG ...
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    SET RESULTFILE=%RESULTFILE_ORG%
    IF NOT DEFINED RESULTFILE SET RESULTFILE=%%~nG%RESULTPOSTFIX%.IPF
    ECHO "%TOOLSPATH%\IPFsample.exe" /o %EOPTION% %IOPTION% /d:2 %SOPTION% %NOPTION% %XOPTION% "%%~dpG " "%%~nxG" "!IDFFILE!" "%THISDIR%%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
    "%TOOLSPATH%\IPFsample.exe" /o %IOPTION% %EOPTION% /d:2 %SOPTION% %NOPTION% %XOPTION% "%%~dpG " "%%~nxG" "!IDFFILE!" "%THISDIR%%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
    IF ERRORLEVEL 1 GOTO error
  )

  IF "%ISMETADATAADDED%"=="1" (
    SET MSG=Adding metadata for %IPFFILTER% ...
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%

    FOR %%G IN ("%RESULTPATH%\!IPFFILTER:.IPF=%RESULTPOSTFIX%.IPF!") DO (
      ECHO   creating metadata for %%~nG ...
      ECHO "iMODmetadata.exe" "%%~dpnG.IPF" "" "" 1 ="%MODELREF0% %MODELNAME%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" "" "" "" "%IPFPATH%; !THISDIR:%ROOTPATH%\=! " "!THISDIR:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
      "%TOOLSPATH%\iMODmetadata.exe" "%%~dpnG.IPF" "" "" 1 ="%MODELREF0% %MODELNAME%" "%METADATA_DESCRIPTION%" "%CONTACTORG%" "" "" "" "%IPFPATH%; !THISDIR:%ROOTPATH%\=! " "!THISDIR:%ROOTPATH%\=!%SCRIPTNAME%.bat" ="%MODELREF0%" "%CONTACTORG%" "%CONTACTSITE%" "%CONTACTPERSON%" %CONTACTEMAIL% >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    )
  )
) ELSE (
  REM Define dummy empty substrings when no substrings were defined
  IF NOT DEFINED IPFSUBSTRINGS (
    SET IPFSUBSTRINGS_ARR[0]=
    SET IDFSUBSTRINGS_ARR[0]=
    SET Np=0
    SET Nd=0
  )
  
  FOR /L %%i IN (0,1,!Np!) DO (
    SET IPFSUBSTRING=!IPFSUBSTRINGS_ARR[%%i]!
    SET IDFSUBSTRING=!IDFSUBSTRINGS_ARR[%%i]!
    
    IF DEFINED IPFSUBSTRING (
      SET FULLIPFFILTER=%IPFPREFIX%!IPFSUBSTRING!%IPFPOSTFIX%.IPF
    ) ELSE (
      SET FULLIPFFILTER=%IPFPREFIX%*%IPFPOSTFIX%.IPF
    )

    SET MSG=Sampling IPF-files with filter '!FULLIPFFILTER!' ...
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
  
    FOR %%G IN ("%IPFPATH%\!FULLIPFFILTER!") DO (
      SET IPFFILENAME=%%~nxG
      IF EXIST "%IPFPATH%\!IPFFILENAME!" (
        SET MSG=  processing IPF-file %%~nxG ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        SET IDFFILENAME=!IPFFILENAME:.IPF=!
        IF DEFINED IPFSUBSTRING (
          REM Replace complete IPF-filename with corresponding IDF-filename
          SET IDFFILENAME=%IDFPREFIX%!IDFSUBSTRING!%IDFPOSTFIX%
        ) ELSE (
          REM Replace IPFPREFIX with IDFPREFIX and IPFPOSTFIX with IDFPOSTFIX
          IF NOT "%IPFPREFIX%"=="" (
            SET IDFFILENAME=!IDFFILENAME:%IPFPREFIX%=%IDFPREFIX%!
          ) ELSE (
            SET IDFFILENAME=%IDFPREFIX%!IDFFILENAME!
          )
          IF NOT "%IPFPOSTFIX%"=="" (
            SET IDFFILENAME=!IDFFILENAME:%IPFPOSTFIX%=%IDFPOSTFIX%!
          ) ELSE (
            SET IDFFILENAME=!IDFFILENAME!%IDFPOSTFIX%
          )
        )
      
        SET IDFFILENAME=!IDFFILENAME!.IDF
        SET MSG=    searching corresponding IDF-file !IDFFILENAME! ...
        REM ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        IF EXIST "%IDFPATH%\!IDFFILENAME!" (
          SET RESULTFILE=%RESULTFILE_ORG%
          IF NOT DEFINED RESULTFILE SET RESULTFILE=!IPFFILENAME:.IPF=%RESULTPOSTFIX%.IPF!
          SET MSG=    sampling IDF-file !IDFFILENAME! ...
          ECHO !MSG!
          ECHO !MSG! >> %LOGFILE%
          ECHO "%TOOLSPATH%\IPFsample.exe" /o %EOPTION% %IOPTION% /d:2 %SOPTION% %NOPTION% %XOPTION% "%IPFPATH%" "!IPFFILENAME!" "%IDFPATH%\!IDFFILENAME!" "%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
          "%TOOLSPATH%\IPFsample.exe" /o %EOPTION% %IOPTION% /d:2 %SOPTION% %NOPTION% %XOPTION% "%IPFPATH%" "!IPFFILENAME!" "%IDFPATH%\!IDFFILENAME!" "%RESULTPATH%\!RESULTFILE!" >> %LOGFILE%
          IF ERRORLEVEL 1 GOTO error
        ) ELSE (
          ECHO     no corresponding IDF-file found, IPF-file skipped >> %LOGFILE%
        )
      ) ELSE (
        ECHO   IPF-file not found and skipped
        ECHO   IPF-file not found and skipped >> %LOGFILE%
      )
    )
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
