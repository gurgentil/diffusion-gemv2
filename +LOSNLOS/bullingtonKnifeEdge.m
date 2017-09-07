function [PrNLOSv,diffrRayDist,PrNLOSvLeft,diffrRayDistLeft,PrNLOSvRight,...
    diffrRayDistRight] = bullingtonKnifeEdge(RxCoord,TxCoord,...
    obsVehicleCorners,cornerOrientation,cornersLeft,cornersRight,distTxRx,...
    distTxObstacles,currObsVehHeights,TxHeight,RxHeight,fspcRxPwr,freq)
% BULLINGTONKNIFEEDGE Perform Bullington method for knife-edge diffraction
% over and off the sides of vehicles ("Radio propagation for vehicular
% communications", K. Bullington, IEEE Transactions on Vehicular
% Technology, Vol. 26, Issue 4). 
%
% Input:
%   see LOSNLOSv.m
%
% Output:
%   PrNLOSX:              Received power (dBm) for ray X
%   diffrRayDistX:        distance traversed by ray X
%
% Copyright (c) 2014-2015, Mate Boban

% Array for storing angles between Tx, Rx, and vehicle outline vertices.
% The goal is to find the largest angles alpha (angle (Tx,Rx,P)) and beta
% (angle (Rx,Tx,P)), as these will enable determining the tip of the
% equivalent obstruction 
% Structure of array: alpha (angle (Tx,Rx,P)) and beta (angle (Rx,Tx,P))
% alpha: [XRx YRx XTx YTx;
%         XRx YRx XP  YP]
% beta:  [XTx YTx XRx YRx;
%         XTx YTx XP  YP]
anglesTxRxP = polygonManipulation.setAndGetAngles...
    (RxCoord,TxCoord,obsVehicleCorners(:,[2 3]));
anglesRxTxP = polygonManipulation.setAndGetAngles...
    (TxCoord,RxCoord,obsVehicleCorners(:,[2 3]));

%% Calculate "left" side diffraction
if ~isempty(cornersLeft)
    anglesTxRxPLeft = anglesTxRxP(cornerOrientation);
    anglesRxTxPLeft = anglesRxTxP(cornerOrientation);    
    % Get the largest angles
    [maxAngleTxLeft,indexTxL] = max(abs(anglesRxTxPLeft));
    [maxAngleRxLeft,indexRxL] = max(abs(anglesTxRxPLeft));    
    if maxAngleTxLeft>90 || maxAngleRxLeft>90
        error('Something is wrong with the angles in LOSNLOSv!');
    end    
    % Get the actual points forming the largest angles
    maxTxPLeft = cornersLeft(indexTxL,[2 3]);
    maxRxPLeft = cornersLeft(indexRxL,[2 3]);    
    % Get the tip of the equivalent obstruction 
    PointLeft = externalCode.linlinintersect.linlinintersect([TxCoord(1),...
        TxCoord(2);maxTxPLeft(1),maxTxPLeft(2);RxCoord(1),RxCoord(2);...
        maxRxPLeft(1),maxRxPLeft(2)]);
    % Get distance between Tx-Rx line and point and projection of point on
    % Tx-Rx line
    [distLeft,PLeft] = polygonManipulation.getLinePointDist(TxCoord(1),...
        TxCoord(2),RxCoord(1),RxCoord(2),PointLeft(1),PointLeft(2));
    % Get distance from Tx and Rx to point
    distTxPLeft = sqrt((TxCoord(1)-PLeft(1)).^2+(TxCoord(2)-PLeft(2)).^2);
    distRxPLeft = sqrt((RxCoord(1)-PLeft(1)).^2+(RxCoord(2)-PLeft(2)).^2);
    % Perform single knife-edge diffraction
    AdLossLeft = LOSNLOS.obstacleAttenuationCorner(distLeft,distTxRx,...
        distTxPLeft,freq);    
    % Get distance traversed by the diffracted ray
    diffrRayDistLeft = distTxPLeft+distRxPLeft;
    % Subtract additional attenuation due to diffraction from received
    % power obtained using free space path loss
    PrNLOSvLeft = fspcRxPwr-AdLossLeft;
else
    PrNLOSvLeft = [];
    diffrRayDistLeft = [];
end

%% Calculate "right" side diffraction
% NB: same as for left. This could be simplified.
if ~isempty(cornersRight)
    anglesTxRxPRight = anglesTxRxP(~cornerOrientation);
    anglesRxTxPRight = anglesRxTxP(~cornerOrientation);
    % Get the largest angles
    [maxAngleTxRight,indexTxR] = max(abs(anglesRxTxPRight));
    [maxAngleRxRight,indexRxR] = max(abs(anglesTxRxPRight));    
    if maxAngleTxRight>90 || maxAngleRxRight>90
        error('Something is wrong with the angles in LOSNLOSv!');
    end 
    % Get the actual points forming the largest angles
    maxTxPRight = cornersRight(indexTxR,[2 3]);
    maxRxPRight = cornersRight(indexRxR,[2 3]);   
    if size(maxRxPRight,1)~=1
        keyboard
    end
    % Get the tip of the equivalent obstruction 
    PointRight = externalCode.linlinintersect.linlinintersect([TxCoord(1),...
        TxCoord(2);maxTxPRight(1),maxTxPRight(2);RxCoord(1),RxCoord(2);...
        maxRxPRight(1),maxRxPRight(2)]);  
    % Get distance between Tx-Rx line and point and projection of point on
    % Tx-Rx line
    [distRight,PRight] = polygonManipulation.getLinePointDist(TxCoord(1),...
        TxCoord(2),RxCoord(1),RxCoord(2),PointRight(1),PointRight(2));    
    % Get distance from Tx and Rx to point
    distTxPRight = sqrt((TxCoord(1)-PRight(1)).^2+(TxCoord(2)-PRight(2)).^2);
    distRxPRight = sqrt((RxCoord(1)-PRight(1)).^2+(RxCoord(2)-PRight(2)).^2);  
    % Perform single knife-edge diffraction
    AdLossRight = LOSNLOS.obstacleAttenuationCorner(distRight,distTxRx,...
        distTxPRight,freq); 
    % Get distance traversed by the diffracted ray
    diffrRayDistRight = distTxPRight+distRxPRight;
    % Subtract additional attenuation due to diffraction from received
    % power obtained using free space path loss   
    PrNLOSvRight = fspcRxPwr-AdLossRight;
else
    PrNLOSvRight = [];
    diffrRayDistRight = [];
end

%% Calculate top diffraction
% Array for angles for top diffraction.
anglesTopTx = polygonManipulation.setAndGetAngles([0,TxHeight],[distTxRx,...
    RxHeight],[distTxObstacles,currObsVehHeights]);
anglesTopRx = polygonManipulation.setAndGetAngles([distTxRx,RxHeight],[0,...
    TxHeight],[distTxObstacles,currObsVehHeights]);
% Get the largest angles
[~,indexTopTx] = max(abs(anglesTopTx));
[~,indexTopRx] = max(abs(anglesTopRx));
maxTxPTopX = distTxObstacles(indexTopTx);
maxTxPTopY = currObsVehHeights(indexTopTx);
maxRxPTopX = distTxObstacles(indexTopRx);
maxRxPTopY = currObsVehHeights(indexTopRx);
% Get the tip of the equivalent obstruction 
PointTop = externalCode.linlinintersect.linlinintersect([0,TxHeight;...
    maxTxPTopX,maxTxPTopY;distTxRx,RxHeight;maxRxPTopX,maxRxPTopY]);
% Get distance between Tx-Rx line and point and projection of point on
% Tx-Rx line 
[distTop,PTop] = polygonManipulation.getLinePointDist(0,TxHeight,distTxRx,...
    RxHeight,PointTop(1),PointTop(2));
% Get distance from Tx and Rx to point
distTxPTop = sqrt(PTop(1)^2+(TxHeight-PTop(2))^2);
distRxPTop = sqrt((distTxRx-PTop(1))^2+(RxHeight-PTop(2)).^2);
% If there's an anomaly where the center of obstructing vehicle is farther
% from Tx than Rx is from Tx (e.g., in case of a very long truck), then
% "put" the obstructing centerpoint between Tx and Rx
if distTxPTop>distTxRx
    % Put the obstructing centerpoint close to Rx
    distTxPTop = distTxRx - min(1,distTxRx/10);
    distRxPTop = distTxRx - distTxPTop;
end
if distRxPTop>distTxRx
    % Put the obstructing centerpoint close to Tx
    distTxPTop = 0 + min(1,distTxRx/10);
    distRxPTop = distTxRx - distTxPTop;
end
% Perform single knife-edge diffraction
AdLossTop = LOSNLOS.obstacleAttenuationCorner(distTop,distTxRx,distTxPTop,freq);
% Get distance traversed by the diffracted ray
diffrRayDist = distTxPTop+distRxPTop;
% Subtract additional attenuation due to diffraction from received
% power obtained using free space path loss
PrNLOSv = fspcRxPwr-AdLossTop;
