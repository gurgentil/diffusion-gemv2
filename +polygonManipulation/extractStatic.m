function[buildings,foliage] = extractStatic(OSMFile)
% EXTRACTSTATIC Function that kicks off extracting the buildings and
% foliage from OSM file
%
% Input:
%   OSMFile:            OSM file containing buildings and foliage
%
% Output:
%   buildings:          buildings in KML format
%   foliage:            foliage in KML format
%
% Copyright (c) 2014-2015, Mate Boban

% Create MATLAB structure from OSM file
[parsed_osm,~] = externalCode.openstreetmap.parse_openstreetmap(OSMFile);

% Get buildings and foliage in separate arrays.
[buildings,foliage] = externalCode.openstreetmap.plot_wayMod(axes,parsed_osm);