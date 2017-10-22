function[vehiclePolygons] = ...
    generateVehiclePolygons(vehicleRows,vehDimensionParams,verbose)
% GENERATEVEHICLEPOLYGONS
%
% Input:
%   vehicleRows:                    
%   - vehicleRows:              array with six columns containing the
%                               following vehicle information: 
%                                   -  Col 1: vehicle ID
%                                   -  Col 2 and 3: X and Y (or Lat and
%                                   Lon) coordinate of the vehicle
%                                   centerpoint (assumption: if Lat and
%                                   Lon, area is not large enough to cause
%                                   non-linearities)
%                                   -  Col 4: vehicle type: car (0) or
%                                   truck (1)
%                                   -  Col 5: bearing (angle in radians
%                                   starting from abscissa and going
%                                   counterclockwise)
%                                   - GUSTAVO: Col 6: speed
%   vehDimensionParams:         parameters for generating vehicle
%                               dimensions (height, width, length)
%
% Output:   
%   vehiclePolygons:            vehicle polygons
%
% Copyright (c) 2014-2015, Mate Boban

tic

% Points on the vehicle (M-midpoint)
%       P4--------P2\
%       |            \
%       |     M   -h-P1
%       |            /
%       P5--------P3/

% Define h from fig above: the height of the triangle P1P2P3. Purposely
% hard-coded as it is unlikely to change often.
hP1 = .5;
% Get bearing
bearing = vehicleRows(:,5);
% Get unique vehicle IDs and their indices
[uniqueVehicles, uniqueVehiclesIndex] = unique(vehicleRows(:,1));

% If there are multiple instances of the same vehicle (over different
% timesteps), assign it same dimensions. Using the idea from
% http://www.mathworks.com/matlabcentral/newsreader/view_thread/300391 to
% do this efficiently.
if length(uniqueVehicles)<length(vehicleRows(:,1))    
    % Some vehicle IDs repeat across timesteps. Assign same dimensions to
    % same vehicle over differenttimesteps.
    % Randomly generate widths and lengths for cars and trucks
    widths = zeros(size(uniqueVehicles));
    widths(vehicleRows(uniqueVehiclesIndex,4)==0) = ...
        randn(1,sum(vehicleRows(uniqueVehiclesIndex,4)==0))*...
        vehDimensionParams(2,2)+vehDimensionParams(2,1);
    widths(vehicleRows(uniqueVehiclesIndex,4)==1) = ...
        randn(1,sum(vehicleRows(uniqueVehiclesIndex,4)==1))*...
        vehDimensionParams(2,4)+vehDimensionParams(2,3);
    
    lengths = zeros(size(uniqueVehicles));
    lengths(vehicleRows(uniqueVehiclesIndex,4)==0) = ...
        randn(1,sum(vehicleRows(uniqueVehiclesIndex,4)==0))*...
        vehDimensionParams(3,2)+vehDimensionParams(3,1);
    lengths(vehicleRows(uniqueVehiclesIndex,4)==1) = ...
        randn(1,sum(vehicleRows(uniqueVehiclesIndex,4)==1))*...
        vehDimensionParams(3,4)+vehDimensionParams(3,3);
    
    % Define points as per figure above
    [P1,P2,P3,P4,P5]=deal(ones(size(vehicleRows,1),2)*Inf);
    
    % Sort and get the indices of sorted IDs
    [sortID, indexID] = sort(vehicleRows(:,1));
    % For each unique (sorted) IDs, get the number of occurences using histc
    uniqueIDandCount  = [uniqueVehicles histc(vehicleRows(:,1),uniqueVehicles)];
    % Set up a cumulative sum of indices for looking up indexIDs.
    cumSumUniqueCount = [0;cumsum(uniqueIDandCount(:,2))];
    
    for kk=1:length(uniqueVehicles)
        % Get locations in original vehicleRows for each vehicle ID
        currUniqueVehicleIDs = indexID(cumSumUniqueCount(kk)+1:cumSumUniqueCount(kk+1));        
        % Set P1-P5 (without rotation using bearing, which is done later)
        P1(currUniqueVehicleIDs,1) = vehicleRows(currUniqueVehicleIDs,3)+lengths(kk)/2;
        P1(currUniqueVehicleIDs,2) = vehicleRows(currUniqueVehicleIDs,2);
        P2(currUniqueVehicleIDs,1) = vehicleRows(currUniqueVehicleIDs,3)+lengths(kk)/2-hP1;
        P2(currUniqueVehicleIDs,2) = vehicleRows(currUniqueVehicleIDs,2)+widths(kk)/2;
        P3(currUniqueVehicleIDs,1) = P2(currUniqueVehicleIDs,1);
        P3(currUniqueVehicleIDs,2) = vehicleRows(currUniqueVehicleIDs,2)-widths(kk)/2;
        P4(currUniqueVehicleIDs,1) = vehicleRows(currUniqueVehicleIDs,3)-lengths(kk)/2;
        P4(currUniqueVehicleIDs,2) = vehicleRows(currUniqueVehicleIDs,2)+widths(kk)/2;
        P5(currUniqueVehicleIDs,1) = P4(currUniqueVehicleIDs,1);
        P5(currUniqueVehicleIDs,2) = vehicleRows(currUniqueVehicleIDs,2)-widths(kk)/2;
    end
else
    % There is no repetition of vehicle IDs over different timesteps (or
    % there is a single timestep).
    
    % Get vehicle type
    type = vehicleRows(:,4);
    % Randomly generate widths and lengths for cars and trucks
    widths = zeros(size(type));
    widths(~type) = ...
        randn(1,sum(type==0))*vehDimensionParams(2,2)+vehDimensionParams(2,1);
    widths(logical(type)) = ...
        randn(1,sum(type))*vehDimensionParams(2,4)+vehDimensionParams(2,3);    
    lengths = zeros(size(type));
    lengths(~type) = ...
        randn(1,sum(type==0))*vehDimensionParams(3,2)+vehDimensionParams(3,1);
    lengths(logical(type)) = ...
        randn(1,sum(type))*vehDimensionParams(3,4)+vehDimensionParams(3,3);

    % Set P1-P5 (without rotation using bearing, which is done later)
    P1(:,1) = vehicleRows(:,3)+lengths./2;
    P1(:,2) = vehicleRows(:,2);
    P2(:,1) = vehicleRows(:,3)+lengths./2-hP1;
    P2(:,2) = vehicleRows(:,2)+widths./2;
    P3(:,1) = P2(:,1);
    P3(:,2) = vehicleRows(:,2)-widths./2;
    P4(:,1) = vehicleRows(:,3)-lengths./2;
    P4(:,2) = vehicleRows(:,2)+widths./2;
    P5(:,1) = P4(:,1);
    P5(:,2) = vehicleRows(:,2)-widths./2;
end

% Get rotation matrix
rotMatrices = [cos(bearing) -sin(bearing) sin(bearing) cos(bearing)];

% Subtract vehicle midpoint from points (needed for proper rotation)
P1Shift = P1-vehicleRows(:,[3,2]);
P2Shift = P2-vehicleRows(:,[3,2]);
P3Shift = P4-vehicleRows(:,[3,2]);
P4Shift = P5-vehicleRows(:,[3,2]);
P5Shift = P3-vehicleRows(:,[3,2]);
P6Shift = P1-vehicleRows(:,[3,2]);

% Apply rotation matrix to the points. 
P1s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P1Shift(:,1)+rotMatrices(:,2).*P1Shift(:,2)) (rotMatrices(:,3).*P1Shift(:,1)+rotMatrices(:,4).*P1Shift(:,2))];
P2s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P2Shift(:,1)+rotMatrices(:,2).*P2Shift(:,2)) (rotMatrices(:,3).*P2Shift(:,1)+rotMatrices(:,4).*P2Shift(:,2))];
P3s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P3Shift(:,1)+rotMatrices(:,2).*P3Shift(:,2)) (rotMatrices(:,3).*P3Shift(:,1)+rotMatrices(:,4).*P3Shift(:,2))];
P4s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P4Shift(:,1)+rotMatrices(:,2).*P4Shift(:,2)) (rotMatrices(:,3).*P4Shift(:,1)+rotMatrices(:,4).*P4Shift(:,2))];
P5s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P5Shift(:,1)+rotMatrices(:,2).*P5Shift(:,2)) (rotMatrices(:,3).*P5Shift(:,1)+rotMatrices(:,4).*P5Shift(:,2))];
P6s = vehicleRows(:,[3,2])+[(rotMatrices(:,1).*P6Shift(:,1)+rotMatrices(:,2).*P6Shift(:,2)) (rotMatrices(:,3).*P6Shift(:,1)+rotMatrices(:,4).*P6Shift(:,2))];

% Insert points into vehiclePolygons array
vehiclePolygons = zeros(size(vehicleRows,1)*6,3);
vehiclePolygons(1:6:end,:) = [vehicleRows(:,1) fliplr(P1s)];
vehiclePolygons(2:6:end,:) = [vehicleRows(:,1) fliplr(P2s)];
vehiclePolygons(3:6:end,:) = [vehicleRows(:,1) fliplr(P3s)];
vehiclePolygons(4:6:end,:) = [vehicleRows(:,1) fliplr(P4s)];
vehiclePolygons(5:6:end,:) = [vehicleRows(:,1) fliplr(P5s)];
vehiclePolygons(6:6:end,:) = [vehicleRows(:,1) fliplr(P6s)];

if verbose
    fprintf('Generating vehicle polygons takes %f seconds.\n', toc);
end