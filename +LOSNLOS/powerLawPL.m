function[Pr] = powerLawPL(dist,Pt,Gt,Gr,f,PLE)
% POWERLAWPL Calculates received power using power-law path loss as defined
% by the modified Friis transmission equation
% (http://en.wikipedia.org/wiki/Friis_transmission_equation#Modifications_to_the_basic_equation).
% Models path loss only (i.e., no fading).
%
% Input:
%	dist:               distance between Tx and Rx
%   Pt:                 transmitting power in dBm
%   Gt, Gr:             antenna gains in dBi
%   f:                  frequency in Hz
%   PLE:                path loss exponent
%
% Output:
%   Pr:                 Power at the receiver in dBm
%
% Copyright (c) 2014-2015, Mate Boban

%{
% NB: For a given frequency, results in practically identical results to
% log-distance path loss model
% (http://en.wikipedia.org/wiki/Log-distance_path_loss_model), given the
% appropriate path loss at the reference distance (PL0) and reference
% distance (d0), irrespective of PLE. For 5.9 GHz and d0 = 1m, PL0=47.8649.
% To convince yourself, execute the following:
PLE=2;Pt=0;Gt=0;Gr=0;f=5.9e9;d0=1;PL0=47.8649;dist=20:200;figure;hold on;
plot(dist,LOSNLOS.logDistancePL(dist,Pt,Gt,Gr,PLE,PL0,d0),'rx');
plot(dist,LOSNLOS.powerLawPL(dist,Pt,Gt,Gr,f,PLE),'kd');
%}

% Path loss
PL = 10*PLE.*log10(dist) + 20*log10(f) - 147.5522;
% Friis transmission equation 
Pr = Pt + Gt + Gr - PL;
