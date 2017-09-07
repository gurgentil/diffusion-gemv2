function[outputBars] = plotNumNeighbors(X,Y,Z,R,timeShifts,maxNumNeighbors)
% PLOTNUMNEIGHBORS Plot bars in KML format representing number of neighbors
%
% Input:
%   X,Y:                coordinates (lat/lon) of the vehicles
%   Z:                  height of the circle (represents rec. power level)
%   R:                  circle radius
%   timeShifts:         time shifts (for animation in case of multiple
%                       timesteps)
%   maxNumNeighbors:    maximum number of neighbors
%
% Output:
%   outputBars:         bars representing number of neighbors
%
% Copyright (c) 2014-2015, Mate Boban

outputBars = [];

% Use Google's date format:
S = 'yyyy-mm-ddTHH:MM:SSZ';

Z = max(.5, Z);
clr = jet(maxNumNeighbors);

% NB: for plotting purpose, assumption is that the time interval is
% 1 second
tStart = datestr(timeShifts,S);
tEnd = datestr(timeShifts+1/24/60/60,S);

for i = 1:size(X,1)
    color = Z(i);
    if color < 1
        color = 1;
    end
    currentColor = clr(color,:);
    outputBars = ...
        [outputBars,externalCode.googleearth.ge_cylinder(X(i,1),Y(i,1),R,Z(i,1),...
        'divisions',5,...
        'lineWidth',5.0,...
        'lineColor', ['ff',plotFunctions.rgbCol2hexCol(currentColor)],...
        'timeSpanStart',tStart(i,:),...
        'timeSpanStop',tEnd(i,:),...
        'polyColor', ['ff',plotFunctions.rgbCol2hexCol(currentColor)])];
end
