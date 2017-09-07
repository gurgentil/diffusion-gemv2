function[obsObjects] = getObstructingObjects(commPairs,objectCells,...
    vehicleMidpoints,BigBoxes,numRowsPerObject,logicalOrObjects,verbose,...
    vehiclesHeight,antennaHeight,commPairList)
% GETOBSTRUCTINOBJECTS For each communicating pair, finds objects
% obstructing the line of sight (LOS).
%
% Input
%   commPairs:          array containing pairwise IDs of vehicles
%                       participating in communication pairs
%   objectCells:        cell containing each object in a separate cell
%   vehicleMidpoints:   midpoints of vehicles
%   BigBoxes:           rectangles forming the generated R-tree
%   numRowsPerObject:   for vehicles, defines the number of rows/points per
%                       object; for buildings and foliage, it is set to -1,
%                       since they have variable number of points)
%   logicalOrObjects:   determines if obsObjects returns ID of obstructing
%                       objects (when set to 0) or a logical value for
%                       blocked/not blocked LOS (when set to 1)
%
% Output
%   obsObjects:         if logicalOrObjects is set to 0, obsObjects returns
%                       IDs of objects obstructing LOS of the comm. pair;
%                       if logicalOrObjects is set to 1, for each comm.
%                       pair, obsObjects returns 1 in case of blocked LOS
%                       or 0 if not blocked
%
% Copyright (c) 2014-2015, Mate Boban

tic
numberOfArguments = nargin;

%% Create an axis-aligned bounding rectangle formed by each comm. pair
commPairBoxes = zeros(size(commPairs,1), 4);

if size(commPairs,2) == 2
    % These are pointers to the vehicle midpoints
    commPairBoxes(:,[2, 1]) = vehicleMidpoints(commPairs(:,1),:);
    commPairBoxes(:,[4, 3]) = vehicleMidpoints(commPairs(:,2),:);
elseif size(commPairs,2) == 6 || size(commPairs,2) == 5
    % These are coordinates of the reflected/diffracted rays with the
    % format [x1,y1,x2,y2,commPairID,building/vehicle reflection]
    commPairBoxes(:,[2, 1]) = commPairs(:,[1, 2]);
    commPairBoxes(:,[4, 3]) = commPairs(:,[3, 4]);
else
    error('Wrong number of rows in commPairs!');
end

%% Get bounding rectangle for each comm pair [minX,minY,maxX,maxY]
isLessX = commPairBoxes(:,1)<commPairBoxes(:,3);
commPairBoxesTemp = zeros(size(commPairs,1), 4);
commPairBoxesTemp(isLessX,1) = commPairBoxes(isLessX,1);
commPairBoxesTemp(~isLessX,1) = commPairBoxes(~isLessX,3);
commPairBoxesTemp(isLessX,3) = commPairBoxes(isLessX,3);
commPairBoxesTemp(~isLessX,3) = commPairBoxes(~isLessX,1);
isLessY = commPairBoxes(:,2)<commPairBoxes(:,4);
commPairBoxesTemp(isLessY,2) = commPairBoxes(isLessY,2);
commPairBoxesTemp(~isLessY,2) = commPairBoxes(~isLessY,4);
commPairBoxesTemp(isLessY,4) = commPairBoxes(isLessY,4);
commPairBoxesTemp(~isLessY,4) = commPairBoxes(~isLessY,2);
commPairBoxes = commPairBoxesTemp';

%% Initiate arrays for obstructed objects
persistent obstructedObjectList;
obstructedObjectList = cell(size(commPairs,1),1);
persistent obstructedByObjects;
obstructedByObjects = zeros(size(commPairs,1),1);

%% Run the recursive function checking LOS blockage by objects
% Initiate the function with the topmost R-tree rectangle (i.e., the root)
% as the obstructing object and with all comm. pairs to be checked
intersected(BigBoxes(1,:), find(commPairBoxes(1,:)),commPairBoxes);

% Return either a logical array determining if LOS is blocked or a cell
% array with complete list of obstructing object IDs
if logicalOrObjects
    obsObjects = obstructedByObjects;
else
    obsObjects = obstructedObjectList;
end

%% Function that finds (and, optionally, reports) objects obstructing LOS
% Function is nested to improve the performance
    function[] = intersected(bigbox, commPairBoxesIndices, commPairBoxes)
        % Determines if the object defined by bigbox intersects the LOS
        % between supplied comm. pairs; returns the objects inside bigbox,
        % if specified
        %
        % Input
        %   bigbox:                 current R-tree rectangle being checked
        %   commPairBoxesIndices:   indices of current comm. pairs
        %   commPairBoxes           bounding rectangles of current pairs
        
        %% Checking if bounding box of object and comm. pairs overlap
        % For all commPairBoxes, check if the bigbox is completely outside
        % the commPairBoxes (rectangle formed by comm. pair). If yes, there
        % is no chance that the object inside bigbox blocks the LOS for the
        % comm. pair. I.e., check if maxX of bigbox is less than minX of
        % commPairBoxes, if minX of bigbox is larger than maxX of
        % commPairBoxes, etc.
        commPairBoxesDot = bigbox(1,2)<=commPairBoxes(1,:) | ...
            bigbox(1,4)<=commPairBoxes(2,:) | ...
            bigbox(1,1)>=commPairBoxes(3,:) | ...
            bigbox(1,3)>=commPairBoxes(4,:);
        % Get those commPairBoxes that bigbox intersects (i.e., where none
        % of the logical statements above is true)
        currCommPairBoxes = commPairBoxes(:,~commPairBoxesDot);
        % Get the indices of currCommPairBoxes
        currIndices = commPairBoxesIndices(~commPairBoxesDot);
        
        if ~isempty(currCommPairBoxes)
            if bigbox(1,7)~=-1
                %% Current bigbox contains an actual object (i.e. is a leaf)
                % Current bigbox is a leaf, check for intersection between
                % the actual object inside it and currCommPairBoxes
                
                % Get the object that current bigbox belongs to
                objPoints = objectCells{bigbox(1,7)};
                x3 = objPoints(:,2);
                y3 = objPoints(:,3);
                % Get the coordinates of vehicles in comm. pairs
                if size(commPairs,2) == 2
                    % These are "regular" comm. pairs (Tx and Rx vehicle)
                    x1 = vehicleMidpoints(commPairs(currIndices,1),1);
                    y1 = vehicleMidpoints(commPairs(currIndices,1),2);
                    x2 = vehicleMidpoints(commPairs(currIndices,2),1);
                    y2 = vehicleMidpoints(commPairs(currIndices,2),2);
                elseif size(commPairs,2) == 5 || size(commPairs,2) == 6
                    % Comm. pairs are coordinates of vehicle-wallPoint pairs for
                    % reflections/diffractions
                    x1 = commPairs(currIndices,1);
                    y1 = commPairs(currIndices,2);
                    x2 = commPairs(currIndices,3);
                    y2 = commPairs(currIndices,4);
                end
                % Logical array containing the intersection between current
                % object segments and comm. pair LOS segments
                % Array size: number object segments X number comm. pairs
                segmentIntersections = zeros(size(x3,1)-1,size(x1,1));
                for ii=1:size(segmentIntersections,1)
                    % Check segment intersection between each object
                    % segment and all comm. pair LOS lines
                    segmentIntersections(ii,:) = polygonManipulation.segmentIntersect...
                        (x1,y1,x2,y2,x3(ii),y3(ii),x3(ii+1),y3(ii+1));
                end
                % Get indices of all comm. pair LOS segments that are
                % intersected by one or more object segment
                getObsPairsIndices = sum(segmentIntersections)>0;
                obsPairsIndices = currIndices(getObsPairsIndices);
                
                % If the obstructing objects are vehicles, exclude the
                % vehicles themselves from the list of obstructing objects.
                if numRowsPerObject~=-1 && size(commPairs,2)==2
                    obsPairsIndices = obsPairsIndices(commPairs...
                        (obsPairsIndices,1)~=bigbox(1,7)&...
                        commPairs(obsPairsIndices,2)~=bigbox(1,7));
                end
                if numel(obsPairsIndices)>0
                    if logicalOrObjects
                        %% Return logical array
                        % (except in case of reflections/diffractions)
                        if numberOfArguments == 10
                            % Obstructing objects are vehicles. Used for
                            % reflection and diffraction calculations. If
                            % vehicles are the obstructing objects,
                            % vehicleHeights, antennaHeights, and commPairs
                            % (the whole list) will be passed.
                            % Otherwise, it's a list of comm. pair IDs.
                            TxHeights = vehiclesHeight(commPairList...
                                (commPairs(obsPairsIndices,5),1));
                            RxHeights = vehiclesHeight(commPairList...
                                (commPairs(obsPairsIndices,5),2));
                            % Get height of the potentially obstructing vehicle
                            currVehHeight = vehiclesHeight(bigbox(1,7));
                            % Check if the blocking vehicle is tall enough
                            % to obstructing LOS (simplified: checks if
                            % obstructing vehicle is higher than the height
                            % of shorter antenna in the comm. pair).
                            isCurrHigher = currVehHeight>min(TxHeights,...
                                RxHeights)+antennaHeight;
                            obsPairsIndices = obsPairsIndices(isCurrHigher);
                            % Check if only one vehicle is blocking
                            notYetModified = obstructedByObjects...
                                (obsPairsIndices,1)==0;
                            % If only one is blocking, get its ID
                            obstructedByObjects(obsPairsIndices...
                                (notYetModified),1)=bigbox(1,7);
                            % If more are blocking, set the value to Inf
                            obstructedByObjects(obsPairsIndices...
                                (~notYetModified),1) = Inf;
                        else
                            % Simply mark that the LOS for the comm. pairs
                            % is blocked
                            obstructedByObjects(obsPairsIndices,1) = 1;
                        end
                    else
                        %% Get the IDs of obstructing objects
                        for ii=1:numel(obsPairsIndices)
                            obstructedObjectList{obsPairsIndices(ii),1} =...
                                [obstructedObjectList{obsPairsIndices(ii),1},...
                                bigbox(1,7)];
                        end
                    end
                end
            else
                %% bigbox is not a leaf, run the function on its children
                intersected(BigBoxes(bigbox(1,9),:),currIndices,currCommPairBoxes);
                intersected(BigBoxes(bigbox(1,10),:),currIndices,currCommPairBoxes);
            end
        end
    end
if verbose
    fprintf('Getting objects intersecting LOS takes %f seconds.\n', toc);
end
end