# Gnuplot script for plotting TEQC slips
# Usage:
# ..\teqcgnuplot\bin\gnuplot.exe -c ..\teqcgnuplot\bin\gnuplot_teqcslip.gp "%frnx2%.slip_%%S" "%%S"
# Output: to a %frnx2%.slip.png file 
# 
# Author: Ira.Sellars at noaa.gov
# Created Date: 2025-12-01 10:20:24

# Check if an argument was provided
if (ARGC < 2) {
    print "Usage: gnuplot -c gnuplot_teqcslip.gp "%frnx2%.slip_%%S" [\"%%S\"]"
    print "Output: %frnx2%.slip_%%S.png"
    exit
}

# Get the input filename from the first argument (ARG1)
INPUT_FILE = ARG1

# Construct the final PNG filename
OUTPUT_FILE = INPUT_FILE . ".png"
set output OUTPUT_FILE

# --- Output Configuration ---
set terminal png enhanced font "arial,10" fontscale 1.0 size 800, 600

# Plot title on the top left corner. Use \n to add a new line.
set label 1 at screen 0.02, 0.95 font ":Bold,10"
set label 1 INPUT_FILE

# Add timestamp at the bottom left
set timestamp "Created: %d-%m-%y %H:%M:%S" offset 1,1

# --- Plot Configuration ---
set angles degrees          # Use degrees instead of radians
set size square             # Ensures the plot is circular
set polar                   # Use polar coordinates
set grid polar              # Add a polar grid, default at every 30 degrees
set theta top clockwise     # North at the top, clockwise now
unset border
unset xtics
unset ytics

set ttics add ("N" 0, "E" 90, "S" 180, "W" -90) font ":Bold"
set rrange [90:0]           # Set 0 at border, 90 at center
#set rtics format "%.0f°"
#set rlabel "Altitude" offset -2 font ":Bold"
# Set rtics manually for GNSS sky plot. 
set rtics ("90°" 90, "45°" 45,"20°" 20, "5°" 5, "0°" 0)
set border polar           

# Now plot each constellation as a series
get_color(c) = (c eq "G" ? "green" : \
                c eq "R" ? "red" : \
                c eq "E" ? "blue" : \
                c eq "C" ? "cyan" : \
                c eq "J" ? "orange" : \
                c eq "I" ? "magenta" : \
                c eq "S" ? "brown" : "black") # Default to black if unknown
get_satsys(c) = (c eq "G" ? "   GPS" : \
                c eq "R" ? "   GLONASS" : \
                c eq "E" ? "   Galileo" : \
                c eq "C" ? "   BeiDou" : \
                c eq "J" ? "   QZSS" : \
                c eq "I" ? "   NavIC" : \
                c eq "S" ? "   SBAS" : "   Unknown") # Default to black if unknown

SAT_LIST = "G R E C J I S"
# (PRN, Elev, Azimuth, Constellation)
plot for [i=1:words(SAT_LIST)] INPUT_FILE using \
    (strcol(4) eq word(SAT_LIST, i) ? $3 : 1/0):(strcol(4) eq word(SAT_LIST, i) ? $2 : 1/0) \
     with points \
     pt 7 \
     lc rgb get_color(word(SAT_LIST, i)) \
     title get_satsys(word(SAT_LIST, i))
        

