function[BigBoxes] = addChildrenRTree(BigBoxes)
% ADDCHILDRENRTREE adds IDs of children elements to each R-tree element
% 
% Copyright (c) 2014-2015, Mate Boban

% Get the first node's ID: needed to get the right row for parentID
firstId = BigBoxes(1,5);

% Skip first (source) node
for kk=2:size(BigBoxes,1)
    % If the first children column is occupied, use second
    if BigBoxes(BigBoxes(kk,6)-firstId+1,9)==-1
        BigBoxes(BigBoxes(kk,6)-firstId+1,9) = BigBoxes(kk, 5);
    else
        BigBoxes(BigBoxes(kk,6)-firstId+1,10) = BigBoxes(kk, 5);
    end    
end