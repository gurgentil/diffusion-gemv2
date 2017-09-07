function[vehicleHeights] = getVehicleHeight(vehicleRows,numRowsPerVehicle,...
    vehDimensionParams,lengthThreshold,verbose)
% GETVEHICLEHEIGHT Calculates vehicle heights. Assumes all vehicles whose
% length is above lengthThreshold are trucks, and those below are cars.
%
% Input:
%   vehicleRows                 vehicle outlines in a three-column format:
%                               [ID,X,Y] 
%   numRowsPerVehicle:          number of rows per vehicle
%   vehDimensionParams:         parameters for generating vehicle
%                               dimensions (height, width, length)
%   lengthThreshold:            length threshold for distinguishing cars
%                               and trucks
%   verbose:                    verbose output
%
% Output:   
%   vehicleHeights:             vehicle heights
%
% Copyright (c) 2014-2015, Mate Boban

tic
% Get one (first) row from each vehicle outline
vehicleRowsOne = vehicleRows(1:numRowsPerVehicle:end,:);
% Get unique vehicle IDs and their indices
[uniqueVehicles,uniqueVehiclesIndex] = unique(vehicleRowsOne(:,1));

% Initiate arrays
vehicleHeights = ones(size(vehicleRows,1)/numRowsPerVehicle,1);
maxLengths = ones(size(vehicleRows,1)/numRowsPerVehicle,1);

% For each vehicle outline, calculate maximum length: distance between
% first point in vehicle outline to the farthest point from first point.
% Approximates the size of the vehicle.
for jj = 1:size(vehicleHeights, 1)
    % Set maximum length from first point in vehicle to all others
    maxLength = 0;
    for kk=2:numRowsPerVehicle
        % Current distance from 1st point to kk-th point.
        currLength = sqrt((vehicleRows((jj-1)*numRowsPerVehicle+kk,2) -...
                           vehicleRows((jj-1)*numRowsPerVehicle+1,2))^2 +...
                          (vehicleRows((jj-1)*numRowsPerVehicle+kk,3) - ...
                           vehicleRows((jj-1)*numRowsPerVehicle+1,3))^2);
        if currLength>maxLength
            maxLength=currLength;
        end
    end
    maxLengths(jj) = maxLength;
end

if length(uniqueVehicles)<length(vehicleRowsOne(:,1))
    % Sort and get the indices of sorted IDs
    [sortID, indexID] = sort(vehicleRowsOne(:,1));
    % For each unique (sorted) IDs, get number of occurences using histc
    uniqueIDandCount = ...
        [uniqueVehicles histc(vehicleRowsOne(:,1),uniqueVehicles)];
    % Set up a cumulative sum of indices for looking up indexIDs.
    cumSumUniqueCount = [0;cumsum(uniqueIDandCount(:,2))];
    vehHeights = ones(size(uniqueVehicles))*Inf;
    % Randomly generate widths and lengths for cars and trucks
    carsNTrucks = maxLengths(uniqueVehiclesIndex)>lengthThreshold;
    vehHeights(carsNTrucks==0)=vehDimensionParams(1,1) + ...
        randn(sum(carsNTrucks==0),1).*vehDimensionParams(1,2);
    vehHeights(carsNTrucks==1)=vehDimensionParams(1,3) + ...
        randn(sum(carsNTrucks==1),1).*vehDimensionParams(1,4);
    % Get locations in original vehicleRows for each vehicle ID
    for kk=1:length(uniqueVehicles)
        currUniqueVehicleIDs = indexID(cumSumUniqueCount(kk) + ...
            1:cumSumUniqueCount(kk+1));
        vehicleHeights(currUniqueVehicleIDs,1) = vehHeights(kk);
    end
else
    % Distinguish large vehicles (trucks)
    trucks = maxLengths>lengthThreshold;
    % Set height for cars and trucks
    vehicleHeights(trucks) = vehDimensionParams(1,3) + ...
        randn(sum(trucks),1).*vehDimensionParams(1,4);
    vehicleHeights(~trucks) = vehDimensionParams(1,1) + ...
        randn(sum(~trucks),1).*vehDimensionParams(1,2);
end
if verbose
    fprintf('Generating vehicle heights takes %f seconds\n', toc);
end