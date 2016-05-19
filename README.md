# DataReductionV1
Data Reduction Tools built in MATLAB using the ndaqTools interface when collecting data with the MiniSim Driving Simulator. The scripts are built around the template given by Chris Schwarz and the NADS team at the University of Iowa. This ensures that the reduction script complies with ndaqTools. The funciton reduce.m produces an Excel file when used as the reduction script in ndaqTools. This reduction function is meant to be run after the DAQ files are collected.  The Excel sheet will include:

- current time in simulation
- current intersection in simulation
- subject's x and y position and acceleration
- x and y positions of lead and follow vehicles
- steering wheel angle
- brake force of subject
- audio state (used for honking signal)
- start and end indication of simulation
- x and y positions of surrounding vehicle's that are NOT opposing vehicles
- number of crashes involving subject
- whether frontal crash warning was present

The data reduction scripts are also repsonsible for creating an excel sheet containing the names of all excel sheets created. This aids in the data cleaning process. 
