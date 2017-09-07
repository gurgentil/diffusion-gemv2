function[Pr] = freeSpace(dist,Pt,Gt,Gr,f)
% FREESPACE Calculates received power using free space path loss and Friis
% transmission equation 
% (http://en.wikipedia.org/wiki/Free-space_path_loss and
% http://en.wikipedia.org/wiki/Friis_transmission_equation)
%
% Input:
%	dist                distance between Tx and Rx
%   Pt                  transmitting power in dBm
%   f                   frequency in Hz
%   Gt, Gr              antenna gains in dBi
%
% Output:
%   Pr:                 power at the receiver in dBm
%
% Copyright (c) 2014-2015, Mate Boban

% Free-space path loss
fspl = 20.*log10(dist) + 20*log10(f) - 147.5522;
% Friis transmission equation
Pr = Pt + Gt + Gr - fspl;