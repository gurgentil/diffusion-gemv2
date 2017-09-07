function[largeScalePwr] = largeScaleVariations(randCommPairs,LOSPairs,NLOSvPairs,...
    NLOSbPairs,NLOSfPairs,effectivePairRange,useReflDiffr,powerNLOSv,...
    powerNLOSf,finalReflRays,reflEfields,realLOSDists,reflDist,finalDiffrRays,...
    diffrEfields,diffrDist,c,freq,txPower,Gr,Gt,PLENLOSb,V2XType)
% LARGESCALEVARIATIONS     
% Large-scale signal variation (path loss and shadowing) for all comm. pairs.
% Calculates power from E-field. 
% Combines reflected and diffracted rays.
% Calculates log-distance path loss for NLOSb and NLOSf links/comm. pairs.
%
% Input: 
%   See simSettings.m, simMain.m, and simOneTimestep.m
%
% Output: 
%   largeScalePwr:          large-scale received power for all links for
%                           which received powerwas deemed to be
%                           significant based on the communication ranges
%                           and link types
%
% Copyright (c) 2014-2015, Mate Boban

% For details on calculating received power from E-field, see Chapter 3 in
% T. S. Rappaport, "Wireless Communications: Principles and Practice."
% Prentice Hall, 1996.

%% Reflection and diffraction manipulations for NLOSb and NLOSf links
% For each NLOSb and NLOSf links put reflected and diffracted rays in a cell 
% Column 1: E-field; Column 2: distance (for phase shift calculations)
allPairs = cell(sum(effectivePairRange~=Inf),2);
if useReflDiffr
    % Loop through the reflected rays, add to the correct comm. pair
    for ii = 1:size(reflEfields,1)
        allPairs{finalReflRays(2*ii,5),1} = ...
            [allPairs{finalReflRays(2*ii,5),1} reflEfields(ii)];
        allPairs{finalReflRays(2*ii,5),2} = ...
            [allPairs{finalReflRays(2*ii,5),2} reflDist(ii)];
    end
    % Loop through the diffracted rays, add to the correct comm. pair
    for ii = 1:size(diffrEfields,1)
        allPairs{finalDiffrRays(2*ii,5),1} = ...
            [allPairs{finalDiffrRays(2*ii,5),1} diffrEfields(ii)];
        allPairs{finalDiffrRays(2*ii,5),2} = ...
            [allPairs{finalDiffrRays(2*ii,5),2} diffrDist(ii)];
    end
end
% Calculate carrier frequency (radians per second)
freqAngx = 2*pi.*freq; 
% Calculate E-field for NLOSb and NLOSf links
fh = str2func('powerCalculations.sumEfields');
allPairsEfield = cellfun(fh,allPairs(:,1),allPairs(:,2),...
    num2cell(repmat(freqAngx,size(allPairs,1),1)),'uni', false);
% Set indices of empty cells to -Inf
emptyIndex = cellfun(@isempty,allPairsEfield);
allPairsEfield(emptyIndex) = {-Inf};      

%% Calculate received power (in dBm) from E-field for NLOSb and NLOSf pairs
lambda=(c/freq);
Grx = 10^(Gr/10);
% Received power (in Watts)
Prec = cell2mat(allPairsEfield).^2.*Grx*lambda^2/(480*pi^2);
% Received power (in dBm)
allPairsPower = 10*log10(Prec)+30;

%% Calculate received power (in dBm) from E-field for LOS and NLOSv links
if ~isempty(powerNLOSv)
    % Received power (in Watts)
    LOSNLOSvW = powerNLOSv.^2.*Grx*lambda^2/(480*pi^2);
    % Received power (in dBm)
    LOSNLOSvdBm = 10*log10(LOSNLOSvW)+30;
else
    LOSNLOSvdBm = zeros(0);
end

%% Calculate received power (in dBm) from E-field for NLOSf links
if ~isempty(powerNLOSf)
    % Received power (in Watts)
    NLOSfW = powerNLOSf.^2.*Grx*lambda^2/(480*pi^2);
    % Received power (in dBm)
    NLOSfdBm = 10*log10(NLOSfW)+30;
else
    NLOSfdBm = zeros(0);
end

%% Array for received power for all links
largeScalePwr = zeros(size(randCommPairs(effectivePairRange~=Inf),1),1);

%% Received power for LOS and NLOSv links
largeScalePwr(NLOSvPairs(effectivePairRange~=Inf) | ...
    LOSPairs(effectivePairRange~=Inf)) = LOSNLOSvdBm;

%% Received power for NLOSb and NLOSf links based on reflections and diffractions
NLOSbReflDiffrdBm = allPairsPower(NLOSbPairs(effectivePairRange~=Inf));

%% Calculate received power for NLOSb and NLOSf links based on log-distance path loss model
powerPLE = ones(size(effectivePairRange,1),1)*Inf;
powerPLE(NLOSbPairs) = LOSNLOS.powerLawPL(realLOSDists(NLOSbPairs),...
    txPower,Gt,Gr,freq,PLENLOSb.(V2XType).NLOSb);
powerPLE(NLOSfPairs) = LOSNLOS.powerLawPL(realLOSDists(NLOSfPairs),...
    txPower,Gt,Gr,freq,PLENLOSb.(V2XType).NLOSf);
powerPLE = powerPLE(effectivePairRange~=Inf);

%% For NLOSb and NLOSf links, use the max. power calculated by the two models
if sum(NLOSbPairs)>0
    NLOSbPLEdBm = powerPLE(NLOSbPairs(effectivePairRange~=Inf));
    largeScalePwr(NLOSbPairs(effectivePairRange~=Inf)) = ...
        max(NLOSbPLEdBm,NLOSbReflDiffrdBm);
end
if ~isempty(powerNLOSf)
    NLOSfPLEdBm = powerPLE(NLOSfPairs(effectivePairRange~=Inf));
    largeScalePwr(NLOSfPairs(effectivePairRange~=Inf)) = ...
        max(NLOSfPLEdBm,NLOSfdBm);
end