#!/bin/bash

#data plotting options:
# 1. Record data only, ovwerwriting $RAWFILE
# 2. Plot old data only from $RAWFILE and overwriting $PLOTFILE
# 3. Record and plot data (overwriting both)

function record_data() {
  TOTAL_TIME=0
  IFS=$'\t'
  for i in {0..5}; do
    #echo "I=$i"
    NOW=$(date +%s)
    while read -r -a line; do
      #don't record the first on, start from i=1 so we get a non-infinity di/dt
      if [ $i -gt 0 ]; then
          this_time=$NOW
          this_irq=${line[1]%':'}
          this_interrupts[${this_irq}]=${line[2]}
          #Calculate delta_t in case we have resumed from suspend, don't assume it's always the same. 
          delta_t=$((this_time - last_time))
          delta_i=$((this_interrupts[${this_irq}] - last_interrupts[${this_irq}]))
          delta_i_cumulative=$((this_interrupts[${this_irq}] - init_interrupts[${this_irq}]))
          #echo "DEBUG: ${this_irq} : ${this_interrupts[${this_irq}]} : ${last_interrupts[$this_irq]}"
          di_per_dt=$(echo "scale=2;$delta_i/$delta_t" | bc)
          printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t\"%s %s %s\"\n" "$this_irq" "$NOW" "$TOTAL_TIME" "${this_interrupts[${this_irq}]}" "$delta_i_cumulative" "$delta_i" "$di_per_dt" "${line[3]}" "${line[4]}" "${line[5]}" >> "$RAWFILE"
          last_interrupts[${this_irq}]=${line[2]}
      else
        this_irq=${line[1]%':'}
        last_interrupts[${this_irq}]=${line[2]}
        init_interrupts[${this_irq}]=${line[2]}
      fi
    done<<EOT
    $(gawk  '/^\ [1 ]/ {print systime()"\t"$1"\t"$2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13"\t"$14"\t"$15"\t"$16}' /proc/interrupts | tail +2)
EOT
    last_time=$(date +%s)
    TOTAL_TIME=$((TOTAL_TIME + delta_t))
    sleep 2
  done
}

function plot_data() {
  this_irq="";
  PLOTFILE="./plotfile.dat"
  rm $PLOTFILE
  num_irqs=0
  # Gnuplot syntax supports a single data file with contain multiple sets of data, separated by two
  # blank lines.  Each data set is assigned as index value that can be retrieved via the ‘using‘
  # specifier ‘column(-2)‘.
  printf "\"IRQ0\"\n" >> $PLOTFILE
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "irq" "timestamp" "time" "interrupts" "delta_isum" "delta_i" "di/dt" "description" >> $PLOTFILE
  while read -r -a line; do
    if [[ $this_irq != "${line[0]}" && ($num_irqs -gt 0 || $this_irq != "") ]] ; then
      printf "\n\n" >> $PLOTFILE
      printf "\"IRQ%s\"\n" "${line[0]}" >> $PLOTFILE
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "irq" "timestamp" "time" "interrupts" "delta_isum" "delta_i" "di/dt" "description" >> $PLOTFILE
      num_irqs=$((num_irqs +1))
    fi
    echo "${line[*]}" >> $PLOTFILE
    this_irq=${line[0]}
  done<<EOF
$(sort -n "$RAWFILE")
EOF

  echo "NUM_IRQS=$num_irqs"

  gnuplot -p -e "plot for [i=0:$num_irqs] '$PLOTFILE' using 3:5:(column(-2)) index i with linespoints lc variable title columnhead"
}

RAWFILE="./rawfile.dat"
RECORD_DATA=TRUE
if [[ $RECORD_DATA == TRUE ]]; then
  rm $RAWFILE
  record_data
fi

PLOT_DATA=TRUE
if [[ $PLOT_DATA == TRUE ]] && [[ -n $RAWFILE ]]; then
  plot_data
fi
