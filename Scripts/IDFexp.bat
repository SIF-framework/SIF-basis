@ECHO OFF
REM *******************************************
REM * SIF-basis v2.1.0 (Sweco)                *
REM *                                         *
REM * IDFexp.bat                              *
REM * DESCRIPTION                             *
REM *   Processes IDF-expressions in INI-file *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2018-02-28 Initial version            *
REM *******************************************
CALL :Initialization

REM ********************
REM * Script variables *
REM ********************
REM INIFILE:       Path to INI-file, or leave empty to use %SCRIPTNAME%.INI
REM EXTENT:        Specify processing extent (xll,yll,xur,yur) or IDF-filename, or leave empty to use defaults (see below). 
REM                  Note: input IDF-files are clipped or enlarged with NoData to input IDF-files. Use in combination with option v to specify use of NoData-value
REM                  Warning: be aware that errors in input IDF-files may be masked when using this option. See option /e below for extent rules when no extent is specified.
REM IDFEXPOPTIONS: Specify IDFexp options (e.g. /v for NoData-value, see below for more info)
REM RESULTPATH:    Name of the subdirectory where the scriptresults are stored. Note: cannot be empty, use dot ('.') for current directory.
REM DELETETMP:     Specify (with value 1) if temporary files in RESULTPATH\TMP-folder should be deleted after finishing script succesfully, or leave empty
SET INIFILE=
SET EXTENT=
SET IDFEXPOPTIONS=
SET RESULTPATH=result
SET DELETETMP=1

REM *******************
REM * Tooldescription *
REM *******************
REM Usage: IDFexp [/o] [/d] [/i] [/r:d] [/s] [/v:v1] ini outpath
REM   for evaluating expressions on IDF-files
REM outpath - path and for writing all results
REM ini - text-file with one or more of the following lines:
REM   <var>=<exp>
REM     to store the result of IDF-expression <exp> in a variable with name <var>
REM     variable names follow the rules of filenames and further should not contain operators, decimal seperators
REM     or other language structures (see below). Variable names are case sensitive.
REM     variables are stored in memory and also written as IDF-file with filename: <var>.IDF
REM     variable names can be prefixed by a relative path to write the IDF-file to a subdirectory. example: KHV\100\KHV_L1=KHV+1
REM     IDF-expressions are defined by one of the following:
REM     - names of previously defined variables
REM     - IDF-filename (absolute path or relative to the path of the ini-file
REM     - floating point constant values
REM     - NoData to specify NoData-value(s)
REM     - <exp1> <op> <exp2>
REM       where <exp1> and <exp2> are (nested) IDF-expressions
REM       where <op> is an arithmetic operator: ^, *, /, +, -
REM     - if-expression: if(<cond>,<then>,<else>)
REM       where <cond> is a condition build up from IDF-expressions and comparison/logical operators
REM         comparison operators: ==, !=, >, >=, <, <=
REM         logical operators: &&, ||
REM         order of evaluation : * or /, + or -, == to <=, && or ||
REM       where <then> and <else> are IDF-expressions
REM       extents are enlarged with NoData to union of input IDF-extents
REM     - min/max-functions: e.g. max(<exp1>,<exp2>)
REM       to take the minimum/maximum of IDF-expressions <exp1> and <exp2>
REM       extents are clipped/enlarged with NoData to extent of IDF-expression <exp1>
REM     - round-function: e.g. round(<exp1>,<decimalcount>)
REM       where <decimalcount> is an integer for the number of decimals
REM     - enlarge-function: e.g. enlarge(<exp1>,<exp2>)
REM       to enlarge IDF-expression <exp1> with NoData to at least the extent of IDF-expression <exp2>
REM     - clip-function: e.g. clip(<exp1>,<exp2>)
REM       to clip IDF-expression <exp1> to the extent of IDF-expression <exp2>
REM     - scale-function: scale(<exp1>,<exp2>[,<method>])
REM       to scale IDF-expression <exp1> to the cellsize of (IDF-expression) <exp2>. Optional method:
REM       for downscale: 0=Block (default)
REM       for upscale: 0=Mean (default), 1=Median, 2=Minimum, 3=Maximum, 4=Most occurring, 5=Boundary
REM     - bbox-function: bbox(<exp1>)
REM       to find bounding box with all non-NoData-values; extent is not changed if only NoData-values are present
REM     parenthesis ('(' and ')') can be used to group subexpressions
REM     environment variables enclosed by %-symbols will be evaluated
REM   FOR <i>=<i1> TO <i2>
REM     to start a FOR-loop with index <i>, that loops from value i1 to i2; lines between FOR and the next ENDFOR-statement are repeated
REM     the value of index <i> can be accessed by prefixing %%. FOR-loops can be nested. 
REM     use simple expressions with indices with syntax '%%(i<op><val>)', where <op> is one of '+','-','*' or '/' and <val> an integer value, e.g. C_L%%i=(BOT_L%%i-TOP_L%%(i+1))*KVV_L%%i
REM     loop values can be padded with zeroes by inserting zeroes after the %% substring: e.g. %%000p will result in values 009,010 and 011 for FOR-loop 'FOR p=9 TO 11'.
REM   ENDFOR
REM     to end a FOR-loop, increase index and continue at line after FOR-statement
REM   #IF [NOT] <cond>: <cmd>
REM     to use a precondition to check if a command should be executed; command <cmd> is executed
REM     if precondition '[NOT] <cond>' evaluates to true; the following preconditions are allowed:
REM     #IF [NOT] EXIST <path>: <cmd>
REM       check if path <path> exists; surround with double quotes when the path may contain spaces
REM   REM <comment>
REM   // <comment>
REM   ' <comment>
REM     to define a commentline which will be ignored
REM
REM /v:v1 - Use NoData as value v1. Without option v, NoData in one of
REM         the input IDF-files results in NoData. Without option v1,
REM         the NoData-value of each IDF-file is used as a value
REM /d    - Run in debug mode: write intermediate expressions and IDF-files
REM /i    - Write intermediate results (all IDF-variables) to IDF-files
REM /m    - Add metadatafiles with (part of) expression(s) and source path
REM 
REM Extent corrections. 
REM If EXTENT has not been specified, extent of IDF-files in expressions is corrected in the following cases:
REM         - if-expression: if(<cond>,<then>,<else>)
REM           extents are enlarged to union of input IDF-extents
REM         - min/max-functions: e.g. max(<exp1>,<exp2>)
REM           extents are clipped/enlarged to extent of <exp1>
REM         - clip(<exp1>,<exp2>): clip to extent of <exp2>
REM         - enlarge(<exp1>,<exp2>): enlarge to at least extent of <exp2>
REM         - other (+,-,/,*,^,==,!=,<,): no extent corrections
REM 
REM example: IDFexp /v:0 "Test\Input" "*L*.IDF" + "Test\Output\file2.IDF"
REM example INI-file:
REM 
REM Horst=HORST.IDF
REM kZUG=50
REM dL1_ZUG_Horst=dL1_ZUG_Horst.IDF
REM dL1_ZUG_Slenk=dL1_ZUG_Slenk.IDF
REM dL1_ZUG=if(Horst==1,dL1_ZUG_Horst,dL1_ZUG_Slenk)
REM 
REM kZZG=35
REM dL1_ZZG_Horst=dL1_ZZG_Horst.IDF
REM dL1_ZZG_Slenk=dL1_ZZG_Slenk.IDF
REM dL1_ZZG=if(Horst==1,dL1_ZZG_Horst,dL1_ZZG_Slenk)
REM 
REM TX1=dL1_ZUG*kZUG+dL1_ZZG*kZZG


REM *********************
REM * Derived variables *
REM *********************
REM Use PUSHD to force temporary drive letter to be used for UNC-paths
PUSHD %~dp0
SET SCRIPTNAME=%~n0
SET LOGFILE="%SCRIPTNAME%.log"
SET THISPATH=%~dp0
SET TEMPDIR=TMP

REM *******************
REM * Script commands *
REM *******************
SETLOCAL EnableDelayedExpansion

TITLE SIF-basis: %SCRIPTNAME%

REM Log settings
SET MSG=Starting %SCRIPTNAME% ...
ECHO %MSG%
ECHO %MSG% > %LOGFILE%

REM Check result path
IF NOT DEFINED RESULTPATH (
  SET MSG=RESULTPATH cannot be empty
  ECHO !MSG!
  ECHO !MSG! >> %LOGFILE%
  GOTO error
)

REM Check INI-file
IF DEFINED INIFILE (
  IF NOT EXIST "%INIFILE%" (
    SET MSG=Defined INI-file not found: %INIFILE%
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
) ELSE (
  SET INIFILE=%SCRIPTNAME%.INI
  IF NOT EXIST "!INIFILE!" (
    ECHO REM Default INI-file, automatically created > "!INIFILE!"
    ECHO FILE1=%%DBASEPATH%%\FILE1.IDF >> "!INIFILE!"
    SET MSG=INI-file not found, default file created: !INIFILE!
    ECHO !MSG!
    ECHO !MSG! >> %LOGFILE%
    GOTO error
  )
)

REM Show used INI-filename
ECHO INIFILE=%INIFILE%
ECHO INIFILE=%INIFILE% >> %LOGFILE%
ECHO: 
ECHO: >> %LOGFILE%

REM Create empty result directory
IF NOT EXIST "%RESULTPATH%" MKDIR "%RESULTPATH%"
IF ERRORLEVEL 1 GOTO error

SET EXTENTOPTION=
IF DEFINED EXTENT SET EXTENTOPTION=/e:"%EXTENT%"

REM Processing INI-file
ECHO "%TOOLSPATH%\IDFexp" %IDFEXPOPTIONS% %EXTENTOPTION% "%INIFILE%" "%RESULTPATH%" >> %LOGFILE%
"%TOOLSPATH%\IDFexp" %IDFEXPOPTIONS% %EXTENTOPTION% "%INIFILE%" "%RESULTPATH%" >> %LOGFILE%
IF ERRORLEVEL 1 GOTO error

IF "%DELETETMP%"=="1" (
  IF NOT "%RESULTPATH%"=="" (
    IF EXIST "%RESULTPATH%\TMP" (
      IF EXIST "%TOOLSPATH%\Del2Bin.exe" (
      SET MSG=Removing temporary files in !RESULTPATH:%ROOTPATH%=!\TMP ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        ECHO "%TOOLSPATH%\Del2Bin.exe" /B /E /S "%RESULTPATH%\TMP" >> %LOGFILE%
        "%TOOLSPATH%\Del2Bin.exe" /B /E /S "%RESULTPATH%\TMP" >> %LOGFILE%
      ) ELSE (
        SET MSG=Removing temporary files (permanently^) in !RESULTPATH:%ROOTPATH%=!\TMP ...
        ECHO !MSG!
        ECHO !MSG! >> %LOGFILE%
        ECHO RMDIR /Q /S "%RESULTPATH%\TMP" >> %LOGFILE%
        RMDIR /Q /S "%RESULTPATH%\TMP" >> %LOGFILE%
      )
      IF ERRORLEVEL 1 GOTO error
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
IF "%NOPAUSE%"=="" PAUSE
