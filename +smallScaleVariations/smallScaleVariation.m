function[smallScaleVar] = smallScaleVariation(newCommPairs,jointVehicles,...
    jointBuildings,jointFoliage,effRange,effectivePairRange,...
    minDensityRange,objectCellsBuildings,objectCellsFoliage,...
    LOSPairs,NLOSvPairs,NLOSfPairs,NLOSbPairs,smallScale,V2XType)
% SMALLSCALEVARIATIONS     
% Small-scale signal variation for all comm. pairs. Uses number of vehicles
% and area of static objects (buildings and foliage) to estimate the level
% of small-scale variations. For details, see the paper. 
%
% Input: 
%   See simSettings.m, simMain.m, and simOneTimestep.m
%
% Output:
%   smallScaleVar:          small-scale received power for all links for
%                           which received power was deemed to be
%                           significant based on the communication ranges
%                           and link types
%
% Copyright (c) 2014-2015, Mate Boban

% Get number of vehicles in communication ellipse for each comm. pair
numVehiclesPerPair = cellfun('size',jointVehicles,1);

% Calculate relative density: equal to the number of vehicles divided by
% the effective range
relVehDensity = numVehiclesPerPair./effRange.^2;

% Get maximum vehicle density in the system
maxVehDensity = max(numVehiclesPerPair(effRange>minDensityRange)./...
                effRange(effRange>minDensityRange).^2);

% Get the area of buildings and foliage
buildingsArea = smallScaleVariations.getPolygonsArea(objectCellsBuildings);
foliageArea = smallScaleVariations.getPolygonsArea(objectCellsFoliage);

% For each comm. pair, get the sum of building and foliage areas 
buildingAreaPerPair = zeros(size(newCommPairs,1),1);
foliageAreaPerPair = zeros(size(newCommPairs,1),1);

for zz=1:size(newCommPairs,1)
    currBuilds = jointBuildings{zz};
    currBuilds = currBuilds(~isnan(currBuilds));
    buildingAreaPerPair(zz) = sum(buildingsArea(currBuilds));    
    currFoliage = jointFoliage{zz};
    currFoliage = currFoliage(~isnan(currFoliage));
    foliageAreaPerPair(zz) = sum(foliageArea(currFoliage));
end

% Get relative building and foliage density
relBuildingDensity = buildingAreaPerPair./effRange.^2;
relFoliageDensity = foliageAreaPerPair./effRange.^2;

% Get maximum building and foliage density in the system
maxBuildingDensity = max(buildingAreaPerPair(effRange>minDensityRange)./...
                        effRange(effRange>minDensityRange).^2);
maxFoliageDensity = max(foliageAreaPerPair(effRange>minDensityRange)./...
                        effRange(effRange>minDensityRange).^2);

% If there are no effRange that are larger than minDensityRange,
% maxXDensity will not be set; set maxXDensity to Inf. 
if isempty(maxVehDensity)
    maxVehDensity = Inf;
end
if isempty(maxBuildingDensity)
    maxBuildingDensity = Inf;
end
if isempty(maxFoliageDensity)
    maxFoliageDensity = Inf;
end

% Calculate the vehicle density coefficient and static density coefficient
vehDensityCoeff = min(1,sqrt(relVehDensity./maxVehDensity));
staticDensityCoeff = min(1,sqrt((relBuildingDensity+relFoliageDensity)./...
                    (maxBuildingDensity+maxFoliageDensity)));

% Calculate minimum and maximum small-scale variation for each comm. pair
% based on comm. pair type (LOS, NLOSv, or NLOSb)
minSmallScaleVar(LOSPairs & effectivePairRange<Inf) = smallScale.(V2XType).minFadingLOS;
minSmallScaleVar(NLOSvPairs & effectivePairRange<Inf) = smallScale.(V2XType).minFadingNLOSv;
minSmallScaleVar(NLOSfPairs & effectivePairRange<Inf) = smallScale.(V2XType).minFadingNLOSf;
minSmallScaleVar(NLOSbPairs & effectivePairRange<Inf) = smallScale.(V2XType).minFadingNLOSb;
maxSmallScaleVar = ones(size(effectivePairRange))*Inf;
maxSmallScaleVar(LOSPairs & effectivePairRange<Inf) = smallScale.(V2XType).maxFadingLOS;
maxSmallScaleVar(NLOSvPairs & effectivePairRange<Inf) = smallScale.(V2XType).maxFadingNLOSv;
maxSmallScaleVar(NLOSfPairs & effectivePairRange<Inf) = smallScale.(V2XType).maxFadingNLOSf;
maxSmallScaleVar(NLOSbPairs & effectivePairRange<Inf) = smallScale.(V2XType).maxFadingNLOSb;

% Calculate additional small scale variation as a function of number of
% vehicles and area of static objects
% Get the small-scale variation variance
addSmallScaleVar = minSmallScaleVar(effectivePairRange<Inf)' + ...
                   .5*(maxSmallScaleVar(effectivePairRange<Inf) - ...
                   minSmallScaleVar(effectivePairRange<Inf)').*...
                   (vehDensityCoeff+staticDensityCoeff);
% Generate normal random variable using small-scale variation variance
smallScaleVar = randn(size(addSmallScaleVar)).*addSmallScaleVar;