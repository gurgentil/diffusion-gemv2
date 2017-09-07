function[finalReflRays,feasibleCommPairsNLOSb,jointBuildingsNLOSb,...
    jointDistancesNLOSb,reflEfields,reflDist] = ...
    reflect(feasibleCommPairs,feasibleCommPairType,antennaHeight,jointBuildings,...
    jointDistances,jointVehicles,objectCellsBuildings,objectCellsVehicles,...
    objectCellsFoliage,numRowsPerVehicle,vehicleMidpoints,vehiclesHeight,...
    RTreeB,RTreeV,RTreeF,buildingReflRelPerm,vehReflRelPerm,polarization,...
    txPower,Gt,verbose)
% REFLECT Calculates reflected rays for NLOSb comm. pairs. 
%
% Input:
%   see simOneTimestep.m
%
% Output:
%   finalReflRays:          array containing reflections; structure:
%                           [x1,y1,x2,y2,commPairID,building refl.(0)/vehicle(1)]
%                           one reflected ray occupies two rows (incident
%                           and reflected component)
%   feasibleCommPairsNLOSb: feasible NLOSb comm. pairs
%   jointBuildingsNLOSb:    buildings inside the ellipse for NLOSb pairs
%   jointDistancesNLOSb:    distance to buildings inside the ellipse for
%                           NLOSb pairs 
%   reflEfields:            E-field for reflections
%   reflDist:               distance traversed by each reflected ray
%
% Copyright (c) 2014-2015, Mate Boban

% Get feasible NLOSb comm. pairs
feasibleCommPairsNLOSb = feasibleCommPairs(feasibleCommPairType==2,:);
% Get buildings and vehicles inside the ellipse for NLOSb pairs
jointBuildingsNLOSb = jointBuildings(feasibleCommPairType==2,:);
jointDistancesNLOSb = jointDistances(feasibleCommPairType==2);
jointVehiclesNLOSb = jointVehicles(feasibleCommPairType==2,:);
% Preallocate reflection array with initial size 100 X comm. pairs
reflRays = zeros(size(feasibleCommPairsNLOSb,1)*100,6);
% Counter for the current position in reflRays 
reflRayCounter = 1;
% When reflRays array is filled up, increase it by reflRayIncrement rows
reflRayIncrement = 20000;

% Get single-interaction reflection points P off buildings and vehicles;
% check whether rays formed by Tx-P and P-Rx are blocked by either
% buildings or vehicles 
for kk=1:size(feasibleCommPairsNLOSb,1)
    % Get data for current comm. pair
    currCommPair = feasibleCommPairsNLOSb(kk,:);
    currJointBuildings = jointBuildingsNLOSb{kk};
    currJointVehicles = jointVehiclesNLOSb{kk};    
    % Get the reflecting rays for the current commPair    
    currPairReflections = reflections.getReflections(currCommPair,...
        kk,currJointBuildings,currJointVehicles,objectCellsBuildings,...
        antennaHeight,objectCellsVehicles,numRowsPerVehicle,...
        vehicleMidpoints,vehiclesHeight);
    % If the end of preallocated array is reached, increase it.
    if size(currPairReflections,1)+reflRayCounter>size(reflRays,1)
        disp('Increasing the preallocated array for reflections...');
        reflRays(end+1:end+reflRayIncrement,:)=0;
    end
    % If there are any reflections, add them to reflRays
    if size(currPairReflections,1)>0
        reflRays(reflRayCounter:reflRayCounter+...
            size(currPairReflections,1)-1,:) = currPairReflections;
        reflRayCounter = reflRayCounter+size(currPairReflections,1);
    end
end
% Delete any extra rows at the end of reflRays
reflRays = reflRays(reflRays(:,1)~=0,:);

% Now we have all potentially reflecting rays; pass them to
% getObstructingObjects to check which ones are not obstructed.

%% First test for ray blocking by buildings
if ~isempty(RTreeB)
    obsReflRaysB = polygonManipulation.getObstructingObjects(reflRays,...
        objectCellsBuildings,vehicleMidpoints,RTreeB,-1,1,verbose);
    % Check both ray parts (Tx-P and P-Rx). Get only those that have both
    % ray parts unobstructed.
    notObstructedByBuild = obsReflRaysB(1:2:end-1)+obsReflRaysB(2:2:end);
    getNonObsRays = ones(size(obsReflRaysB,1),1)*Inf;
    % Assign the sum to both parts of the ray (Tx-P & P-Rx)
    getNonObsRays(1:2:end-1) = notObstructedByBuild;
    getNonObsRays(2:2:end) = notObstructedByBuild;
    % Get the reflected rays (Tx-P AND P-Rx) not obstructed by buildings
    reflRaysB = reflRays(getNonObsRays==0,:);
else
    reflRaysB = reflRays;
end

%% For rays not blocked by buildings, test for blocking by foliage
if ~isempty(RTreeF)
    obsReflRaysF = polygonManipulation.getObstructingObjects(reflRaysB,...
        objectCellsFoliage,vehicleMidpoints,RTreeF,-1,1,verbose);
    % Check both ray parts (Tx-P and P-Rx). Get only those that have both
    % ray parts unobstructed.
    notObstructedByFoliage = obsReflRaysF(1:2:end-1)+obsReflRaysF(2:2:end);
    getNonObsRaysF = ones(size(obsReflRaysF,1),1)*Inf;
    % Assign the sum to both parts of the ray (Tx-P & P-Rx)
    getNonObsRaysF(1:2:end-1) = notObstructedByFoliage;
    getNonObsRaysF(2:2:end) = notObstructedByFoliage;
    % Get the reflected rays (Tx-P AND P-Rx) not obstructed by foliage
    reflRaysF = reflRaysB(getNonObsRaysF==0,:);
else
    reflRaysF = reflRaysB;
end
    
%% For rays not blocked by buildings or foliage, test for blocking by vehicles
obsReflRaysV = polygonManipulation.getObstructingObjects(reflRaysF,...
    objectCellsVehicles,vehicleMidpoints,RTreeV,-1,1,verbose,...
    vehiclesHeight,antennaHeight,feasibleCommPairs);

%% Get the reflected rays (Tx-P AND P-Rx) not obstructed by vehicles
notObstructedByVeh = obsReflRaysV(1:2:end-1)+obsReflRaysV(2:2:end);
getNonObsRaysV = ones(size(obsReflRaysV,1),1)*Inf;
% Assign the sum to both parts of the ray (Tx-P & P-Rx)
getNonObsRaysV(1:2:end-1) = notObstructedByVeh;
getNonObsRaysV(2:2:end) = notObstructedByVeh;

%% Finally, get the reflected rays that are free of all obstructions
finalReflRays = reflRaysF(getNonObsRaysV==0,:);

%% Calculate E-field for reflected rays
if ~isempty(finalReflRays)
    [reflEfields,reflDist] = reflections.calcReflEfield(finalReflRays,...
        buildingReflRelPerm,vehReflRelPerm,polarization,vehiclesHeight,...
        feasibleCommPairs,txPower,Gt);
else
    reflEfields = zeros(0);
    reflDist = zeros(0);
end