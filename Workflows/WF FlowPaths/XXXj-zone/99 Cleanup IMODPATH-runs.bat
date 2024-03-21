@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * Cleanup flowfiles.bat                   *
REM * DESCRIPTION                             * 
REM *   Removes/zips large intermediate files *
REM *   of BW/FW IMODPATH-calculation(s) and  *
REM *   is part of the FlowPath workflow      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2018-12-01 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM Specify flowpath files to cleanup
SET BW_SUBSTR=BW_9c%FPBW_ISD_N1:.0=%m%FPBW_ISD_VIN%x_%TYPESTRING%
SET BW_IFFFILE=%RESULTPATH_RUNS%\%BW_SUBSTR%\%MODELREF%_%BW_SUBSTR%.IFF
SET BW_IPFFILE=%RESULTPATH_RUNS%\%BW_SUBSTR%\%MODELREF%_%BW_SUBSTR%.IPF
SET BW_IPFEPFILE=%RESULTPATH_RUNS%\%BW_SUBSTR%\%MODELREF%_%BW_SUBSTR%_EP.IPF
SET BW_PNTFILE=%RESULTPATH_RUNS%\%BW_SUBSTR%\%MODELABBR%_%BW_SUBSTR%.PNT
SET FW_SUBSTR=FW_CHULLBUFFER
SET FW_IFFFILE=%RESULTPATH_RUNS%\%FW_SUBSTR%\%MODELREF%_%FW_SUBSTR%.IFF
SET FW_IPFFILE=%RESULTPATH_RUNS%\%FW_SUBSTR%\%MODELREF%_%FW_SUBSTR%.IPF
SET FW_IPFEPFILE=%RESULTPATH_RUNS%\%FW_SUBSTR%\%MODELREF%_%FW_SUBSTR%_EP.IPF
SET FW_PNTFILE_L=%RESULTPATH_RUNS%\%FW_SUBSTR%\%MODELABBR%_%FW_SUBSTR%-L.PNT
SET FW_PNTFILE_P=%RESULTPATH_RUNS%\%FW_SUBSTR%\%MODELABBR%_%FW_SUBSTR%-P.PNT

REM Specify files to delete
SET DELFILES=%BW_IPFEPFILE%,%BW_PNTFILE%,%FW_IFFFILE%,%FW_IPFEPFILE%,%FW_PNTFILE_L%,%FW_PNTFILE_P%

REM Specify files to first zip and then delete
SET ZIPFILES=%BW_IFFFILE%,%BW_IPFFILE%,%FW_IPFFILE%

REM Specify deleted foldernames
SET DELPATHS=tmp,IMOD_TMP

REM *********************
REM * Derived variables *
REM *********************
SET SCRIPTNAME=%~n0
SET THISPATH=%~dp0
SET LOGFILE="%THISPATH%%SCRIPTNAME%.log"
SET ZIP7EXE=C:\Program Files\7-Zip\7z.exe

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

SET MSG=Starting script '%SCRIPTNAME%' ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

SET MSG=deleting temporary files ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
IF DEFINED DELFILES (
  FOR %%D IN (%DELFILES%) DO (
    IF EXIST "%%D" (
      ECHO     deleting to recycle bin %%D ... 
      ECHO "%TOOLSPATH%\Del2Bin.exe" /F /E "%%D" >> %LOGFILE%
      "%TOOLSPATH%\Del2Bin.exe" /F /E "%%D" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
      ECHO: >> %LOGFILE%
    ) ELSE (
      ECHO     file not found: %%~nxD ...
      ECHO     file not found: %%D ... >> %LOGFILE%
    )
  )
)

IF DEFINED DELPATHS (
  SET MSG=deleting temporary folders ...
  ECHO   !MSG!
  ECHO !MSG! >> %LOGFILE%
  FOR %%D IN (%DELPATHS%) DO (
    SET DELETEDPATH=%%D
    SET DELETEDPATH=!DELETEDPATH:"=!

    IF "!DELETEDPATH!"=="%~dp0" (
      SET MSG=DELETEDPATH cannot be equal to current path %~dp0
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="%~dp0\" (
      SET MSG=DELETEDPATH cannot be equal to current path %~dp0\
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="." (
      SET MSG=DELETEDPATH cannot be equal to current path '.'
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"==".." (
      SET MSG=DELETEDPATH cannot be equal to previous path '..'
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH!"=="" (
      SET MSG=DELETEDPATH cannot be empty
      ECHO !MSG!
      ECHO !MSG! >> %LOGFILE%
      GOTO error
    )

    IF "!DELETEDPATH:~1,1!" == ":" (
      SET ROOTDIR=!DELETEDPATH:~3!
      IF "!ROOTDIR:\=!"=="!ROOTDIR!" (
	REM No backslashes found after X:\ 
        SET MSG=DELETEDPATH cannot be equal to single directory under root 'X:\YYY'
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        GOTO error
      )
    )

    SET MSG=removing !DELETEDPATH:%ROOTPATH%\=! ...
    ECHO     !MSG!
    ECHO !MSG! >> %LOGFILE%
    IF "%ISNOTRECYCLED%"=="1" (
      ECHO IF EXIST "!DELETEDPATH!" RMDIR /Q /S "!DELETEDPATH!" >> %LOGFILE%
      IF EXIST "!DELETEDPATH!" RMDIR /Q /S "!DELETEDPATH!" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO IF EXIST "!DELETEDPATH!" "%TOOLSPATH%\Del2Bin.exe" /e /s "!DELETEDPATH!" >> %LOGFILE%
      IF EXIST "!DELETEDPATH!" "%TOOLSPATH%\Del2Bin.exe" /e /s "!DELETEDPATH!" >> %LOGFILE% 2>&1
      IF ERRORLEVEL 1 GOTO error
    )
  )
)

REM Check that ZIP7EXE exists
IF NOT EXIST "%ZIP7EXE%" (
  ECHO   ZIP7EXE-file not found: %ZIP7EXE%
  ECHO   ZIP7EXE-file not found: %ZIP7EXE% >> %LOGFILE%
  ECHO   Skipped zipping/cleanup of: %ZIPFILES%
  ECHO   Skipped zipping/cleanup of: %ZIPFILES% >> %LOGFILE%
  GOTO warning
) 

SET MSG=zipping and deleting temporary files ...
ECHO   %MSG%
ECHO %MSG% >> %LOGFILE%
IF DEFINED ZIPFILES (
  FOR %%D IN (%ZIPFILES%) DO (
    IF EXIST "%%D" (
      ECHO     zipping %%~nxD ...
      ECHO     zipping %%D ... >> %LOGFILE%
      
      ECHO CD %%~dpD >> %LOGFILE%
      CD %%~dpD
      
      ECHO "%ZIP7EXE%" a -tzip "%%~nxD.zip" "%%~nxD" >> %LOGFILE%
      "%ZIP7EXE%" a -tzip "%%~nxD.zip" "%%~nxD" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
      
      ECHO     deleting to recycle bin %%~nxD ...
      ECHO     deleting to recycle bin %%D ... >> %LOGFILE%
      ECHO "%TOOLSPATH%\Del2Bin.exe" /F /E "." "%%~nxD" >> %LOGFILE%
      "%TOOLSPATH%\Del2Bin.exe" /F /E "." "%%~nxD" >> %LOGFILE%
      IF ERRORLEVEL 1 GOTO error
    ) ELSE (
      ECHO     file not found: %%~nxD ...
      ECHO     file not found: %%D ... >> %LOGFILE%
    )
    CD %THISPATH%
  )
)

IF DEFINED TMPDIR (
  IF EXIST "%TMPDIR%" (
    ECHO RMDIR /S /Q "%TMPDIR%" >> %LOGFILE%
    RMDIR /S /Q "%TMPDIR%" >> %LOGFILE% 2>&1
    IF ERRORLEVEL 1 GOTO error
  )
)

:success
ECHO: 
ECHO: >> %LOGFILE%
SET MSG=Script finished, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel 0 for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:warning
ECHO: 
ECHO: >> %LOGFILE%
SET MSG=Script finished WITH WARNINGS, see "%~n0.log"
ECHO %MSG%
ECHO %MSG% >> %LOGFILE%
REM Set errorlevel 0 for higher level scripts
CMD /C "EXIT /B 0"
GOTO exit

:error
ECHO: 
ECHO: >> %LOGFILE%
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
