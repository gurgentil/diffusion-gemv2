function[PrNLOSv,diffrRayDist,PrNLOSvLeft,diffrRayDistLeft,PrNLOSvRight,...
    diffrRayDistRight] = ITURKnifeEdge(distTxRxCorners,pointOnTxRxLine,...
    TxCoord,cornerOrientation,cornersLeft,cornersRight,distTxRx,...
    distTxObstacles,currObsVehHeights,TxHeight,RxHeight,txPower,freq,Gt,Gr)
% ITURKNIFEEDGE Perform multiple knife-edge diffraction over and off the
% sides of vehicles based on ITU-R method. (Propagation by diffraction,
% Recommendation P.526, Feb. 2007, available at
% http://www.itu.int/rec/R-REC-P.526-13-201311-I/en). 
%
% Input:
%   see LOSNLOSv.m
%
% Output:
%   PrNLOSX:              Received power (dBm) for ray X
%   diffrRayDistX:        distance traversed by ray X
%
% Copyright (c) 2014-2015, Mate Boban

% Get distance to and projection of corner points to Tx-Rx line
distValidCornersL = distTxRxCorners(cornerOrientation);
distValidCornersR = distTxRxCorners(~cornerOrientation);
pointOnTxRxLineL = pointOnTxRxLine(cornerOrientation,:);
pointOnTxRxLineR = pointOnTxRxLine(~cornerOrientation,:);

% For each obstructing vehicle, find the corner that is farthest from Tx-Rx
% line -- the goal is to have a single diffraction over a vehicle, not
% multiple diffraction on its corners.

%% Calculate "left" side diffraction
if ~isempty(cornersLeft)
    % Using the fact that all corners belonging to a specific vehicle are
    % contiguous and that unique gives last index of occurence, get
    % last-occurring ID of vehicles
    [~,lastVehIdOccurenceL] = unique(cornersLeft(:,1));
    if size(lastVehIdOccurenceL,2) == 1
        % There is only one blocking vehicle/corner        
        [distValidCornersL,indL] = max(distValidCornersL);
        pointOnTxRxLineL = pointOnTxRxLineL(indL,:);
    else
        % Set first-occuring ID
        firstVehIdOccurenceL = [1,lastVehIdOccurenceL(1:end-1)+1];
        maxVals = ones(2,size(firstVehIdOccurenceL,2));
        % Find maximum distance corner for each vehicle
        for zz=1:size(firstVehIdOccurenceL,2)
            [maxVals(1,zz),maxVals(2,zz)] = max(distValidCornersL...
                (firstVehIdOccurenceL(zz):lastVehIdOccurenceL(zz)));
        end
        distValidCornersL = maxVals(1,:);
        pointOnTxRxLineL = pointOnTxRxLineL(maxVals(2,:),:);
    end
    % Distance from Tx to bases of obstructing point (i.e., where they
    % touch Tx-Rx line)
    distTxObstaclesL = sort(sqrt((TxCoord(1)-pointOnTxRxLineL(:,1)).^2+...
        (TxCoord(2)-pointOnTxRxLineL(:,2)).^2));
    % Calculate the received power.
    [PrNLOSvLeft,~,diffrRayDistLeft] = LOSNLOS.compMultKnifeAtten...
        ([TxHeight,distValidCornersL',RxHeight],[0,distTxObstaclesL',distTxRx],...
        txPower,freq,Gt,Gr);
    if isempty(diffrRayDistLeft)
        diffrRayDistLeft = Inf;
    end
else
    diffrRayDistLeft = [];
    PrNLOSvLeft = [];
end

%% Calculate "right" side diffraction
% NB: same as for left. This could be simplified.
if ~isempty(cornersRight)
    % Using the fact that all corners belonging to a specific vehicle are
    % contiguous and that unique gives last index of occurence, get
    % last-occurring ID of vehicles
    [~,lastVehIdOccurenceR] = unique(cornersRight(:,1));
    if size(lastVehIdOccurenceR,2) == 1
        % There is only one blocking vehicle/corner        
        [distValidCornersR,indR] = max(distValidCornersR);
        pointOnTxRxLineR = pointOnTxRxLineR(indR,:);
    else
        % Set first-occuring ID
        firstVehIdOccurenceR = [1,lastVehIdOccurenceR(1:end-1)+1];
        maxVals = ones(2,size(firstVehIdOccurenceL,2));
        % Find maximum distance corner for each vehicle
        for zz=1:size(firstVehIdOccurenceR,2)
            [maxVals(1,zz),maxVals(2,zz)] = max(distValidCornersR...
                (firstVehIdOccurenceR(zz):lastVehIdOccurenceR(zz)));
        end
        distValidCornersR = maxVals(1,:);
        pointOnTxRxLineR = pointOnTxRxLineR(maxVals(2,:),:);
    end
    % Distance from Tx to bases of obstructing point (i.e., where they
    % touch Tx-Rx line)
    distTxObstaclesR = sort(sqrt((TxCoord(1)-pointOnTxRxLineR(:,1)).^2+...
        (TxCoord(2)-pointOnTxRxLineR(:,2)).^2));
    % Calculate the received power.
    [PrNLOSvRight,~,diffrRayDistRight] = LOSNLOS.compMultKnifeAtten...        
        ([TxHeight,distValidCornersR',RxHeight],[0,distTxObstaclesR',distTxRx],...
        txPower,freq,Gt,Gr);
else
    diffrRayDistRight = [];
    PrNLOSvRight = [];
end

%% Calculate top diffraction
[PrNLOSv,~,diffrRayDist] = LOSNLOS.compMultKnifeAtten...
    ([TxHeight currObsVehHeights' RxHeight],[0 distTxObstacles' distTxRx],...
    txPower,freq,Gt,Gr);
if isempty(diffrRayDist)
    diffrRayDist=distTxRx;
end