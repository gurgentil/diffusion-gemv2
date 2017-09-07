function[Pr,additionalAtten,mainObsDists] = ...
    compMultKnifeAtten(vehHeights,distToTx,Pt,f,Gt,Gr)
% COMPMULTKNIFEATTEN Perform multiple knife-edge diffraction based on ITU-R
% method. (Propagation by diffraction, Recommendation P.526, Feb. 2007,
% available at http://www.itu.int/rec/R-REC-P.526-13-201311-I/en).
%
% Input:
%   vehHeights:         heights of vehicles (Tx included)
%   distToTx            distance from each vehicle to Tx (Tx (zero) and Rx
%                       included) 
%   Pt                  transmitting power in dBm
%   f                   frequency in Hz
%   Gt, Gr              antenna gains in dBi
%
% Output:
%   Pr:                 total power at the receiver (dBm)
%   additionalAtten:    additional attenuation due to the obstacles
%   mainObsDists:       length of the diffracted ray
%
% Copyright (c) 2014-2015, Mate Boban & Tiago Vinhoza

% Sort vehicles based on distance from Tx; sort their heights accordingly
[distToTx,indDist] = sort(distToTx);
vehHeights = vehHeights(indDist);
members = length(distToTx);

%% Determining the main obstacles
next = 1;
% Set mainObs to be max size (size of members)
mainObs = ones(1,length(distToTx))*Inf;
mainObsCounter = 1;
for jj=1:members
    % skip for steps without changing the value of jj
    if jj == next
        % Check all the angles and select the largest
        angle = (vehHeights(jj+1:end) - vehHeights(jj))./(distToTx(jj+1:end)...
            - distToTx(jj));
        [~,indAngle] = max(angle);
        next = jj+indAngle;
        if ~isempty(next)
            if next~=members
                mainObs(mainObsCounter) = next;
                mainObsCounter = mainObsCounter+1;
            end
        end
    end
end
% Delete unused elements
mainObs(mainObsCounter:end) = [];

% Get distance traversed by the diffracting rays (from Tx, over main
% obstacles only, to Rx) 
if ~isempty(mainObs)
    % Add Tx and Rx to mainObs
    mainObsAll = [1 mainObs members];
    mainObsDists = sum(sqrt((vehHeights(mainObsAll(2:end))-...
        vehHeights(mainObsAll(1:end-1))).^2+(distToTx(mainObsAll(2:end))...
        -distToTx(mainObsAll(1:end-1))).^2));
else
% Add Tx-Rx distance if there are no main obstacles
    mainObsDists = distToTx(end);
end

% Drawing the "stretched rope" and building distBetwObs for correction
% factor calculation
% Add Tx and Rx indices to mainObs
mainObsWTxRx = [1 mainObs members]; % Tx - main obstacles - Rx
distBetwObs = ones(1,length(distToTx))*Inf;
distBetwObsCounter = 1;
for jj=1:length(mainObsWTxRx)-1
	distBetwObs(distBetwObsCounter) = distToTx(mainObsWTxRx(jj+1))-...
        distToTx(mainObsWTxRx(jj));
    distBetwObsCounter = distBetwObsCounter+1;
end
% Delete unused elements
distBetwObs(distBetwObsCounter:end) = [];

%% Determining the secondary obstacles
secObs = ones(3,length(mainObsWTxRx))*Inf;
secObsCounter = 1;
for kk = 1:length(mainObsWTxRx)-1
    delta = (mainObsWTxRx(kk+1) - mainObsWTxRx(kk));
    switch delta
        case 1
            % Nothing between two main obstacles
        case 2
            % A single obstacle between two main obstacles
            secObs(:,secObsCounter) = [(mainObsWTxRx(kk+1)+mainObsWTxRx(kk))/2;...
                mainObsWTxRx(kk);mainObsWTxRx(kk+1)];
            secObsCounter = secObsCounter+1;
        otherwise
            % More than one obstacle between two main obstacles
            if mainObsWTxRx(kk+1)-mainObsWTxRx(kk)>0
                cadidateObs = mainObsWTxRx(kk):mainObsWTxRx(kk+1);
            else
                cadidateObs = [];
            end
            if ~isempty(cadidateObs)
                obsHeight = vehHeights(cadidateObs);
                % Straight line connecting mainObsWTxRx(kk) and
                % mainObsWTxRx(kk+1);
                x1 = distToTx(mainObsWTxRx(kk));
                x2 = distToTx(mainObsWTxRx(kk+1));
                y1 = vehHeights(mainObsWTxRx(kk));
                y2 = vehHeights(mainObsWTxRx(kk+1));
                
                distToTxObs = distToTx(cadidateObs);
                
                % Measuring the distance between  mainObsWTxRx(kk) and
                % mainObsWTxRx(kk+1) line and top of obstacles
                distLineObs = ((y2-y1)*distToTxObs + x2*y1 - x1*y2)/(x2-x1);
                deltaDist = distLineObs - obsHeight;
                % Selecting the obstacle with shortest length.
                [~,indObs] = min(deltaDist);
                % Updating secObs array
                secObs(:,secObsCounter) = ...
                    [cadidateObs(indObs);mainObsWTxRx(kk);mainObsWTxRx(kk+1)];
                secObsCounter = secObsCounter+1;
            end
    end
end
% Delete unused elements
secObs(:,secObsCounter:end) = [];

%% Obtaining additional attenuation due to main obstacles
addAttMainObs = 0;
if isempty(mainObs)
    addAttMainObs = 0;
else
    % For each main obstacle, calculate attenuation
    for mm=1:length(mainObs);
        Tx = mainObsWTxRx(mm);
        Rx = mainObsWTxRx(mm+2);
        obs = mainObs(mm);        
        h1 = vehHeights(Tx);
        h2 = vehHeights(Rx);
        d = distToTx(Rx)-distToTx(Tx);
        d1 = distToTx(obs)-distToTx(Tx);
        h = vehHeights(obs);        
        addAttMainObs = addAttMainObs+LOSNLOS.obstacleAttenuation(h1,h2,h,d,d1,f);
    end
end

%% Obtaining additional attenuation due to secondary obstacles
addAttSecObs = 0;
if isempty(secObs)
    addAttSecObs = 0;
else
    % For each secondary obstacle, calculate attenuation
    for mm=1:size(secObs,2);
        Tx = secObs(2,mm);
        Rx = secObs(3,mm);
        obs = secObs(1,mm);        
        h1 = vehHeights(Tx);
        h2 = vehHeights(Rx);
        d = distToTx(Rx)-distToTx(Tx);
        d1 = distToTx(obs)-distToTx(Tx);
        h = vehHeights(obs);
        addAttSecObs = addAttSecObs+LOSNLOS.obstacleAttenuation(h1,h2,h,d,d1,f);
    end        
end

%% Calculating Correction Factor C
if isempty(distBetwObs)
    C = 0;
else
    mainObstleft = [distBetwObs 0]; 
    mainObstright = [0 distBetwObs]; 
    mainObstSum = mainObstright + mainObstleft; 
    mainObstSum = mainObstSum(2:end-1);
    C = -10*log10((prod(distBetwObs)*sum(distBetwObs))/...
        (prod(mainObstSum)*distBetwObs(1)*distBetwObs(end)));
end

%% Get received power
% Additional attenuation is the sum of attenuation due to main obstacles,
% secondary obstacles and correction factor
additionalAtten = addAttMainObs + addAttSecObs + C;
% Free-space attenuation
fspc = LOSNLOS.freeSpace(distToTx(end),Pt,Gt,Gr,f);
% Received signal power level 
Pr = fspc - additionalAtten;
