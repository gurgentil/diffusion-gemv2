function[outputObjects] = plotPolygons(objectCells,elevation,objectColor,timeShifts)
% PLOTRECPWR Plot polygons (e.g., vehicles, buidings, foliage) in KML
% format
%
% Input:
%   objectCells:        cell array containing each object separately
%   elevation:          elevation (height) of objects
%   objectColor:        color to use for objects
%   timeShifts:         time shifts (for animation in case of multiple
%                       timesteps)
%
% Output:
%   outputObjects:      objects in KML format
%
% Copyright (c) 2014-2015, Mate Boban

if nargin==3 
elseif nargin==4
    % Use Google's date format:
    S = 'yyyy-mm-ddTHH:MM:SSZ';
    % NB: for plotting purpose, assumption is that the time interval is
    % 1 second
    tStart = datestr(timeShifts,S);
    tEnd = datestr(timeShifts+1/24/60/60,S);
else
    error('Wrong number of input arguments!');
end

% Initialize kml string:
outputObjects='';

for jj=1:size(objectCells,1)
    currObject = objectCells{jj};
    Y = currObject(:,2);
    X = currObject(:,3);
    if length(elevation)==1
        Z = elevation;
        Z = repmat(Z,size(X,1),1);
    else
        Z = elevation(jj);
        Z = repmat(Z,size(X,1),1);
    end

    if nargin==3
        outputObjects = [outputObjects,externalCode.googleearth.ge_poly3(X,Y,Z,...
            'altitudeMode','relativeToGround',...
            'lineColor', ['ff',plotFunctions.rgbCol2hexCol(objectColor)],...
            'msgToScreen',false)];
    elseif nargin==4
        outputObjects = [outputObjects,externalCode.googleearth.ge_poly3(X,Y,Z,...
            'altitudeMode','relativeToGround',...
            'lineColor', ['ff',plotFunctions.rgbCol2hexCol(objectColor)],...
            'timeSpanStart',tStart(jj,:),...
            'timeSpanStop',tEnd(jj,:),...
            'msgToScreen',false)];
    else
        error('Unknown input!')
    end
end
