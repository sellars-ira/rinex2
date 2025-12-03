# Usage:

teqcgnuplot.cmd <ssss> <yyyy> <ddd>

## where:

<ssss> : the 4-char ID of an NCN station, must be lower-case, e.g. gode
<yyyy> : year, must be 4 digits, e.g. 2025
<ddd> : day of year, must be 3 digits, e.g. 328 or 001

# Description:

In Windows Command Prompt, teqcgnuplot.cmd will: - create a folder <ssss> if not exists; - attempt to download the daily RINEX 2 of the given <ssss> station; - attempt to download the broadcast ephemeris files of the given <yyyy>:<ddd> - run TEQC qc with 5 deg elevation cut-off to create a TEQC summary file,
a .meta file, and multiple slip plots in PNG format.
