function[Efield] = getReflEfield(reflCoeff,reflDist,txPower,Gt)
% GETREFLEFIELD Calculates the the E-field using reflection coefficients,
% traversed distance, frequency, and power.
%
% Input:
%   reflCoeff:              reflection coefficient for each reflected ray
%   reflDist:               distance traversed by each reflected ray
%   txPower:                Tx power (in dBm)
%   Gt                      antenna gain at the transmitter
%
% Output:
%   Efield:                 reflections E-field
%
% Copyright (c) 2014-2015, Mate Boban

% For details on calculating E-field, see Chapter 3 in T. S. Rappaport,
% "Wireless Communications: Principles and Practice." Prentice Hall, 1996.

% Get power in Watts
Pt = 10^(txPower/10)/1000; 
% Set reference distance in meters
d0 = 1; 
% Convert antenna gain at Rx from dBi to linear
Gt = 10^(Gt/10); 
% Calculate reference power flux density at distance d0
Pd0 = Pt*Gt/(4*pi*d0^2); 
% Calculate reference E-field
E0 = sqrt(Pd0*120*pi); 
% Calculate E-field
Efield = reflCoeff.*E0*d0./reflDist;