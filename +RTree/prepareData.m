function[bBoxes,objectCells,BigBx,startEndIndices] = prepareData(data,verbose)
% PREPAREDATA Builds R-tree, object bounding boxes, and puts the input data
% in a cell format, with each provided object in a separate cell.
% Input
%   data:               three-column array containing object points
%                       array format: [objectID latitude longitude]
%   verbose:            verbose output
%
% Output
%   bBoxes:             object bounding boxes
%   objectCells         cell containing each object in a separate cell
%   BigBx               rectangles forming the generated R-tree
%   startEndIndices     start and end index for each provided object
%
% Copyright (c) 2014-2015, Mate Boban

% NB: using global variables because passing a potentially large R-tree
% recursively can considerably degrade the performance 

% Plot the generated boxes? Purposely hard-coded to avoid passing as
% argument (most times will be 0)
plotOrNot=0;

%% Get the bounding rectangles and cells for the objects
tic
[bBoxes, objectCells, startEndIndices] = RTree.getBoxesAndCells(data);
if verbose
    fprintf('Getting the bounding rectangles and cells takes %f seconds.\n',toc);
end
tic

%% Initiate variables needed to build the R-tree
clear global
% BigBoxes contains rectangles forming the generated R-tree
global BigBoxes;
% Pool of IDs for R-tree elements
global IdPool;
IdPool = 0;
%% Build the R-tree
RTree.RTree(bBoxes',-1,0,-1);
% Clean BigBoxes
BigBoxes = BigBoxes(BigBoxes(:,1)~=0,:);
if verbose
    fprintf('Building R-tree takes %f seconds.\n',toc);
end
tic
%% Add the children to the R-tree
BigBoxes = RTree.addChildrenRTree(BigBoxes);
if verbose
    fprintf('Adding children to R-tree takes %f seconds.\n',toc);
end
BigBx = BigBoxes;
if plotOrNot
    plotFunctions.plotBigBoxes(BigBoxes(:,1:4));
    plotFunctions.plotData(data,verbose,'b');
end