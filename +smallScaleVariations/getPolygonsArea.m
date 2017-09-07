function[area] = getPolygonsArea(polygons)
% GETBUILDINGSAREA Calculates the area of supplied polygons.
%
% Input:
%   polygons:       cell containing polygons in a three-column format:
%                   [ID,Lat,Lon] 
%
% Output:
%   area:           area of polygons
%
% Copyright (c) 2014-2015, Mate Boban

area = ones(size(polygons,1),1)*Inf;
for ii=1:size(polygons,1)
    currPolygonCoord = polygons{ii,1}(:,[2 3]);
    currPolygonCoord = currPolygonCoord(~isnan(currPolygonCoord(:,1)),:);
    area(ii) = polyarea(currPolygonCoord(:,1),currPolygonCoord(:,2));
end
