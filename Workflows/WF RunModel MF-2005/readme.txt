Workflow: WF RunModel
---------------------
Description: Scripts for running a model via a PRJ-file; (optionally) starting with a RUN-file

- 01a RUN2PRJ.bat
  Conversion from RUN-file to PRJ-file. If no RUN-file is specified, the (alphabetically last) RUN-file from the current directory is used
- 01b runmodel-PRJ.bat
  Convert PRJ-file to NAM-file with iMOD-batchfunction RUNFILE with specified settings. And run NAM-file with MF-2005.
  If no PRJ-file is specified, the (alfphabetically last) PRJ-file from the current directory is used.
- 02 ppmodels-PRJ.bat
  Usual (steady-state) SIF-postprocressing. For this a PRJ-file is searched in the current directory (using specified PRJ-file filter).
- 03 IMFcreate modelresults
  Create IMF-file with modelresults: residuals, head, surfacelevel file
- 03 IMFcreate modeleffect
  Create IMF-file with modeleffect relative to specified base model: residual differences, head differences
