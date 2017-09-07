function[Efield] = sumEfields(inputEfields,inputDists,freqAng)
% CALCCOMPLETEEFIELD2 Sums the input E-fields. Uses maximum E-field's
% distance as reference.
%
% Input: 
%   inputEfields:           Efield of input rays/paths
%   inputDists:             distance traveled by input rays
%   freqAng:                carrier frequency (radians per second)
%
% Output: 
%   Efield:                 output E-field
%
% Copyright (c) 2014-2015, Mate Boban

% Speed of light
c = 299792458; 

% Find the distance of the strongest E-field, set as reference distance
[~,maxEfieldInd] = max(inputEfields);
refDist = inputDists(maxEfieldInd);

% Shift and sum the E-fields
Efield = sum(inputEfields.*cos(freqAng.*(refDist./c-inputDists./c)));