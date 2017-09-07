function[buildings,buildingsLatLon,bBoxesBuildings,objectCellsBuildings,...
    BigBoxesBuildings,foliage,foliageLatLon,bBoxesFoliage,...
    objectCellsFoliage,BigBoxesFoliage] = loadBuildingsFoliage...
    (staticFile,foliageFile,toleranceBuildings,verbose)
% LOADBUILDINGSFOLIAGE  Loads buildings and foliage outlines. 
%   Performs building outline simplification if toleranceBuildings>0.
%   Saves preprocessed outlines (so that the outline processing can
%   be done only once).
%
% Input: see simMain.m
%
% Output:
%   buildings:                  building outlines in UTM in a three-column
%                               format: [ID,X,Y]  
%   buildingsLatLon:            building outlines in lat/lon in a
%                               three-column format: [ID,Lat,Lon]  
%   bBoxesBuildings:            building bounding boxes 
%   boxesobjectCellsBuildings:  cell containing each building separately
%   BigBoxesBuildings:          building R-tree
%   foliage:                    foliage outlines in UTM in a three-column
%                               format: [ID,X,Y]  
%   foliageLatLon:              foliage outlines in lat/lon in a
%                               three-column format: [ID,Lat,Lon]
%   bBoxesFoliage:              foliage bounding boxes
%   objectCellsFoliage:         cell containing each foliage separately
%   BigBoxesFoliage:            foliage R-tree
%
% Copyright (c) 2014-2015, Mate Boban

if ischar(staticFile)
    [pathstrStatic,nameStatic,~] = fileparts(staticFile);
    if ~isempty(pathstrStatic)
        insert = '/';
    else
        insert = '';
    end
end

% If this static file has been previously processed (i.e., .mat file with
% the same name exists), ask if it should be used instead of processing the
% static data again. 
reply = 'N';
if length(dir([pathstrStatic,insert,nameStatic,'_preprocessed.mat'])) == 1
    reply = input('Do you want to use the previously processed static data? Y/N [Y]: ', 's');
    if isempty(reply)
        reply = 'Y';
    end
end

if isequal(reply,'Y') || isequal(reply,'y')
    %% Load the stored preprocessed data. 
    load([pathstrStatic,insert,nameStatic,'_preprocessed.mat']);
else
    %% Process the data. 
    disp('Processing static data ...');
    OSMFile = 0;
    [~,~,extStatic] = fileparts(staticFile);
    if strcmpi(extStatic,'.osm')
        % If OSM file is provided, simulation assumes that the outlines
        % have been taken from OpenStreetMap
        OSMFile = 1;
    end
    if OSMFile
        % This is data from OSM file
        [buildings,foliage] = polygonManipulation.extractStatic(staticFile);
    elseif ischar(staticFile)
        buildings = load(staticFile);
        foliage = load(foliageFile);
    elseif ~isempty(staticFile)
        % This is pre-loaded data
        buildings = staticFile;
        foliage = [];
    elseif isempty(staticFile)
        buildings = [];
        foliage = [];
    else
        error('Unknown type of static data input');
    end
        
    if ~isempty(buildings)
        % Simulation needs the Lat/Lon coordinates for Google Earth Visualization
        buildingsLatLon = buildings;
        tic
        [xxB,yyB,~] = externalCode.deg2utm.deg2utm(buildings(:,2),buildings(:,3));
        if verbose
            fprintf('Converting from Lat/Lon to UTM takes %f seconds.\n',toc);
        end
        buildings(:,2) = yyB;
        buildings(:,3) = xxB;        
        % If poly2cw exists, merge adjacent buildings
        if exist('poly2cw')==5 
            buildings = polygonManipulation.mergeBuildings(buildings,verbose);
        end
        % Remove inner building polygons and simplify buildings
        buildings = polygonManipulation.simplifyBuildingsFoliage...
            (buildings,verbose,toleranceBuildings);
        % Build the building R-tree
        [bBoxesBuildings,objectCellsBuildings,BigBoxesBuildings,~] =...
            RTree.prepareData(buildings,verbose);
    else
        BigBoxesBuildings = [];
        objectCellsBuildings = [];
        bBoxesBuildings = [];
        buildingsLatLon = [];
    end
    
    if ~isempty(foliage)
        % Simulation needs the Lat/Long coordinates for Google Earth Visualization
        foliageLatLon = foliage;
        tic
        [xxF,yyF,~] = externalCode.deg2utm.deg2utm(foliage(:,2),foliage(:,3));
        fprintf('Converting from Lat/Lon to UTM takes %f seconds.\n',toc);        
        foliage(:,2) = yyF;
        foliage(:,3) = xxF;
        % Build the foliage R-tree        
        [bBoxesFoliage,objectCellsFoliage,BigBoxesFoliage] =...
            RTree.prepareData(foliage,verbose);
    else
        BigBoxesFoliage = [];
        bBoxesFoliage = [];
        objectCellsFoliage = [];
        foliageLatLon = [];
    end        
    reply = input('Do you want to save the processed static data? Y/N [Y]: ', 's');
    if isempty(reply)
        reply = 'Y';
    end
    if reply == 'Y' || reply == 'y'
        % Save the static data.
        if ~isempty(pathstrStatic)
            insert = '/';
        else
            insert = '';
        end
        if isempty(foliage)
            BigBoxesFoliage=[];
        end
        save([pathstrStatic,insert,nameStatic,'_preprocessed.mat'],...
            'buildings','foliage','bBoxesBuildings','objectCellsBuildings',...
            'BigBoxesBuildings','foliage','BigBoxesFoliage','bBoxesFoliage',...
            'objectCellsFoliage','buildingsLatLon','foliageLatLon');
    end
end