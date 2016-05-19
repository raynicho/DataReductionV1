%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (C) Copyright 2010 by National Advanced Driving Simulator and
% Simulation Center, the University of Iowa and The University of Iowa.
% All rights reserved.
%
% Version: $ID$
% Authors: Created by Chris Schwarz and others at the NADS


% Description: Reduce data, drive by drive
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [results, data] = reduce( elemDataI, Fs, header, daqData, this, varargin  )
%% Read in all optional variable a rguments
for i = 1:2:length(varargin)
    eval([varargin{i} ' = varargin{i+1};'])
end

%% constants
cMPS2MPH = 2.23694;
cMPH2FPS = 1.46667;
cM2FT = 3.28083;
cG2FPSS = 32.2;
cG2MPSS = 9.81;
cRad2Deg = 180/pi;
cEpsilon = 0.000001;
cHeadingOffsetOwn = 90;

%% apply offset to orient vehicle heading as desired (0 degrees faces east)
% if ~isfield(elemDataI,'VDS_Veh_Heading_Fixed')
%     disp('fixing vehicle heading')
%     try
%         elemDataI.VDS_Veh_Heading_Fixed = elemDataI.VDS_Eyepoint_Orient(:,1) + cHeadingOffsetOwn;
%     catch me
%         elemDataI.VDS_Veh_Heading_Fixed = elemDataI.VDS_Veh_Heading + cHeadingOffsetOwn;
%     end
%     % save elemDataI back into the matfile for next time
%     %disp(['saving elemDataI to ' strcat('MatFiles\',daqData(this).matFile)]);
%     %save(strcat('MatFiles\',daqData(this).matFile),'elemDataI','-append');
% end

%% read the sol file
if exist('solData','file')~=7
    [sol,solId] = ReadSolFile();
    save solData sol solId;
end

%% collect dynamic object data
dyndata = CollectDynamicObjects(elemDataI,false);
dyndata = CombineWithSol(dyndata,sol,solId);
for i = 1:length(dyndata)
    dyndata(i) = mapDynObjToElemData(dyndata(i));
end

%% Begin the writing of the excel sheet
%Find the beginning of valid data
for i = 1:length (elemDataI.Time)
   if (elemDataI.SCC_LogStreams (i, 5))
      startIndication = i;
      break
   end
end

%Find the end of valid data
for i = 1:length (elemDataI.Time)
   if (elemDataI.SCC_LogStreams (i, 5))
       endIndication = i;
   end
end

%Set the vector lengths for data reading and writing
indicationLength = startIndication:endIndication;
writeLength = 2:endIndication - startIndication + 2;
currentColumn = 1;

%Write the names to the first row
Names = {'gender', 'age', 'time', 'intersection', 'subjectXPos', 'subjectYPos', 'subjectXAccel', 'subjectYAccel', 'steerAngle', 'numberCrashes', 'brakeForce', 'audioState', 'startEndIndication', 'crashWarning'};

%Gather the gender from the filename
gender = daqData (this).DaqName;
currentColumn = currentColumn + 1;

%Get the age and then write it to column 2
ageCategory = daqData(this).DaqName (2);
currentColumn = currentColumn + 1;

%Name the file properly
FileName = strcat(gender, ageCategory, daqData(this).DaqName(3), '_', strcat(datestr(clock,'yyyy-mm-dd_HH_MM'), '_', datestr(clock, 'ss')), '.xlsx');

%Get the time
Data (writeLength, currentColumn) = elemDataI.Time (indicationLength);
currentColumn = currentColumn + 1;

%Get the intersections
Data (writeLength, currentColumn) = elemDataI.SCC_LogStreams (indicationLength, 1);
currentColumn = currentColumn + 1;

%Get x and y position of subject
Data (writeLength, currentColumn) = elemDataI.VDS_Chassis_CG_Position (indicationLength, 2); %x is the second column
currentColumn = currentColumn + 1;
Data (writeLength, currentColumn) = elemDataI.VDS_Chassis_CG_Position (indicationLength, 1); %y is the first column
currentColumn = currentColumn + 1;

%Get x and y acceleration of subject
Data (writeLength, currentColumn) = elemDataI.VDS_Chassis_CG_Accel (indicationLength, 2); %x is the second column
currentColumn = currentColumn + 1;
Data (writeLength, currentColumn) = elemDataI.VDS_Chassis_CG_Accel (indicationLength, 1); %y is the first column
currentColumn = currentColumn + 1;

%Get the steering wheel angle
Data (writeLength, currentColumn) = elemDataI.CFS_Steering_Wheel_Angle (indicationLength, 1);
currentColumn = currentColumn + 1;

%Get the number of crashes
Data (writeLength, currentColumn) = elemDataI.SCC_Eval_Collisions (indicationLength, 1);
currentColumn = currentColumn + 1;

%Get the brake force
Data (writeLength, currentColumn) = elemDataI.CFS_Brake_Pedal_Force (indicationLength);
currentColumn = currentColumn + 1;

%Get the audio state
Data (writeLength, currentColumn) = elemDataI.SCC_Audio_Trigger (indicationLength);
currentColumn = currentColumn + 1;

%Get the start and end indications
Data (writeLength, currentColumn) = elemDataI.SCC_LogStreams (indicationLength, 5);
currentColumn = currentColumn + 1;

%Get the crash warning, log stream two
Data (writeLength, currentColumn) = elemDataI.SCC_LogStreams (indicationLength, 2);
currentColumn = currentColumn + 1;

%Get the x and y positions of the lead vehicle
numberOfNames = length (Names) + 1;
for i = 1:length(dyndata)
    %If the first letter is not an O (i.e. the vehicle name is not opposite)
    if ~strcmp(dyndata(i).SCC_DynObj_Name (1:1), 'O')
        %Write the name of the vehicle alongside position identifiers
        Names {1, numberOfNames} = strcat(dyndata (i).SCC_DynObj_Name, 'posX');
        numberOfNames = numberOfNames + 1;
        Names {1, numberOfNames} = strcat(dyndata (i).SCC_DynObj_Name, 'posY');
        numberOfNames = numberOfNames + 1;
        
        %Write the x and y positions now
        Data (writeLength, currentColumn) = dyndata(i).SCC_DynObj_Pos (indicationLength, 2);
        currentColumn = currentColumn + 1;
        
        Data (writeLength, currentColumn) = dyndata(i).SCC_DynObj_Pos (indicationLength, 1);
        currentColumn = currentColumn + 1;
    end
end

%Write the names first
xlswrite (FileName, Names);

%Write data to a excel file
Data2 = num2cell (Data);
Data2 (isnan(Data)) = {'NaN'};
Data2 (writeLength, 2) = cellstr(ageCategory);
Data2 (writeLength, currentColumn) = cellstr('M');
xlswrite (FileName, (Data2), 1, 'A2');
fprintf ('%s reduced. %d%% complete.\n', daqData(this).DaqName, (this/length(daqData))*100);

%%
data = [];
results = [];
