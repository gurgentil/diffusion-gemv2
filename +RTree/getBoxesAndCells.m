function[bBoxes, objectCells, startEndIndices] = getBoxesAndCells(objects)
% GETOBJECTSANDCELLS Builds bounding boxes for provided objects. Puts the
% input data in a cell format, with each provided object in a separate
% cell. Returns start and end index for each provided object
% Input
%   objects:            three-column array containing object points
%                       array format: [objectID latitude longitude]
%
% Output
%   bBoxes:             object bounding boxes
%   objectCells         cell containing each object in a separate cell
%   startEndIndices     start and end index for each provided object
%
% Copyright (c) 2014-2015, Mate Boban

% Assumption: the objects are provided so that one object's points are all
% in one place in the array (i.e., they are congruent). If not, the array
% needs to be sorted based on the object ID.

% Get the number and IDs of objects
numObjects = unique(objects(:,1));
% Initiate counter for start and end index for each provided object
startIndex = 1;

% Bounding boxes for objects
bBoxes = zeros(numel(numObjects), 5);
% Start and end index for each provided object
startEndIndices = zeros(numel(numObjects), 2);

% Cell containing each object in a separate cell
objectCells = cell(numel(numObjects), 1);

% Loop through all objects
for ii=1:numel(numObjects)
    endIndex = startIndex;
    % Get all points for the current object
    while objects(startIndex,1)==objects(endIndex,1)
        endIndex = endIndex+1;
        if endIndex>size(objects,1)
            break
        end
    end
    startEndIndices(ii,1)=startIndex;
    startEndIndices(ii,2)=endIndex-1;
    getPoints = objects(startIndex:endIndex-1,:);
    getPoints(:,1) = ii;
    startIndex = endIndex;
    % Store all current object's points in a cell
    objectCells{ii}=getPoints;  
    % Get the bounding box information for the current object
    bBoxes(ii,1)=min(getPoints(:,3));
    bBoxes(ii,2)=max(getPoints(:,3));
    bBoxes(ii,3)=min(getPoints(:,2));
    bBoxes(ii,4)=max(getPoints(:,2));
    bBoxes(ii,5)=ii;    
end
