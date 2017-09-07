function[Efield] = getEfieldFromPwr(PrdBm,Gr,lambda)
% GETEFIELDFROMPWR Calculates the magnitude of the E-field at the receiver
% antenna, based on the supplied received power in dBm.
%
% Input:
%   PrdBm:                  power in dBm
%   Gr:                     gain at the receiver in dBi
%   lambda:                	wavelength in meters
%
% Output:
%   Efield:                 output Efield in V/m
%
% Copyright (c) 2014-2015, Mate Boban

% For details on calculating E-field from received power, see Chapter 3 in
% T. S. Rappaport, "Wireless Communications: Principles and Practice."
% Prentice Hall, 1996.

% Convert from dBm to Watt
PrW = 10.^((PrdBm-30)/10);

% Convert antenna gain at Rx from dBi to linear
Gr = 10.^((Gr)/10);

% Convert to E-field
Efield = sqrt(PrW.*480.*pi^2./(Gr*lambda^2));