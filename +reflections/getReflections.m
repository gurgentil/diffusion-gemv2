function[currPairReflections] = getReflections(commPair,...
    commPairID,jointBuildings,jointVehicles,objectCellsBuildings,...
    antennaHeight,objectCellsVehicles,numRowsPerVehicle,vehicleMidpoints,...
    vehiclesHeight)
% GETREFLECTIONS Prepares the input polygons for finding potential
% reflections off buildings and vehicles.
%
% Input:
%   see reflect.m
%
% Output:
%   currPairReflections:    potential reflections for current comm. pair
%
% Copyright (c) 2014-2015, Mate Boban

%% Get potential reflections off buildings 
buildingRays = [];
if ~isempty(jointBuildings)    
    currBuildings = vertcat(objectCellsBuildings{jointBuildings});  
    % Check which contiguous points in the currBuildings array have the
    % same ID (i.e., are on the same building)
    sameBuilding = currBuildings(1:end-1,1)==currBuildings(2:end,1);
    % Build line segments from points
    segments = [currBuildings(1:end-1,:) currBuildings(2:end,:)];
    % Segments should only exist between points on the same building;
    % remove the remaining ones
    segments = segments(sameBuilding, :);
    % Get potentially reflecting rays
    if ~isempty(segments)
        buildingRays = reflections.getReflRays(commPair,segments,...
            commPairID,0,vehicleMidpoints,objectCellsVehicles);
    end
end

%% Get potential reflections off vehicles
vehicleRays = [];
if ~isempty(jointVehicles)
    % For the purpose of reflecting or obstructing reflection/diffraction,
    % to simplify calculations, a reflecting vehicle needs to be taller
    % than the shorter vehicle in the comm. pair PLUS the antenna height of
    % top of that vehicle.
    jointTallerVehicles = jointVehicles(vehiclesHeight(jointVehicles)>...
        min(vehiclesHeight(commPair))+antennaHeight);
    % Get possibly reflecting vehicles
    currVehicles = vertcat(objectCellsVehicles{jointTallerVehicles});
    
    % Get the segments forming vehicle outlines
    vehicleSegments = [currVehicles(1:end-1,:) currVehicles(2:end,:)];
    % Remove non-existent segments between different vehicles
    vehicleSegments(numRowsPerVehicle:numRowsPerVehicle:end,:) = [];
    if ~isempty(vehicleSegments)
        vehicleRays = reflections.getReflRays(commPair,vehicleSegments,...
            commPairID,1,vehicleMidpoints,objectCellsVehicles);
    end
end

%% Get the array containing potential reflections
% Array structure: [x1,y1,x2,y2,commPairID,building refl.(0)/vehicle(1)]
currPairReflections=[];
if size(buildingRays,1)+size(vehicleRays,1)>0
    currPairReflections = zeros(size(buildingRays,1)+size(vehicleRays,1),6);
    if ~isempty(buildingRays)
        currPairReflections(1:size(buildingRays,1),1:5) = buildingRays;
    end
    if ~isempty(vehicleRays)
        currPairReflections(size(buildingRays,1)+1:end,1:5) = vehicleRays;
        % Mark reflection off buildings as 0
        % Mark reflection off vehicles as 1
        currPairReflections(size(buildingRays,1)+1:end,6)=1;
    end
end
end