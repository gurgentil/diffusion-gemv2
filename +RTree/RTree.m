function[] = RTree(boundingBoxes,ParentId,level,prevColumnMax)
% RTREE Recursive function that builds the binary R-tree
% 
% Copyright (c) 2014-2015, Mate Boban

% Format of BigBoxes:
%   First 4 columns define bounding box of the rectangle (minX maxX minY maxY)
%   Column 5 is the rectangle ID
%   Column 6 is the ID of rectangle's parent (-1 for topmost rectangle)
%   Column 7 is the ID of the bounding_box (in case a rectangle is a leaf)
%   Column 8 is the level of the rectangle in the tree
%   Column 9 and 10 contain the IDs of children rectangles (-1 by default) 
%   Column 9 and 10 (children IDs) are assigned in addChildrenRTree.m

% Get the bounds of the current box
minX = min(boundingBoxes(1,:));
maxX = max(boundingBoxes(2,:));
minY = min(boundingBoxes(3,:));
maxY = max(boundingBoxes(4,:));

% Global variable IdPool - pool of IDs for the rectangles
global IdPool;
% Global variable BigBoxes - rectangles forming the generated R-tree
global BigBoxes;
% Counter for BigBoxes row insertion
persistent BigBoxesCounter;

if isempty(BigBoxes)
    % Initiate array and counter
    BigBoxes=zeros(size(boundingBoxes,2)*2,10);
    BigBoxesCounter = 1;
end

% Increment the level for current rectangles
MyLevel = level+1;
% Take the next ID from IdPool
MyId = IdPool+1;
IdPool = IdPool+1;

if size(boundingBoxes,2)==1
    % There is only 1 leaf    
    % Add the current rectangle to BigBoxes
    BigBoxes(BigBoxesCounter,:) = [minX maxX minY maxY MyId ParentId boundingBoxes(5,1) MyLevel -1 -1];
    BigBoxesCounter = BigBoxesCounter+1;
else
    NewParent = MyId;       
    % Add the current rectangle to BigBoxes
    BigBoxes(BigBoxesCounter,:) = [minX maxX minY maxY MyId ParentId -1 MyLevel -1 -1];
    BigBoxesCounter = BigBoxesCounter+1;
    
    % Check which dimension is longer: split over the longer one
    if (maxX-minX)>(maxY-minY)
        ColumnMax = 2;
    else
        ColumnMax = 4;
    end    
    if prevColumnMax == ColumnMax
        % Sorting is not necessary (sorted in previous recursion over the
        % same column); simply split bounding boxes. 
        sortedBoundingBoxes = boundingBoxes;
    else        
        % Sort the bounding boxes over the currently longer dimension: this
        % should reduce the overall area of the bounding boxes        
        sortedBoundingBoxes = transpose(boundingBoxes);
        sortedBoundingBoxes = sortrows(sortedBoundingBoxes,ColumnMax);
        sortedBoundingBoxes = transpose(sortedBoundingBoxes);
    end
    % Set the new midpoint; separate boxes based on it
    newMidpoint = floor(size(sortedBoundingBoxes,2)/2);
    leftBox = sortedBoundingBoxes(:,1:newMidpoint);
    rightBox = sortedBoundingBoxes(:,newMidpoint+1:size(sortedBoundingBoxes,2));    
    % Run the RTree on both set of boxes (recursion)
    RTree.RTree(leftBox, NewParent, MyLevel, ColumnMax);
    RTree.RTree(rightBox, NewParent, MyLevel, ColumnMax);
end