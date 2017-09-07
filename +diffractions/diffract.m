function[diffrEfields,finalDiffrRays,diffrDist] = diffract(finalReflRays,...
    commPairsNLOSb,commPairDistsNLOSb,effRange,...
    newCommPairType,jointBuildingsNLOSb,jointDistancesNLOSb,...
    objectCellsBuildings,objectCellsVehicles,vehicleMidpoints,...
    vehiclesHeight,antennaHeight,BVHB,BVHV,txPower,Gt,Gr,c,freq,verbose)
% DIFFRACT Calculates diffracted rays for NLOSb comm. pairs. 
%
% Input:
%   see simOneTimestep.m
%
% Output:
%   diffrEfields:           E-field for reflections
%   finalDiffrRays:         diffraction array; structure:
%                           [x1,y1,x2,y2,commPairID]
%                           one difftacted ray occupies two rows (incident
%                           and diffracted component)
%   diffrDist:              distance traversed by reflections
%
% Copyright (c) 2014-2015, Mate Boban
tic
% NB: This function deals with diffractions off building corners only. For
% diffractions off vehicles, see LOSNLOSv.m

%{
% Employ the following heuristics fot diffracted NLOSb rays: 
%   - for NLOSb links with reflections: find diffractions whose traveled
%   distance is equal or less than the distance traversed by the shortest
%   reflected ray
%   - for NLOSb links with no reflections: find diffractions within max.
%   range for the NLOSb links
% Reasoning: compared to diffracted rays off building corners, rays
% reflected off buildings that are of same length usually carry
% considerably more power. For details, see:
% T. S. Rappaport, Wireless Communications: Principles and Practice.
Prentice Hall, 1996. 
% and
% "H. Anderson, “Building corner diffraction measurements and predictions
% using UTD,” IEEE Transactions on Antennas and Propagation, vol. 46, no.
% 2, pp. 292 –293, February 1998." 
%}

% Find the minimum reflection distance, used for filtering possible
% diffraction corners based on distance
minDists = sqrt((finalReflRays(:,1)-finalReflRays(:,3)).^2+...
    (finalReflRays(:,2)-finalReflRays(:,4)).^2);
% Total distance is sum of the two ray parts (Tx-P and P-Rx)
minDists = minDists(1:2:end-1)+minDists(2:2:end);

% Counter for the reflected rays
startIndex = 2;
endIndex = startIndex;
% Get minimum reflected ray distance for each NLOSb comm. pair
minDistReflRay = ones(size(commPairsNLOSb,1),1)*Inf;
% Skip every even row, since each reflected ray is composed of two parts
% (Tx-P and P-Rx), and ray distance is the sum of the two 
while endIndex<size(finalReflRays,1)
    endIndex = startIndex;
    % Skip every other row
    while finalReflRays(startIndex,5)==finalReflRays(endIndex,5) &&...
            endIndex<size(finalReflRays,1)
        endIndex = endIndex+2;
    end
    % Get the minimum reflection distance for current comm. pair
    currMinDistRefl = min(minDists(startIndex/2:(endIndex-2)/2));
    minDistReflRay(finalReflRays(startIndex,5)) = currMinDistRefl;
    startIndex = endIndex;
end
% Get effective range for NLOSb comm. pairs
effRangeNLOSb = effRange(newCommPairType==2);

% Eliminate reflections larger than NLOSb effective range 
minDistReflRay(minDistReflRay>effRangeNLOSb) = Inf;
% Distinguish NLOSb links with and w/o reflections
NLOSbRefl = minDistReflRay~=Inf; %& newCommPairType==2;
NLOSbNoRefl = minDistReflRay==Inf; %& newCommPairType==2;

% Set effective diffraction distance for each comm. pair based on the
% (non)existence of reflections
effectiveDiffrDist = ones(size(commPairsNLOSb,1),1)*Inf;
effectiveDiffrDist(NLOSbRefl) = minDistReflRay(NLOSbRefl);
effectiveDiffrDist(NLOSbNoRefl) = effRangeNLOSb(NLOSbNoRefl);

% Remove any effective diffraction distances larger than effRange
effectiveDiffrDist(effectiveDiffrDist>effRange(newCommPairType==2)) = Inf;

% Get the points for diffraction for each pair whose range<Inf
fh = str2func('diffractions.getObjectsBelowThres');
[diffrBuild, diffrBuildDist] = cellfun(fh, num2cell(effectiveDiffrDist),...
    jointBuildingsNLOSb,jointDistancesNLOSb,'uni', false);

% Get the max. number of diffracting rays: equal to the number of corners
% on buildings within the range 
numDiffrRays = sum(cellfun('size',diffrBuild,2));
% Preallocate diffraction array with initial size 100 X numDiffrRays
diffrRays = zeros(numDiffrRays*100,5);
diffrRayCounter = 1;
% When diffrRays array is filled up, increase it by diffrRayIncrement rows
diffrRayIncrement = 10000;

%% For each comm. pair, find feasible diffracting rays
for kk=1:size(diffrBuild,1)
    if ~isempty(diffrBuild{kk})
        % Get current comm. pair
        currCommPair = commPairsNLOSb(kk,:);
        % Get current joint building IDs
        currJointBuildings = diffrBuild{kk};        
        % Get the distance to the buildings
        currJointBuildingsDist = diffrBuildDist{kk};        
        % Get those buildings to which the distance is less than the
        % effectiveDiffrDist 
        currJointBuildings = currJointBuildings(currJointBuildingsDist...
            <effectiveDiffrDist(kk));        
        currJointBuildings = vertcat(objectCellsBuildings{currJointBuildings});
        % Remove NaN rows from corners used for diffraction
        currJointBuildings = currJointBuildings(~isnan(currJointBuildings(:,2)),:);
        % Add preceeding and succeeding point to each corner in currJointBuildings
        currJointBuildingsPrevSucc=ones(size(currJointBuildings,1),4)*-Inf;
        % Set first two columns: coordinates of previous point
        currJointBuildingsPrevSucc(2:end,[1 2]) = currJointBuildings(1:end-1,[2 3]);
        % Set remaining two columns: coordinates of next point
        currJointBuildingsPrevSucc(1:end-1,[3 4]) = currJointBuildings(2:end,[2 3]);
        % In case of multiple buildings, remove the previous and succeeding
        % points between different buildings
        sameAsNext = [1; currJointBuildings(1:end-1,1)==currJointBuildings(2:end,1)];
        currJointBuildingsPrevSucc(~sameAsNext,[1,2])=-Inf;
        sameAsNext = [sameAsNext(2:end); 1];
        currJointBuildingsPrevSucc(~sameAsNext,[3,4])=-Inf;
        currJointBuildingsPrevSucc(currJointBuildingsPrevSucc(:,1)==-Inf,[1 2])...
            = currJointBuildingsPrevSucc(currJointBuildingsPrevSucc(:,1)==-Inf,[3 4]);
        % Join previous and succ neighbors into one, as we only need one
        currJointBuildingsPrevSucc = currJointBuildingsPrevSucc(:,[1 2]);        
        % Remove duplicate rows
        [currJointBuildings, currJVehInd] = unique(currJointBuildings, 'rows');
        currJointBuildingsPrevSucc = currJointBuildingsPrevSucc(currJVehInd,:);
        % Get Tx and Rx coordinates
        TxX = vehicleMidpoints(currCommPair(1),1);
        TxY = vehicleMidpoints(currCommPair(1),2);
        RxX = vehicleMidpoints(currCommPair(2),1);
        RxY = vehicleMidpoints(currCommPair(2),2);
        %% Check if the corner is "between" Tx and Rx (i.e., if corner
        % Tx-Rx-P and corner Rx-Tx-P are below 90 degrees). If not, remove
        % the corner. For details, see:
        % http://www.mathworks.com/matlabcentral/newsreader/view_thread/164048 
        firstIf = (RxX-TxX).*(currJointBuildings(:,2)-TxX)+(RxY-TxY).*...
            (currJointBuildings(:,3)-TxY) >= 0;
        secondIf = (RxX-TxX).*(currJointBuildings(:,2)-RxX)+(RxY-TxY).*...
            (currJointBuildings(:,3)-RxY) <= 0;
        PinsideTxRx = logical(firstIf.*secondIf);        
        currJointBuildings = currJointBuildings(PinsideTxRx,:);
        currJointBuildingsPrevSucc = currJointBuildingsPrevSucc(PinsideTxRx,:);
        
        %% Remove the corners that cannot obstruct the Tx-Rx line 
        % (due to their orientation wrt Tx-Rx line)
        % Find Tx-Rx midpoint
        midpointX = (TxX+RxX)/2;
        midpointY = (TxY+RxY)/2;        
        % Orientation of midpoint wrt Tx-P and Rx-P
        orientMidpointTxP = polygonManipulation.tripletOrientation(TxX,TxY,...
            currJointBuildings(:,2),currJointBuildings(:,3),midpointX,midpointY);
        orientMidpointRxP = polygonManipulation.tripletOrientation(RxX,RxY,...
            currJointBuildings(:,2),currJointBuildings(:,3),midpointX,midpointY);
        % Orientation of neighboring corners wrt Tx-P and Rx-P
        orientNeighborCornerTxP = polygonManipulation.tripletOrientation...
            (TxX,TxY,currJointBuildings(:,2),currJointBuildings(:,3),...
            currJointBuildingsPrevSucc(:,1),currJointBuildingsPrevSucc(:,2));
        orientNeighborCornerRxP = polygonManipulation.tripletOrientation...
            (RxX,RxY,currJointBuildings(:,2),currJointBuildings(:,3),...
            currJointBuildingsPrevSucc(:,1),currJointBuildingsPrevSucc(:,2));
        % Remove those corners whose neighboring corner is not of the same
        % orientation as the midpoint 
        currJointBuildings = currJointBuildings(orientMidpointTxP.*...
            orientNeighborCornerTxP>0 & orientMidpointRxP.*orientNeighborCornerRxP>0,:);
        
        %% If there is one of more diffracting corner
        if size(currJointBuildings,1)>=1
            % Get the diffracting rays for the current comm. pair
            currPairDiffractions = zeros(size(currJointBuildings,1)*2,5);
            % Put Tx in every odd rows
            currPairDiffractions(1:2:end-1,1) = TxX;
            currPairDiffractions(1:2:end-1,2) = TxY;
            % Put Rx in even rows
            currPairDiffractions(2:2:end,1) = RxX;
            currPairDiffractions(2:2:end,2) = RxY;
            % Add feasible corners to each row
            currPairDiffractions(1:2:end-1,3) = currJointBuildings(:,2)';
            currPairDiffractions(1:2:end-1,4) = currJointBuildings(:,3)';
            currPairDiffractions(2:2:end,3) = currJointBuildings(:,2)';
            currPairDiffractions(2:2:end,4) = currJointBuildings(:,3)';
            currPairDiffractions(:,5) = kk;          
            % If neccesary, increase the size of the preallocated array
            if size(currPairDiffractions,1)+diffrRayCounter>size(diffrRays,1)
                if verbose
                    disp('Increasing the preallocated array for diffractions...');
                end
                diffrRays(end+1:end+diffrRayIncrement,:)=0;
            end
            diffrRays(diffrRayCounter:diffrRayCounter+...
                size(currPairDiffractions,1)-1,:) = currPairDiffractions;
            diffrRayCounter = diffrRayCounter+size(currPairDiffractions,1);
        end        
    end
end
% Delete any zero-value ray entries.
diffrRays = diffrRays(diffrRays(:,1)~=0,:);

%% First, test diffraction points against all buildings
% Test the Tx-Corner lines first
diffrRaysBTx = diffrRays(1:2:end-1,:);
obsDiffrRaysBTx = polygonManipulation.getObstructingObjects(diffrRaysBTx,...
    objectCellsBuildings,vehicleMidpoints,BVHB,-1,1,verbose);
% Get the non-obstructed Tx-Corner rays
diffrRaysBTx = diffrRaysBTx(obsDiffrRaysBTx==0,:);
% For those Tx-Corner rays that are not obstructed, test Corner-Rx rays
diffrRaysBRx = diffrRays(2:2:end,:);
diffrRaysBRxUnobsTx = diffrRaysBRx(obsDiffrRaysBTx==0,:);
obsDiffrRaysBRx = polygonManipulation.getObstructingObjects(diffrRaysBRxUnobsTx,...
    objectCellsBuildings,vehicleMidpoints,BVHB,-1,1,verbose);
% Array of potentially diffracting rays
finalDiffrRaysB = zeros(sum(obsDiffrRaysBRx==0)*2,5);
finalDiffrRaysB(1:2:end-1,:) = diffrRaysBTx(obsDiffrRaysBRx==0,:);
finalDiffrRaysB(2:2:end,:) = diffrRaysBRxUnobsTx(obsDiffrRaysBRx==0,:);

%% Test potentially diffracting rays against vehicle blocking
% Get Tx rays
finalDiffrVTx = finalDiffrRaysB(1:2:end-1,:);
% Check which are obstructed
obsReflDiffrVTx = polygonManipulation.getObstructingObjects(finalDiffrVTx,...
    objectCellsVehicles,vehicleMidpoints,BVHV,-1,1,verbose,vehiclesHeight,...
    antennaHeight,commPairsNLOSb);
finalDiffrVTx = finalDiffrVTx(obsReflDiffrVTx==0,:);

% For those Tx-Corner rays that are not obstructed, test Corner-Rx rays
finalDiffrVRx = finalDiffrRaysB(2:2:end,:);
finalDiffrRaysVRxUnobsTx = finalDiffrVRx(obsReflDiffrVTx==0,:);
obsDiffrRaysVRx = polygonManipulation.getObstructingObjects...
    (finalDiffrRaysVRxUnobsTx,objectCellsVehicles,vehicleMidpoints,BVHV,...
    -1,1,verbose,vehiclesHeight,antennaHeight,commPairsNLOSb);

% Put all feasible diffracted rays in finalDiffrRays
finalDiffrRays = zeros(sum(obsDiffrRaysVRx==0)*2,5);
finalDiffrRays(1:2:end-1,:) = finalDiffrVTx(obsDiffrRaysVRx ==0,:);
finalDiffrRays(2:2:end,:) = finalDiffrRaysVRxUnobsTx(obsDiffrRaysVRx==0,:);

%% All diffracted rays are now found - calculate rec. power for each ray
% Find the height from Tx-Rx line to corner P (heightCorners) and vertical
% translation of P on Tx-Rx line (pointsOnTxRxLine)
[heightCorners,pointsOnTxRxLine] = polygonManipulation.getLinePointDist...
    (finalDiffrRays(1:2:end-1,1),finalDiffrRays(1:2:end-1,2),...
    finalDiffrRays(2:2:end,1),finalDiffrRays(2:2:end,2),...
    finalDiffrRays(1:2:end-1,3), finalDiffrRays(1:2:end-1,4));
% Distance between Tx and pointsOnTxRxLine
distsTxP = sqrt((finalDiffrRays(1:2:end-1,1)-pointsOnTxRxLine(:,1)).^2+...
    (finalDiffrRays(1:2:end-1,2)-pointsOnTxRxLine(:,2)).^2);
% Distance between Tx and corner
distsTxCorner = sqrt((finalDiffrRays(1:2:end-1,1)-finalDiffrRays(1:2:end-1,3)).^2 ... 
    +(finalDiffrRays(1:2:end-1,2)-finalDiffrRays(1:2:end-1,4)).^2);
% Distance between Rx and corner
distsRxCorner = sqrt((finalDiffrRays(2:2:end,1)-finalDiffrRays(2:2:end,3)).^2+...
    (finalDiffrRays(2:2:end,2)-finalDiffrRays(2:2:end,4)).^2);

% Get LOS distances
LOSDistDiffr = commPairDistsNLOSb(finalDiffrRays(1:2:end-1,5));
% Calculate the power of diffracted rays
powerDiffrRays = LOSNLOS.freeSpace(LOSDistDiffr,txPower,Gt,Gr,freq) - ...
    LOSNLOS.obstacleAttenuationCorner(heightCorners,LOSDistDiffr,distsTxP,freq);

% Calculate distance traversed by diffracted ray
diffrDist = sqrt((distsTxCorner + distsRxCorner).^2+ ...
    (vehiclesHeight(commPairsNLOSb(finalDiffrRays(1:2:end-1,5),1))-...
    vehiclesHeight(commPairsNLOSb(finalDiffrRays(1:2:end-1,5),2))).^2);

% Get E-field for diffracred rays
diffrEfields = powerCalculations.getEfieldFromPwr(powerDiffrRays, Gr, c/freq);
if verbose
    fprintf('Calculating diffractions takes %f seconds.\n', toc);
end