function[jointVehicles,jointVehicleDistances] = excludeCommPairJointVeh...
    (jointVehicles,jointVehicleDistances,commPair)
% EXCLUDECOMMPAIRJOINTVEH Removes the vehicles participating in the
% communication pair from the list of shared vehicles (jointVehicles).
% Assumption: joint vehicles are sorted in ascending order! 
%
% Copyright (c) 2014-2015, Mate Boban

% Sort the two vehicles in commPair
if commPair(1)>commPair(2)
    temp = commPair(1);
    commPair(1) = commPair(2);
    commPair(2) = temp;
end

% Keep all vehicles except those in commPair
locations =~ismembc2(jointVehicles,commPair);
jointVehicles = jointVehicles(locations);
jointVehicleDistances = jointVehicleDistances(locations);