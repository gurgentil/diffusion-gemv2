function[commPairs] = mapCommPairs(vehicleMidpoints,range,verbose,RSUMidpoints)
% MAPVEHICLECOMMPAIRS For each vehicle, mapVehicleCommPairs finds all
% vehicles within "range" meters.
% Note: each comm. pair is found twice (e.g., A<->B found when searching
% for A (A->B) and B (B->A)).
%
% Copyright (c) 2014-2015, Mate Boban

tic
if nargin==3
    commPairs = cell(size(vehicleMidpoints,1),1);
    for ii=1:size(vehicleMidpoints,1)
        temp = externalCode.rangesearchYiCao.rangesearch...
            (vehicleMidpoints(ii,:),range,vehicleMidpoints);
        if ~isempty(temp)
            commPairs(ii) = mat2cell(temp', 1, size(temp, 1));
        end
    end
elseif nargin==4
    commPairs = cell(size(RSUMidpoints,1),1);
    for ii=1:size(RSUMidpoints,1)
        temp = externalCode.rangesearchYiCao.rangesearch...
            (RSUMidpoints(ii,:),range,vehicleMidpoints);
        if ~isempty(temp)
            commPairs(ii) = mat2cell(temp', 1, size(temp, 1));
        end
    end
else
    error('Incorrect number of arguments in mapCommPairs!');
end
if verbose
    fprintf('Finding communicating pairs takes %f seconds.\n', toc);
end