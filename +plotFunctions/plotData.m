function[]=plotData(data,verbose,currColor)
% PLOTDATA Plot provided data
%
% Input:
%   data:               input data in three column format: [ID,lat,lon]
%   currColor:          color used for plotting
%   verbose:            verbose output
% Copyright (c) 2014-2015, Mate Boban

tic
uniqueData = unique(data(:,1));
plotArray = zeros(size(data,1)+numel(uniqueData),size(data,2));
currPlotArrayID = 1;

if nargin==3
elseif nargin == 2
    currColor = 'b';
else
    error('Wrong number of input arguments!');
end

% Separate objects based on ID; add NaN rows to plot each object separately
for ii = 1:numel(uniqueData)
    currObject = data(data(:,1)==uniqueData(ii),:);
    plotArray(currPlotArrayID:currPlotArrayID+size(currObject,1),:) =...
        [currObject; ones(1, size(currObject,2))*NaN];
    currPlotArrayID = currPlotArrayID+size(currObject,1)+1;
end
% Plot the objects
plot(plotArray(:,3),plotArray(:,2),currColor);
if verbose
    fprintf('Plotting takes %f seconds.\n',toc);
end