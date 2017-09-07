function randCommPairs = getRandCommPairs(commPairs,numCommPairs,V2I)
% GETRANDCOMMPAIRS Generates random communication pairs. Takes all possible
% pairs, removes the duplicates and same-vehicle (A-A) pairs, and randomly
% selects numCommPairs of pairs. If numCommPairs is larger than the total
% number of pairs in the system, fetches all pairs in the system. Since it
% goes over all pairs (which can be millions), this function can be slow.
% 
% Input
%   commPairs:          cell containing all communication pairs (including
%                       duplicates) 
%   numCommPairs:       desired number of randomly chosen communication
%                       pairs 
%
% Output
%   randCommPairs:      randomly chosen communication pairs
%
% Copyright (c) 2014-2015, Mate Boban

% Get the number of neighbors per each vehicle
numPairsPerVehicle = cellfun('size', commPairs, 2);

% Array for all communication pairs
allPairs = ones(sum(numPairsPerVehicle),2);
counter = 1;
% Put commPairs in the allPairs array
for ii =1:size(commPairs,1)
    % Fetch the comm. pairs for current vehicle
    tempArray = commPairs{ii,:};
    if size(tempArray,2)>0
        allPairs(counter:counter+size(tempArray,2)-1,1) = ii;
        allPairs(counter:counter+size(tempArray,2)-1,2) = tempArray';
        counter=counter+size(tempArray,2);
    end
end

if nargin==2
    % These are V2V pairs
    % Remove the comm. pairs formed by one vehicle
    allPairs(allPairs(:,1)==allPairs(:,2),:)=[];
    % Sort each row so that first column value is less than the second
    rowsToFlip = find(allPairs(:,1)>allPairs(:,2));
    tempArray = allPairs(rowsToFlip,1);
    allPairs(rowsToFlip,1) = allPairs(rowsToFlip,2);
    allPairs(rowsToFlip,2) = tempArray;
end
% Remove duplicate rows
allPairs = unique(allPairs,'rows');

if numCommPairs>size(allPairs,1)
    fprintf(['In total, there are %i communication pairs in the system,\n'... 
        'given the current settings. Fetching %i pairs.\n'],...
        size(allPairs,1),size(allPairs,1));
    randCommPairs = allPairs;
else
    % Get random comm. pairs
    randRows = randperm(size(allPairs,1));
    randCommPairs = allPairs(randRows(1:numCommPairs),:);
end
