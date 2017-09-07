function[]=plotBigBoxes(boundingBoxes)
% PLOTBIGBOXES Plot object bounding boxes 
%
% Input:
%   boundingBoxes:      object bounding boxes
%
% Copyright (c) 2014-2015, Mate Boban

figure;hold on;
plot([boundingBoxes(:,1) boundingBoxes(:,2) boundingBoxes(:,2) boundingBoxes(:,1) boundingBoxes(:,1)]',...
    [boundingBoxes(:,3) boundingBoxes(:,3) boundingBoxes(:,4) boundingBoxes(:,4) boundingBoxes(:,3)]','k-');


