function[eFieldPerPair,distPerPair] = LOSNLOSv(objectCellsVehicles,LOSPairs,...
    NLOSvPairs,randCommPairs,obstructedCommPairs,effectivePairRange,...
    realLOSDists,vehiclesHeight,vehicleMidpoints,RSUHeights,RSUMidpoints,...
    antennaHeight,txPower,c,freq,Gt,Gr,polarization,NLOSvModelType,...
    addNLOSvLoss,V2XType,verbose)
% LOSNLOSV Calculates received power for LOS and NLOSv links.
%
% Input:
%   see simOneTimestep.m
%
% Output:
%   eFieldPerPair:        E-field for LOS and NLOSv pairs
%   distPerPair:          distance between Tx and Rx in LOS and NLOSv pairs
%{
% For LOS links, uses the two-ray ground reflection model with effective
% ground reflection coefficient. Detailed description available in:
% "Geometry-Based Vehicle-to-Vehicle Channel Modeling for Large-Scale
% Simulation", Boban et al., IEEE Trans. Veh. Technol., 2014. 
% Performance evaluation described in: "Modeling vehicle-to-vehicle line of
% sight channels and its impact on application-layer performance", Boban
% et al., VANET '13.
%
% For NLOSv links, three models can be used (determined by NLOSvModelType):
%       1: Simple model: add attenuation based on the number of obstructing
%       vehicles, irrespective of their dimensions. NB: requires
%       addNLOSvLoss variable to be set up.
%       2: Bullington method for knife-edge diffraction ("Radio propagation
%       for vehicular communications", K. Bullington, IEEE Transactions on
%       Vehicular Technology, Vol. 26, Issue 4): Top and side
%       diffraction are accounted for.
%       3: Multiple knife-edge based on ITU-R method (Propagation by
%       diffraction, Recommendation P.526, Feb. 2007, available at
%       http://www.itu.int/rec/R-REC-P.526-13-201311-I/en). Top and side
%       diffraction are accounted for.
%       NB: Bullington results in approx. 8 dB more attenuation on average 
%       across typical distances (e.g., up to 500 meters), when compared to
%       multiple knife-edge method. 
% Details on how the NLOSv models are implemented are available in: "Impact
% of vehicles as obstacles in vehicular ad hoc networks", Boban et al.,
% IEEE Journal on Selected Areas in Communications, Vol. 29, Issue 1.
%}
%
% Copyright (c) 2014-2015, Mate Boban
tic

%% Array declaration and other prep work
% Get both NLOSv and LOS pairs with effective range < inf
NLOSvCommPairs = randCommPairs((NLOSvPairs | LOSPairs) & effectivePairRange<Inf,:);
% Get their distances
realLOSDistsNLOSv = realLOSDists((NLOSvPairs | LOSPairs) & effectivePairRange<Inf);
% Get new cell containing obsstructing vehicles for NLOSv and LOS pairs
obsCommPairsV = obstructedCommPairs((NLOSvPairs | LOSPairs) & effectivePairRange<Inf,:);
% Array to store E-field for LOS and NLOSv links
eFieldPerPair = ones(size(NLOSvCommPairs,1),1)*Inf;
% Array to store total diffracted ray distance
distPerPair = zeros(size(NLOSvCommPairs,1),1);
% Get Tx and Rx coordinates and height
if strcmpi(V2XType,'v2v')
    % V2V links
    TxHeights = vehiclesHeight(NLOSvCommPairs(:,1))+antennaHeight;
    TxCoords = vehicleMidpoints(NLOSvCommPairs(:,1),:);
else
    % V2I links
    TxHeights = RSUHeights(NLOSvCommPairs(:,1));
    TxCoords = RSUMidpoints(NLOSvCommPairs(:,1),:);
end
RxHeights = vehiclesHeight(NLOSvCommPairs(:,2))+antennaHeight;
RxCoords = vehicleMidpoints(NLOSvCommPairs(:,2),:);

%% LOS link calculations
% Determine which links are LOS and which NLOSv
LOSLinks = cellfun(@isempty,obsCommPairsV);
% For LOS links, calculate E-field using the two-ray model 
[Etot, ~, ~]= LOSNLOS.twoRay(sqrt((TxCoords(LOSLinks,1)...
    -RxCoords(LOSLinks,1)).^2+(TxCoords(LOSLinks,2)...
    -RxCoords(LOSLinks,2)).^2),TxHeights(LOSLinks),...
    RxHeights(LOSLinks),c/freq,txPower,Gt,Gr,polarization);
eFieldPerPair(LOSLinks) = Etot;
% Calculate the free-space path loss (in dBm) for all links (LOS and NLOSv)
fspcRxPwr = LOSNLOS.freeSpace(sqrt((TxCoords(:,1)-RxCoords(:,1)).^2+...
    (TxCoords(:,2)-RxCoords(:,2)).^2),txPower,Gt,Gr,freq);

%% NLOSv link calculations
if NLOSvModelType==1
    %% Simple model for NLOSv links
    numObsVehs = cellfun(@length,obsCommPairsV(~LOSLinks));
    fspcRxPwrNLOSv = fspcRxPwr(~LOSLinks);
    eFieldPerPairNLOSv = eFieldPerPair(~LOSLinks);
    eFieldPerPairNLOSv(numObsVehs==1) = powerCalculations.getEfieldFromPwr...
        (fspcRxPwrNLOSv(numObsVehs==1)-addNLOSvLoss(1),Gr,c/freq);
    eFieldPerPairNLOSv(numObsVehs==2) = powerCalculations.getEfieldFromPwr...
        (fspcRxPwrNLOSv(numObsVehs==2)-addNLOSvLoss(2),Gr,c/freq);
    eFieldPerPairNLOSv(numObsVehs>=3) = powerCalculations.getEfieldFromPwr...
        (fspcRxPwrNLOSv(numObsVehs>=3)-addNLOSvLoss(3),Gr,c/freq);
    eFieldPerPair(~LOSLinks) = eFieldPerPairNLOSv;    
elseif NLOSvModelType==2 || NLOSvModelType==3    
    for tt=1:size(NLOSvCommPairs,1)        
        if ~LOSLinks(tt)            
            TxHeight = TxHeights(tt);
            RxHeight = RxHeights(tt);            
            TxCoord = TxCoords(tt,:);
            RxCoord = RxCoords(tt,:);
            distTxRx = realLOSDistsNLOSv(tt);
            [PrNLOSv,PrNLOSvLeft,PrNLOSvRight,diffrRayDist,...
                diffrRayDistLeft,diffrRayDistRight] = deal([]);            
            % Get midpoints and heights of obstructing vehicles
            currObsVehsMidpoints = vehicleMidpoints(obsCommPairsV{tt},:);
            currObsVehHeights = vehiclesHeight(obsCommPairsV{tt});
            % Find points where obstructing vehicles obstruct Tx-Rx line
            [~, obsBlockTxRxLinePoint] = polygonManipulation.getLinePointDist...
                (TxCoord(1),TxCoord(2),RxCoord(1),RxCoord(2),...
                currObsVehsMidpoints(:,1),currObsVehsMidpoints(:,2));
            % Distance from Tx to each obstacle
            distTxObstacles = sqrt((TxCoord(1)-obsBlockTxRxLinePoint(:,1)).^2+...
                (TxCoord(2)-obsBlockTxRxLinePoint(:,2)).^2);

            %% Side diffractions part
            % Get corners of obstructing vehicles
            obsVehicleCorners = cell2mat(objectCellsVehicles(obsCommPairsV{tt,:},:));            
            % Distance from corners to Tx-Rx line
            [distTxRxCorners,pointOnTxRxLine] = ...
                polygonManipulation.getLinePointDist(TxCoord(1),TxCoord(2),...
                RxCoord(1),RxCoord(2),obsVehicleCorners(:,2),obsVehicleCorners(:,3));            
            % Get the corners that are "between" Tx and Rx (i.e., whose
            % projection on Tx-Rx line is on the Tx-Rx line segment).
            validCorners = polygonManipulation.segmentIntersect(TxCoord(1),...
                TxCoord(2),RxCoord(1),RxCoord(2),pointOnTxRxLine(:,1),...
                pointOnTxRxLine(:,2),obsVehicleCorners(:,2),obsVehicleCorners(:,3));           
            if sum(validCorners)>0
                % Get the "valid" corners
                obsVehicleCorners = obsVehicleCorners(validCorners,:);
                % Get the orientation of corners wrt Tx-Rx line
                cornerOrientation = polygonManipulation.tripletOrientation...
                    (TxCoord(1),TxCoord(2),RxCoord(1),RxCoord(2),...
                    obsVehicleCorners(:,2),obsVehicleCorners(:,3))<0;
                % Get corners left and right of Tx-Rx line
                cornersLeft = obsVehicleCorners(cornerOrientation,:);
                cornersRight = obsVehicleCorners(~cornerOrientation,:);                
                if NLOSvModelType==2
                    % Calculate multiple-knife edge using Bullington method
                    [PrNLOSv,diffrRayDist,PrNLOSvLeft,diffrRayDistLeft,...
                        PrNLOSvRight,diffrRayDistRight] = ...
                        LOSNLOS.bullingtonKnifeEdge(RxCoord,TxCoord,...
                        obsVehicleCorners,cornerOrientation,cornersLeft,...
                        cornersRight,distTxRx,distTxObstacles,currObsVehHeights,...
                        TxHeight,RxHeight,fspcRxPwr(tt),freq);
                elseif NLOSvModelType==3
                    % Calculate multiple-knife edge using ITU-R method
                    [PrNLOSv,diffrRayDist,PrNLOSvLeft,diffrRayDistLeft,...
                        PrNLOSvRight,diffrRayDistRight] = ...
                        LOSNLOS.ITURKnifeEdge(distTxRxCorners,pointOnTxRxLine,...
                        TxCoord,cornerOrientation,cornersLeft,cornersRight,...
                        distTxRx,distTxObstacles,currObsVehHeights,TxHeight,...
                        RxHeight,txPower,freq,Gt,Gr);
                end
            end
            % Use only the ray with maximum energy (between top, left, and
            % right ray).
            threeRaysDist = [diffrRayDist,diffrRayDistLeft,diffrRayDistRight];
            [threeRays,indThreeRays] = max([PrNLOSv,PrNLOSvLeft,PrNLOSvRight]);
            threeRaysDist = threeRaysDist(indThreeRays);
            if ~isempty(threeRaysDist(threeRays~=-Inf))
                % Get E-field from power
                threeRayEfields = powerCalculations.getEfieldFromPwr...
                    (threeRays(threeRays~=-Inf),Gr,c/freq);
                % Combine E-fields
                combinedEfield = powerCalculations.sumEfields...
                    (threeRayEfields,threeRaysDist(threeRays~=-Inf),2*pi*freq);
                % Store E-fields and distance for the rays
                eFieldPerPair(tt) = combinedEfield;
                distPerPair(tt) = min(threeRaysDist);
            end
        end
    end
else
    error('Unknown model for LOS and NLOSv links!');
end
if verbose
    fprintf('Calculating power for LOS and NLOSv links takes %f seconds.\n', toc);
end
% Assign the real LOS distance values to all the NLOSv rays that are not
% obstructed 
LOSDistsNLOSv = realLOSDists((NLOSvPairs | LOSPairs) & effectivePairRange<Inf);
distPerPair(distPerPair==0) = LOSDistsNLOSv(distPerPair==0);