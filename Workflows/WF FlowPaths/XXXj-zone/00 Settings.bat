@ECHO OFF
REM *******************************************
REM * SIF-basis v2.2.0 (Sweco)                *
REM *                                         *
REM * Settings.bat                            *
REM * DESCRIPTION                             *
REM *   Defines settings for subworkflow      *
REM * AUTHOR(S): Koen van der Hauw (Sweco)    *
REM * VERSION: 2.0.0                          *
REM * MODIFICATIONS                           *
REM *   2020-01-23 Initial version            *
REM *   2024-01-12 Cleanup, move to SIF-basis *
REM *******************************************
CALL :Initialization

REM ***************
REM * Description *
REM ***************
REM Workflow settings for flowpath-runs with IMODPATH: 
REM 1) Perform backward flowpath-run starting around source and with specified traveltime, to retrieve general area of zone
REM 2) Peform forward flowpath-run starting from a buffer around backwards zone
REM 3) Select flowlines and points that end in or pass the specified source
REM 4) Create IDF-file from all starting points that end in or pass the specified source and a traveltime less than or equal to the specified traveltime
REM 5) Create a boundary hull for the zone in the IDF-file. The resulting IDF-file will have a cellsize as specified by variabele FPFW_ISDP_N1
REM Optionally, the results can be converted to ASC-grids and shapefiles and metadata is added automatically based on specified settings.

REM **********************
REM * Workflow variables *
REM **********************
REM --- Define used model, names for flowpath resultfiles and result paths ---
REM MODELREF:        Reference to model for which flowpaths are calculated; name should refer to path under RESULTSPATH and use underscores for subdirectory levels (e.g. ORG_BAS)
REM SOURCEABBR:      Short name or abbreviation for source/extraction, which is used as a substring in flowpath-filenames
REM TYPESTRING:      String to include in flowpath-filenames that defines the type of zone/result (e.g. 25-jaarszone)
REM RESULTPATH_SP:   Path to store ISD-files with starting points for flowpath runs
REM RESULTPATH_RUNS: Path to store results of flowpath runs
REM RESULTPATH_ZONE: Path to store resulting zone-files: an IDF, GEN and IFF for calculated zone
REM RESULTPATH_GIS:  Path to store converted GIS-files (ASC and shapefiles)
REM FLOWLINE_PREFIX: Prefix to add before resultfiles that contain flowlines
SET MODELREF=ORG_BAS
SET SOURCEABBR=ZUTPHEN
SET TYPESTRING=25-jaarszone
SET RESULTPATH_SP=result\startpoints
SET RESULTPATH_RUNS=result\runs
SET RESULTPATH_ZONE=result\zone
SET RESULTPATH_GIS=%ROOTPATH%\..\GIS\DataWorkout\Stroombanen\%TYPESTRING%
SET FLOWLINE_PREFIX=stroombanen_

REM --- Specify model-files that define layermodel and porosity ----
REM NLAY:               Number of modellayers in model that is referenced by MODELREF
REM BNDIDFFILENAMEBASE: Base filename or BND-files, including path and prefix except modellayernumber and IDF-extension (e.g. '%DBASEPATH%\ORG\BND\BND_L')
REM TOPIDFFILENAMEBASE: Base filename file or TOP-files, including path and prefix except modellayernumber (e.g. '%DBASEPATH%\ORG\TOP\TOP_L')
REM BOTIDFFILENAMEBASE: Base filename or BOT-files, including path and prefix except modellayernumber (e.g. '%DBASEPATH%\ORG\BOT\BOT_L')
REM PORAQT:             Porosity for aquitards
REM PORAQF1:            Porosity for normal aquifers
REM PORAQF2:            Alternative porosity for aquifer layers specified by PORAQF2LAYERS (e.g. for limestone), or leave empty to ignore
REM PORAQF2LAYERS:      Comma-seperated list with layernumbers of layers that have alternative porosity PORAQT2, or leave empty to ignore
SET NLAY=9
SET BNDIDFFILENAMEBASE=%DBASEPATH%\ORG\BNDcorr\100\BND_L
SET TOPIDFFILENAMEBASE=%DBASEPATH%\ORG\TOPBOT\TOP_L
SET BOTIDFFILENAMEBASE=%DBASEPATH%\ORG\TOPBOT\BOT_L
SET PORAQT=0.1
SET PORAQF1=0.3
SET PORAQF2=
SET PORAQF2LAYERS=

REM --- Define source/extraction ---
REM SOURCE_IPFPATH:   Path to IPF-file with filters of source
REM SOURCE_IPFFILE:   IPF-filename of IPF-file with source. The IPF is assumed to have the filtertop and filterbottom defined in columns named BKFILT_NAP and OKFILT_NAP
REM SOURCE_SELCOL:    Columnnumber (one-based) of column in source IPF-file with values to select IPF-point(s) from
REM SOURCE_SELVAL:    Value to search for in SOURCE_SELCOL column; value is parsed a regular expression
SET SOURCE_IPFPATH=%DBASEPATH%\ORG\WEL
SET SOURCE_IPFFILE=WEL_VITENS.IPF
SET SOURCE_SELCOL=6
SET SOURCE_SELVAL=Zutphen.*

REM --- Specify settings for backward flowpaths ---
REM FPBW_ISD_RECTSIZE: Size of rectangle around source filters to generate startpoints for backward calculation
REM FPBW_ISD_N1:       Define dimension 1 for the shape for the starting points: an integer or float (english notation). For points: radius of circle around point, for polygons: distance X between points in the polygon, for lines: distance between points along the line
REM FPBW_ISD_N2:       Define dimension 2 for the shape for the starting points: an integer or float (english notation). For points: dinstance between points on the circle, for polygons: distance Y between points in the polygon, for lines: not used, use any number e.g. 0 
REM FPBW_ISD_VIN:      Vertical interval number, number of points between top and bottom level
REM FPBW_ISD_TOP:      TOP-level as an IDF-file, numeric value or columnname in shpFile for TOP-level
REM FPBW_ISD_BOT:      BOT-level as an IDF-file, numeric value or columnname in shpFile for BOT-level
REM FPBW_MAXT:         Maximum tracing time in days
REM FPBW_ISNK:         Specify how to handle weak-sinks: particles will continue (1) or stop (2) at weak sinks. If stopped a fraction can be used (3)
REM FPBW_FRACTION:     Fraction in case of ISNK=3, see iMOD-manual for details
SET FPBW_ISD_RECTSIZE=75
SET FPBW_ISD_N1=5.0
SET FPBW_ISD_N2=5.0
SET FPBW_ISD_VIN=10
SET FPBW_ISD_TOP=WellTopLevel
SET FPBW_ISD_BOT=WellBottomLevel
SET FPBW_MAXT=9125
SET FPBW_ISNK=1
SET FPBW_FRACTION=0.5

REM --- Specify settings for forward flowpaths ---
REM FPFW_ISD_RECTSIZE: Size of rectangle around source filters to generate startpoints for forward calculation; note: a a general rule, use at least 1.5 times the model cellsize to catch lines/points that pass just outside the cell with the source filters
REM FPFW_ISDP_N1:      Dimension 1 for the shape for the starting points for IPF-result: an integer or float (english notation). For points: radius of circle around point, for polygons: distance X between points in the polygon, for lines: distance between points along the line
REM FPFW_ISDP_N2:      Dimension 2 for the shape for the starting points for IPF-result: an integer or float (english notation). For points: dinstance between points on the circle, for polygons: distance Y between points in the polygon, for lines: not used, use any number e.g. 0 
REM FPFW_ISDP_VIN:     Vertical interval number for IPF-resusult, number of points between top and bottom level
REM FPFW_ISDL_N1:      Dimension 1 for the shape for the starting points for IFF-result (flowlines): an integer or float (english notation). For points: radius of circle around point, for polygons: distance X between points in the polygon, for lines: distance between points along the line
REM FPFW_ISDL_N2:      Dimension 2 for the shape for the starting points for IFF-result (flowlines):  an integer or float (english notation). For points: dinstance between points on the circle, for polygons: distance Y between points in the polygon, for lines: not used, use any number e.g. 0 
REM FPFW_ISDL_VIN:     Vertical interval number for IFF-result (flowlines), number of points between top and bottom level
REM FPFW_ISD_TOP:      TOP-level for startpoints as an IDF-file, numeric value or columnname in shpFile for TOP-level
REM FPFW_ISD_BOT:      BOT-level for startpoints as an IDF-file, numeric value or columnname in shpFile for BOT-level
REM FPFW_ISD_TOPSTR:   TOP-level string for startpoints for use in metadata
REM FPFW_ISD_TOPSTR:   BOT-level string for startpoints for use in metadata
REM FPFW_MAXT:         Maximum tracing time in days
REM FPFW_ISNK:         Specify how to handle weak-sinks: particles will continue (1) or stop (2) at weak sinks. If stopped a fraction can be used (3)
REM FPFW_FRACTION:     Fraction in case of ISNK=3, see iMOD-manual for details
SET FPFW_ISD_RECTSIZE=250
SET FPFW_ISDP_N1=25.0
SET FPFW_ISDP_N2=25.0
SET FPFW_ISDP_VIN=10
SET FPFW_ISDL_N1=50.0
SET FPFW_ISDL_N2=50.0
SET FPFW_ISDL_VIN=10
SET FPFW_ISD_TOP=%DBASEPATH%\ORG\TOPBOT\TOP_L1.IDF
SET FPFW_ISD_BOT=%DBASEPATH%\ORG\TOPBOT\BOT_L4.IDF
SET FPFW_ISD_TOPSTR=TOP_L1
SET FPFW_ISD_BOTSTR=BOT_L4
SET FPFW_MAXT=365.0E25
SET FPFW_ISNK=3
SET FPFW_FRACTION=0.5

REM --- Specify settings for selection of forward flowpaths ---
REM FPFW_SEL_MAXY:   Maximum time in years to select from calculated flowpaths for resulting zone
REM FPFW_SEL_TOP:    Path and filename of IDF-file with TOP-level (m+NAP) of volume that source filters are in, used for IPF/IFF-selection after flowpath calculation; 
REM FPFW_SEL_BOT:    Path and filename of IDF-file with BOT-files-level (m+NAP) of volume that source filters are in, used for IPF/IFF-selection after flowpath calculation; 
SET FPFW_SEL_MAXY=25
SET FPFW_SEL_TOP=%DBASEPATH%\ORG\TOPBOT\TOP_L3.IDF
SET FPFW_SEL_BOT=%DBASEPATH%\ORG\TOPBOT\BOT_L3.IDF

REM --- Specify template file for creation of GIS metadata ---
SET XMLTEMPLATEFILE=input\MetadataTemplate FlowPaths.xml

REM *******************
REM * Script commands *
REM *******************
CMD /C "EXIT /B 0"
GOTO exit

REM FUNCTION: Intialize script and search/call 'SETTINGS\SIF.Settings.Project.bat' and '00 settings.bat'. To use: "CALL :Initialization", without arguments
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
  IF EXIST "%~dp0..\00 settings.bat" (
    CALL "%~dp0..\00 settings.bat"
  ) ELSE (
    IF EXIST "%~dp0..\..\00 settings.bat" (
      CALL "%~dp0..\..\00 settings.bat"
    ) ELSE (
      IF EXIST "%~dp0..\..\..\00 settings.bat" (
        CALL "%~dp0..\..\..\00 settings.bat"
      ) ELSE (
        IF EXIST "%~dp0..\..\..\..\00 settings.bat" (
          CALL "%~dp0..\..\..\..\00 settings.bat"
        ) ELSE (
          IF EXIST "%~dp0..\..\..\..\..\00 settings.bat" (
            CALL "%~dp0..\..\..\..\..\00 settings.bat"
          ) ELSE (
            IF EXIST "%~dp0..\..\..\..\..\..\00 settings.bat" (
              CALL "%~dp0..\..\..\..\..\..\00 settings.bat"
            ) ELSE (
              REM Higher level settings file not found, ignore
            )
          )
        )
      )
    )
  )
  GOTO:EOF

:exit
