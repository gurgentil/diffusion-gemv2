function[jointObjects,jointDistances] = getObjectsInsideEllipse(commPairs,...
    vehicleMidpoints,RSUMidPoints,commRange,effectiveRange,locVehMidpoints,...
    locRSUMidpoints,bBoxesObjects,verbose)
% GETOBJECTSINSIDEELLIPSE For each communicating pair, finds objects inside
% the communications ellipse (see paper for details)
%
% Input
%   commPairs:          array containing pairwise IDs of vehicles
%                       participating in communication pairs
%   vehicleMidpoints:   vehicle midpoints
%   commRange:          communications range (in meters)
%   effectiveRange:     maximum distance from any object to both Tx and
%                       Rx in a comm. pair (i.e., effectivePairRange =
%                       dist(Tx,point)+dist(point,Rx))
%   locVehMidpoints:	selected IDs of vehicle midpoints
%   bBoxesObjects:      axis-aligned bounding boxes of objects
%                       
% Output
%   jointObjects:       objects inside ellipse of each comm. pair
%   jointDistances:     distance from each object to both Tx and
%                       Rx in a comm. pair (i.e., effectivePairRange =
%                       dist(Tx,point)+dist(point,Rx)) 
%
% Copyright (c) 2014-2015, Mate Boban

tic
% Get the center of bounding boxes for all objects
objectCenterpoints = ones(size(bBoxesObjects,1),2)*Inf;
objectCenterpoints(:,1) = (bBoxesObjects(:,3)+bBoxesObjects(:,4))/2;
objectCenterpoints(:,2) = (bBoxesObjects(:,1)+bBoxesObjects(:,2))/2;
% Half the size of objects' diagonals (used for determining the distance
% from comm. pair vehicles to object centerpoint)
objectsHalfDiagonal = sqrt((objectCenterpoints(:,2)-bBoxesObjects(:,1)).^2+...
    (objectCenterpoints(:,1)-bBoxesObjects(:,3)).^2);
% Get only those vehicle midpoints that are used in comm. pairs
vehicleMpSelected = vehicleMidpoints(locVehMidpoints,:);
% Get only those RSU midpoints that are used in comm. pairs
if ~isempty(locRSUMidpoints)
    RSUMpSelected = RSUMidPoints(locRSUMidpoints,:);
end

if exist('rangesearch') == 5 || exist('rangesearch') == 2
    % For each vehicle, get the objects within commRange
    [vehiclesObjects, vehiclesObjectsDist] = ...
        rangesearch(objectCenterpoints, vehicleMpSelected, commRange);
    if ~isempty(locRSUMidpoints)        
        % For each vehicle, get the objects within commRange
        [RSUObjects, RSUObjectsDist] = ...
            rangesearch(objectCenterpoints, RSUMpSelected, commRange);
    end
else
    %(NB: considerably slower than built-in rangesearch)
    vehiclesObjects = cell(size(vehicleMpSelected,1),1);
    vehiclesObjectsDist = cell(size(vehicleMpSelected,1),1);
    for ii=1:size(vehicleMpSelected,1)
        [vehiclesObjects{ii}, vehiclesObjectsDist{ii}] = ...
            externalCode.rangesearchYiCao.rangesearch...
            (vehicleMpSelected(ii,:), commRange, objectCenterpoints);      
    end
    vehiclesObjects = cellfun(@transpose,vehiclesObjects,'un',0);
    vehiclesObjectsDist = cellfun(@transpose,vehiclesObjectsDist,'un',0);    
    if ~isempty(locRSUMidpoints)        
        %(NB: considerably slower than built-in rangesearch)
        RSUObjects = cell(size(RSUMpSelected,1),1);
        RSUObjectsDist = cell(size(RSUMpSelected,1),1);
        for ii=1:size(RSUMpSelected,1)
            [RSUObjects{ii}, RSUObjectsDist{ii}] = ...
                externalCode.rangesearchYiCao.rangesearch...
                (RSUMpSelected(ii,:), commRange, objectCenterpoints);
        end
        RSUObjects = cellfun(@transpose,RSUObjects,'un',0);
        RSUObjectsDist = cellfun(@transpose,RSUObjectsDist,'un',0);
    end    
end

% Sort the objects, so that faster ismembc2 can be used instead of ismember
[vehObjectsCellTemp, vehObjectsDistCellTemp] = cellfun(@sortObjects,...
    vehiclesObjects,vehiclesObjectsDist,'uni',false);
if ~isempty(locRSUMidpoints)
    [RSUObjectsCellTemp, RSUObjectsDistCellTemp] = cellfun(@sortObjects,...
        RSUObjects,RSUObjectsDist,'uni',false);
end

%%  Get objects within ellipse for each comm. pair
newVehObjCell = cell(length(vehicleMidpoints),1);
newVehObjDistCell= cell(length(vehicleMidpoints),1);
newVehObjCell(locVehMidpoints,1) = vehObjectsCellTemp;
newVehObjDistCell(locVehMidpoints,1) = vehObjectsDistCellTemp;
if ~isempty(locRSUMidpoints)
    newRSUObjCell = cell(length(RSUMidPoints),1);
    newRSUObjDistCell= cell(length(RSUMidPoints),1);
    newRSUObjCell(locRSUMidpoints,1) = RSUObjectsCellTemp;
    newRSUObjDistCell(locRSUMidpoints,1) = RSUObjectsDistCellTemp;
end
if isempty(locRSUMidpoints)
    [jointObjects,jointDistances] = cellfun(@getjointObjectsRangesearch,...
        newVehObjCell(commPairs(:,1)),newVehObjCell(commPairs(:,2)),...
        newVehObjDistCell(commPairs(:,1)),newVehObjDistCell(commPairs(:,2)),...
        num2cell(effectiveRange),'uni',false);
else
    [jointObjects,jointDistances] = cellfun(@getjointObjectsRangesearch,...
        newRSUObjCell(commPairs(:,1)),newVehObjCell(commPairs(:,2)),...
        newRSUObjDistCell(commPairs(:,1)),newVehObjDistCell(commPairs(:,2)),...
        num2cell(effectiveRange),'uni',false);
end


%% Function to sort the objects, so that ismembc2 can be used instead of ismember 
    function[vehsBuilds, vehsBuildsDist] = sortObjects(vehiclesObjects,vehiclesObjectsDist)
        [vehsBuilds, vehsBuildsIndices] = sort(vehiclesObjects);
        vehsBuildsDist = vehiclesObjectsDist(vehsBuildsIndices);
    end
%% Function to get objects within ellipse for each comm. pair
    function[jointObjects, jointDistances]= getjointObjectsRangesearch...
            (objectsCommPair1,objectsCommPair2,distances1,distances2,commRange)
        % Returns objects that are within commRange distance for both
        % vehicles in the comm. pair AND the sum of minimum distance to
        % both vehicles is less than commRange
        %
        % Input
        %   objectsCommPair1:   objects within commRange for first vehicle
        %   objectsCommPair2:   objects within commRange for second vehicle
        %   distances1:         distances from vehicle 1 to objectsCommPair1
        %   distances2:         distances from vehicle 2 to objectsCommPair2
        %   commRange:          maximum communication range (NOTE: this can
        %                       be different than the original (LOS)
        %                       maximum comm range.        
        
        % Get the indices of objects shared by both vehicles in comm. pairs
        sharedObjectsIndices2=ismembc2(objectsCommPair1,objectsCommPair2);
        sharedObjectsIndices = (sharedObjectsIndices2>0);        
        % Get the numerical indices above 0 only for the second vehicle
        sharedObjectsIndices2=sharedObjectsIndices2(sharedObjectsIndices);
        % Sum of distances using logical indices for vehicle 1 and
        % numerical for vehicle 2 
        sharedDist1 = distances1(sharedObjectsIndices);
        sharedDist2 = distances2(sharedObjectsIndices2);
        
        sharedObjectDistances = sharedDist1+sharedDist2-2.*...
            objectsHalfDiagonal(objectsCommPair2(sharedObjectsIndices2))';
        % Get the shared objects irrespective of the distance
        jointObjects = objectsCommPair2(sharedObjectsIndices2);        
        % Get indices of objects whose sum to two vehicles in comm. pairs
        % is under the designated commRange 
        distBelowCommRange = find(sharedObjectDistances<commRange);
        % Get objects and summed distance to the vehicles in comm. pairs
        jointObjects = jointObjects(distBelowCommRange);
        jointDistances = sharedObjectDistances(distBelowCommRange);        
    end
if verbose
    fprintf(['Getting objects that are within commRange for both Tx '...
        'and Rx takes %f seconds.\n'], toc);
end
end