function[commPairs] = mapVehicleCommPairs(vehicleMidpoints,range,verbose)
% MAPVEHICLECOMMPAIRS For each vehicle, mapVehicleCommPairs finds all
% vehicles within "range" meters.
% Note: each comm. pair is found twice (e.g., A<->B found when searching
% for A (A->B) and B (B->A)).
%
% Copyright (c) 2014-2015, Mate Boban

tic
commPairs = cell(size(vehicleMidpoints,1),1);
for ii=1:size(vehicleMidpoints,1)
    temp = externalCode.rangesearchYiCao.rangesearch...
        (vehicleMidpoints(ii,:),range,vehicleMidpoints);
    % Remove yourself from the list of your neighbors
    if ~isempty(temp)
        commPairs(ii) = mat2cell(temp', 1, size(temp, 1));
    end
end
if verbose
    fprintf('Finding communicating pairs takes %f seconds.\n', toc);
end