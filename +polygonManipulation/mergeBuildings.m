function[buildings] = mergeBuildings(buildings,verbose)
% MERGEBUILDINGS Merges building outlines that are sharing one or more
% sides (edges). Example: turns a row of townhouses in a single large
% building. In some cases, this can increase the speed of propagation
% calculations considerably, at no cost in terms of accuracy.
%
% Input:
%   buildings:                  building outlines in a three-column format:
%                               [ID,Lat,Lon]
%   verbose:                    verbose text output
%
% Output:
%   buildings:                  (merged) building outlines
%
% Copyright (c) 2014-2015, Mate Boban

tic
% Get the unique rows for buildings (i.e., remove the "wrap-around" rows)
buildingsUniqueRows = unique(buildings, 'rows');
% Get the rows with unique lat/lon coordinates
[~,buildingsUniqueCoordinates] = unique(buildingsUniqueRows(:,[2 3]),'rows');
% Running setdiff on unique rows and unique lat/lon rows will return the
% rows with duplicate lat/lon values
duplLatLonRows = setdiff(buildingsUniqueRows,...
    buildingsUniqueRows(buildingsUniqueCoordinates,:),'rows');
% Running setdiff on buildingsUniqueRows and duplLatLonRows removes the
% non-repeating lat/lon rows
[~, nonRepeatingRowIndices] = setdiff(buildingsUniqueRows(:,[2 3]),...
    duplLatLonRows(:,[2 3]),'rows');
% Get the duplicate rows - the opposite of nonRepeating rows. These are the
% rows we are after.
duplicateRows = buildingsUniqueRows(setdiff(1:size(buildingsUniqueRows,1),...
    nonRepeatingRowIndices),:);

while ~isempty(duplicateRows)
    % Get the rows that match current row's lat/lon
    sameLatLonRowIDs = duplicateRows(sum(ismember(duplicateRows(:,[2 3]),...
        duplicateRows(1,[2 3])),2)==2,:);
    % Get IDs of rows for merging
    getBuildingsToMergeHelper = ...
        buildings(sum(ismember(buildings(:,[2 3]),duplicateRows(1,[2 3])),2)==2,1);
    % Get building rows for merging
    getBuildingsToMerge = ...
        buildings(ismember(buildings(:,1),getBuildingsToMergeHelper),:);
    currentMergedBuilding = zeros(0);
    uniqueIDs = unique(getBuildingsToMerge(:,1));
    % Perform n-1 building unions over the buildings in sameLatLonRowIDs
    if numel(uniqueIDs)>1
        for kk=1:numel(uniqueIDs)-1
            % Get current building
            if kk==1
                [currentBuildingX,currentBuildingY] = poly2cw...
                    (getBuildingsToMerge(getBuildingsToMerge(:,1)==uniqueIDs(kk),2),...
                    getBuildingsToMerge(getBuildingsToMerge(:,1)==uniqueIDs(kk),3));
            else
                if isempty(currentMergedBuilding)
                    currentBuildingX = [];
                    currentBuildingY = [];
                else                    
                    currentBuildingX = currentMergedBuilding(:,1);
                    currentBuildingY = currentMergedBuilding(:,2);
                end
            end
            % Get next building            
            [nextBuildingX, nextBuildingY] = poly2cw...
                (getBuildingsToMerge(getBuildingsToMerge(:,1)==uniqueIDs(kk+1),2),...
                getBuildingsToMerge(getBuildingsToMerge(:,1)==uniqueIDs(kk+1),3));
            % Do the union on buildings (merge current and next building)
            [newBuildX, newBuildY] = polybool('union',currentBuildingX,...
                currentBuildingY,nextBuildingX,nextBuildingY);
            currentMergedBuilding = [newBuildX newBuildY];
        end
        % Add the common building ID to currentMergedBuilding
        currentMergedBuilding = ...
            [repmat(sameLatLonRowIDs(1,1),size(currentMergedBuilding,1),1)...
            currentMergedBuilding];
        % Remove the merged buildings
        buildings(ismember(buildings(:,1),getBuildingsToMergeHelper),:) = [];
        % Add the newly created building
        buildings = [buildings; currentMergedBuilding];
    end
    % Remove the rows in sameLatLonRowIDs from duplicateRows
    duplicateRows(sum(ismember(duplicateRows(:,[2 3]),...
        duplicateRows(1,[2 3])),2)==2,:) = [];
end
if verbose
    fprintf('Merging buildings takes %f seconds.\n', toc);
end