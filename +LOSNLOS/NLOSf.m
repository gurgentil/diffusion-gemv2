function[eFieldPerPair,distPerPair] = NLOSf(objectCellsFoliage,NLOSfPairs,...
    randCommPairs,obstructedCommPairsFListObsOnly,realLOSDists,...
    vehicleMidpoints,txPower,c,freq,Gt,Gr,verbose)
% NLOSF Calculates attenuation due to transmission through foliage.
% Calculations and parameters based on: "J. Goldhirsh and W. J. Vogel,
% "Handbook of propagation effects for vehicular and personal mobile
% satellite systems - overview of experimental and modeling results," The
% Johns Hopkins University, Applied Physics Laboratory and The University
% of Texas at Austin, Electrical Engineering Research Laboratory, Tech.
% Rep. A2A-98-U-0-021 (APL), EERL-98-12A (EERL), Dec. 1998.
%
% Input:
%   see simOneTimestep.m
%
% Output:
%   eFieldPerPair:         E-field for NLOSf pairs
%   distPerPair:           distance between NLOSf pairs
%
% Copyright (c) 2014-2015, Mate Boban

tic
% Mean Excess Loss per meter of transmission through foliage (cf. ref. above)
MEL = 0.79*(freq/10e9)^0.61;
% Get the IDs of NLOSf pairs
actualNLOSfPairs = find(NLOSfPairs==1);
% Array to store the distance of transmission through foliage
distThroughFoliage = zeros(size(actualNLOSfPairs));

for ii=1:size(actualNLOSfPairs,1)
    % Get the Tx and Rx from comm. pairs
    Tx = vehicleMidpoints(randCommPairs(actualNLOSfPairs(ii),1),:);
    Rx = vehicleMidpoints(randCommPairs(actualNLOSfPairs(ii),2),:);
    % Get obstructing foliage
    currObsFoliageList = objectCellsFoliage...
        (obstructedCommPairsFListObsOnly{ii},1);
    currDistThroughFoliage = 0;
    % For each foliage object, calculate the distance of transmission
    % through foliage (i.e., distance the LOS ray travels through each
    % foliage object). Sum up transmission distances through all foliage
    % objects.
    for jj = 1:size(currObsFoliageList,1)
        currObsFoliage = currObsFoliageList{jj};
        if size(currObsFoliage,1)>2
            currDistThroughFoliage = currDistThroughFoliage+...
                getDistForFoliage(Tx,Rx,currObsFoliage(:,[2 3]));
        end
    end
    distThroughFoliage(ii) = currDistThroughFoliage;
end

    function[dist] = getDistForFoliage(Tx,Rx,foliageObject)
        % Calculates transmission distance through foliage (i.e., the
        % distance that the LOS ray travels through the foliage object).
        [xx,yy]=externalCode.intersections.intersections([Tx(1) Rx(1)],...
            [Tx(2) Rx(2)],foliageObject(:,1),foliageObject(:,2),'false');
        if size(xx,1)>2
            % Multiple intersections of LOS ray and a single foliage
            % object; this can happen if foliage object is of complex
            % (concave) shape. In this case, take as the transmission
            % distance the following: distance(Tx,Rx) - ((distance from Tx
            % to intersection point closest to Tx) + (distance from Rx to
            % intersection point closest to Rx)).
            % I.e., trans. dist. = dist(Tx,Rx)-(dist(Tx,P1)+dist(P2,Rx))
            % Tx-----P1<-foliage->P2-----Rx
            distTxPoints = sqrt((Tx(1)-xx).^2+(Tx(2)-yy).^2);
            distRxPoints = sqrt((Rx(1)-xx).^2+(Rx(2)-yy).^2);
            dist = sqrt((Tx(1)-Rx(1))^2+(Tx(2)-Rx(2))^2)-...
                (min(distTxPoints)+min(distRxPoints));
        elseif size(xx,1)==1
            % Anomalous situation, skip this foliage
            dist=0;
        elseif size(xx,1)==2
            % Most common situation: two intersections between LOS ray and
            % foliage object.
            dist = sqrt((xx(1)-xx(2))^2+(yy(1)-yy(2))^2);
        else
            error('Something is wrong with NLOSf.m');
        end
    end

% Calculate the received power (dBm)
eFieldPerPair = LOSNLOS.freeSpace(realLOSDists(logical(NLOSfPairs)),...
    txPower,Gt,Gr,freq)-distThroughFoliage.*MEL;
distPerPair = realLOSDists(logical(NLOSfPairs));

% Convert to efield
eFieldPerPair = powerCalculations.getEfieldFromPwr(eFieldPerPair,Gr,c/freq);
if verbose
    fprintf('Calculating attenuation through foliage takes %f seconds.\n',toc);
end
end