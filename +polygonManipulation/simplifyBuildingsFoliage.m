function[simplBuildings] = simplifyBuildingsFoliage(buildings,verbose,tolerance)
% REMOVEINNERPOLYANDSIMPLIFYBUILDINGS Removes the inner polygons (if any)
% from building outlines. If tolerance is provided, simplifies the
% building outlines using Douglas-Peucker polyline simplification algorithm
%
% Input:                        
%   buildings:                  building outlines in a three-column format:
%                               [ID,Lat,Lon]  
%   tolerance:                  tolerance (in meters) for simplifying
%                               building outlines 
%
% Output:
%   simplBuildings:             (simplified) building outlines
%
% Copyright (c) 2014-2015, Mate Boban

tic
% Initiate indices and counters
startIndex = 1;
endIndex=1;
simplBuildingsCounter = 1;

% Preallocate the array to be the size of original buildings
simplBuildings=zeros(size(buildings,1),3);

% If tolerance for building simplification is not provided, there is no
% simplification
if nargin == 2
    tolerance = 0;
end

while endIndex<=size(buildings,1)    
    while endIndex<=size(buildings,1) && ...
            buildings(startIndex,1)==buildings(endIndex,1)
        endIndex=endIndex+1;
    end
    simplifiedBuilding = buildings(startIndex:endIndex-1, [2 3]);
    % Run Douglas-Peucker polyline simplification algorithm
    if size(simplifiedBuilding,1)>4 && tolerance>0
        simplifiedBuilding = ...
             externalCode.dpsimplify.dpsimplify(simplifiedBuilding,tolerance);
    end
    % Add the current building to the array
    simplBuildings(simplBuildingsCounter:simplBuildingsCounter+...
        size(simplifiedBuilding,1)-1,:) = [repmat(buildings(startIndex,1),...
        size(simplifiedBuilding,1),1) simplifiedBuilding];
    simplBuildingsCounter = simplBuildingsCounter+size(simplifiedBuilding,1);
    startIndex = endIndex;
end
% Remove extra rows
simplBuildings=simplBuildings(simplBuildings(:,1)~=0,:);
if verbose
    fprintf(['Removing inner building polygons and simplifying buildings'...
        'takes %f seconds.\n'],toc);
end