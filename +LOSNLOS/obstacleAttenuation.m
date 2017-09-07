function additionalAtten = ...
    obstacleAttenuation(txHeight,rxHeight,obsHeight,distTxRx,distTxObs,f)
% OBSTACLEATTENUATION Calculates attenuation caused by a single obstacle.
% For details, see: Propagation by diffraction, Recommendation P.526, Feb.
% 2007, available at http://www.itu.int/rec/R-REC-P.526-13-201311-I/en).
%
% Input:
%   txHeight:               Tx height
%   rxHeight:               Rx height
%   obsHeight:              obstacle height
%   distTxRx:               Tx-Rx distance
%   distTxObs:              Tx-obstacle distance
%   f:                      frequency in GHz
%
% Output:
%   additionalAtten:        additional attenuation due to the obstacle
%
% Copyright (c) 2014-2015, Mate Boban & Tiago Vinhoza

% Get wavelenght in meters
lambda = 299792458/f; 
% Get distance between Rx and obstacle
distRxObs = distTxRx-distTxObs; 
% Height of point on line connecting Tx and Rx at obstacle position
obsHeightTxRxLine = (rxHeight-txHeight)./distTxRx.*distTxObs + txHeight;
% Calculate additional attenuation (see P.526, pg 18 onwards)
H = obsHeight-obsHeightTxRxLine;
r1 = sqrt(lambda.*distTxObs.*distRxObs./distTxRx); 
V0 = sqrt(2).*H./r1;
additionalAtten = zeros(length(V0),1);
additionalAtten(V0>-0.78) = 6.9 + 20*log10(sqrt((V0-0.1).^2+1)+V0-0.1);
