# interrupts_measure
Measure and record IRQ interrupts over time and format for plotting the data. 

This parses the file /proc/interrupts every few seconds and records the IRQs, their interrupts, 
and the change in interrupts per unit time in an array indexed by IRQ. This allows for diagnosing 
continuous interrupts from possibly buggy kernel drivers

Written in bash so no additional languages or libraries need to be loaded
