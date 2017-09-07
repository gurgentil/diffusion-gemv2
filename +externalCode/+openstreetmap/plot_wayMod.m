function [buildings, foliage] = plot_wayMod(ax, parsed_osm, map_img_filename)
%PLOT_WAY   plot parsed OpenStreetMap file
%
% usage
%   PLOT_WAY(ax, parsed_osm)
%
% input
%   ax = axes object handle
%   parsed_osm = parsed OpenStreetMap (.osm) XML file,
%                as returned by function parse_openstreetmap
%   map_img_filename = map image filename to load and plot under the
%                      transportation network
%                    = string (optional)
%
% See also PARSE_OPENSTREETMAP, EXTRACT_CONNECTIVITY.
%
% File:         plot_way.m
% Author:       Ioannis Filippidis, jfilippidis@gmail.com
% Date:         2010.11.06 - 2012.04.17
% Language:     MATLAB R2012a
% Purpose:      plot parsed OpenStreetMap file
% Copyright:    Ioannis Filippidis, 2010-

% Modified by:  Mate Boban, 2012

if nargin < 3
    map_img_filename = [];
end

[bounds, node, way, ~] = externalCode.openstreetmap.assign_from_parsed(parsed_osm);

disp_info(bounds, size(node.id, 2), size(way.id, 2))
[buildings, foliage]=show_ways(ax, bounds, node, way, map_img_filename);

function [buildings, foliage] = show_ways(hax, bounds, node, way, map_img_filename)
%externalCode.openstreetmap.show_map(hax, bounds, map_img_filename)

%plot(node.xy(1,:), node.xy(2,:), '.')

% Mod: arrays for buildings and foliage
buildings = zeros(0);
foliage = zeros(0);

key_catalog = {};
for i=1:size(way.id, 2)
    [key, val] = externalCode.openstreetmap.get_way_tag_key(way.tag{1,i} );    
    % Find unique way types
    if isempty(key)
    elseif isempty( find(ismember(key_catalog, key) == 1, 1) )
        key_catalog(1, end+1) = {key};
    end
    
    flag = 0;
    switch key
        case 'building'
            flag = 2;
        case 'shop'
            flag = 3;
        case 'amenity'
            flag = 4;
            % Mod: flag 5 denotes any type of way that contains trees (as per
            % http://wiki.openstreetmap.org/wiki/Tag:landuse%3Dforest)
        case 'landuse'
            if strcmp(val, 'forest')
                flag = 5;
                disp('Forest found')
            end
        case 'natural'
            if strcmp(val, 'wood') || strcmp(val, 'tree') || strcmp(val, 'tree_row')
                flag = 5;
                disp('Trees found')
            end
        case 'wood'
            flag = 5;
            disp('Forest found')
            
        %otherwise
        %    disp('way without tag.')
    end
    
    % Plot highway
    way_nd_ids = way.nd{1, i};
    num_nd = size(way_nd_ids, 2);
    nd_coor = zeros(2, num_nd);
    nd_ids = node.id;
    % Mod: nodes that form a way might not exist in the node list
    emptyNodeFlag=0;
    for j=1:num_nd
        cur_nd_id = way_nd_ids(1, j);
        nodeXY=node.xy(:, cur_nd_id == nd_ids);
        if ~isempty(nodeXY)
            nd_coor(:, j) = node.xy(:, cur_nd_id == nd_ids);
        else
            nd_coor(:, j) = -Inf;
            emptyNodeFlag=1;
        end
    end
    
    if emptyNodeFlag
        empty_nds = nd_coor(1,:)==-Inf;
        nd_coor(:,empty_nds)=[];
        num_nd = num_nd-sum(empty_nds);
    end
    
    if num_nd>0
        if flag == 2
            buildings = [buildings; [repmat(way.id(i), num_nd, 1), ...
                nd_coor(2,:)', nd_coor(1,:)']];
        elseif flag == 3
            buildings = [buildings; [repmat(way.id(i), num_nd, 1), ...
                nd_coor(2,:)', nd_coor(1,:)']];
        elseif flag == 4
            buildings = [buildings; [repmat(way.id(i), num_nd, 1), ...
                nd_coor(2,:)', nd_coor(1,:)']];
        elseif flag == 5
            foliage = [foliage; [repmat(way.id(i), num_nd, 1), ...
                nd_coor(2,:)', nd_coor(1,:)']];
        else
        end
    end
end
disp(key_catalog.')

function [] = disp_info(bounds, Nnode, Nway)
disp( ['Bounds: xmin = ' num2str(bounds(1,1)),...
    ', xmax = ', num2str(bounds(1,2)),...
    ', ymin = ', num2str(bounds(2,1)),...
    ', ymax = ', num2str(bounds(2,2)) ] )
disp( ['Number of nodes: ' num2str(Nnode)] )
disp( ['Number of ways: ' num2str(Nway)] )
