function[objects, objectsDist] = getObjectsBelowThres(effectiveDist,jointObjects,jointDistances)
% GETOBJECTSBELOWTHRES For comm. pair, returns objects within given range
%
% Input:
% 	effectiveDist:          effective distance for communication pair
% 	jointObjects:           joint objects for communication pair
% 	jointDistances:         joint distances for communication pair
%
% Output:
% 	objects:                objects that are within effectiveDist
% 	objectsDist:            joint distance to objects from Tx and Rx
%
% Copyright (c) 2014-2015, Mate Boban

if effectiveDist<Inf
    objects = jointObjects(jointDistances<effectiveDist);
    objectsDist = jointDistances(jointDistances<effectiveDist);
else
    objects=[];
    objectsDist=[];
end