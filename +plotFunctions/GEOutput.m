function[] = GEOutput(plotPoly,plotRxPwr,plotNeighbors,...
    vehicleMidpointsLatLon,vehiclesLatLon,vehiclesHeight,...
    RSUMidpointsLatLon,RSUHeight,numRowsPerVehicle,buildingsLatLon,...
    foliageLatLon,verbose,timeNow,numNeighborsPerVehPerIntervalCell,...
    numCommPairsPerInterval,randCommPairsCell,effectivePairRange,...
    largeScalePwrCell,smScaleVarCell,V2XNames,numSeconds,...
    numVehiclesPerTimestep,randCommPairsLatLon)
% GEOUTPUT Generates Google Earth visualization of objects and received
% power.
%
% Input:   
%   see runSimulation.m, simMain.m, simSettings.m
%
% Output: 
%   KML files containing objects and received power plots
%
% Copyright (c) 2014-2015, Mate Boban

disp('Generating Google Earth visualization ...');

% Set object colors
vehicleColor = [1 0 0];
buildingColor = [1 1 1];
foliageColor = [0 1 0];

%timeNow = now;

%% Plot the buildings, foliage and vehicle outlines
if plotPoly
	disp('Plotting buildings, foliage, and vehicle outlines ...');
    objectCellsVehiclesLatLon=cell(0);    
    timeShifts = zeros(sum(numVehiclesPerTimestep),1);
    timeShiftsCurrStart=1;
    for ii=1:numSeconds-1
        timeShiftsCurrEnd = timeShiftsCurrStart+numVehiclesPerTimestep(ii)-1;
        % NB: for plotting purpose, assumption is that the time interval is
        % 1 second. 
        timeShifts(timeShiftsCurrStart:timeShiftsCurrEnd) = ii/24/60/60;   
        [~,currObjectCellsVehiclesLatLon,~,~] = RTree.prepareData...
            (vehiclesLatLon((timeShiftsCurrStart-1)*numRowsPerVehicle+...
            1:timeShiftsCurrEnd*numRowsPerVehicle,:),verbose);
        objectCellsVehiclesLatLon = ...
            [objectCellsVehiclesLatLon;currObjectCellsVehiclesLatLon];
        timeShiftsCurrStart = timeShiftsCurrEnd+1;        
    end
    vehiclesKML = plotFunctions.plotPolygons(objectCellsVehiclesLatLon,...
        vehiclesHeight,vehicleColor,timeShifts+timeNow);    
    if ~isempty(buildingsLatLon)
        [~,buildingsLatLonCell,~,~] = RTree.prepareData(buildingsLatLon,verbose);
        buildingsKML = plotFunctions.plotPolygons(buildingsLatLonCell,30,buildingColor);
    else
        buildingsKML    = [];
    end    
    if ~isempty(foliageLatLon)
        [~, objectCellsFoliageLatLon, ~, ~] = RTree.prepareData(foliageLatLon,verbose);
        foliageKML      = plotFunctions.plotPolygons(objectCellsFoliageLatLon,10,foliageColor);
    else
        foliageKML      = [];
    end
    % Plot RSUs as white cylinders of height RSUHeight
    RSUoutputBars=[];
    if ~isempty(RSUMidpointsLatLon)
        color=[1 1 1];
        for i = 1:size(RSUMidpointsLatLon,1)
            RSUoutputBars = ...
                [RSUoutputBars,...
                externalCode.googleearth.ge_cylinder(RSUMidpointsLatLon(i,2),...
                RSUMidpointsLatLon(i,1),1,RSUHeight(i),...
                'divisions',5,...
                'lineWidth',5.0,...
                'lineColor', ['ff',plotFunctions.rgbCol2hexCol(color)],...
                'polyColor', ['ff',plotFunctions.rgbCol2hexCol(color)])];
        end
    end
    % Output all objects to KML file; use the current date as file name
    % (NB: overwrites over any files generated before on the dame day!)
    kmlFileName = [date,'_Polygons.kml'];
    kmlTargetDir = ['outputKML/'];
    externalCode.googleearth.ge_output([kmlTargetDir,kmlFileName],...
        [vehiclesKML,buildingsKML,foliageKML,RSUoutputBars],'name',kmlFileName);
end

%% Plot the received power
if plotRxPwr
	disp('Plotting received power lines ...');
    rxPwrCircles=[];
    rxPwrLines=[];    
    if iscell(largeScalePwrCell)
        maxRecPwr = cell2mat(largeScalePwrCell)+cell2mat(smScaleVarCell);
    else
        maxRecPwr = largeScalePwrCell+smScaleVarCell;
    end
    maxRecPwr = maxRecPwr(maxRecPwr<Inf);
    maxRecPwr = max(ceil(maxRecPwr));
    fprintf(['Maximum received power in dBm in the system is %i. The color\n',...
        'of the received power lines is relative to this value.\n'],maxRecPwr);
    % Convert rec. power to RSSI-like value
    maxRecPwr = maxRecPwr+95;
    % Plot rec. power circles and lines; if more than one timestep, then
    % make an animation
    timeShifts = zeros(sum(numCommPairsPerInterval),1);
    timeShiftsCurrStart=1;
    vehicleShiftsCurrStart=1;
    for ii=1:numSeconds
        vehicleShiftsCurrEnd = vehicleShiftsCurrStart+numVehiclesPerTimestep(ii)-1;
        currVehicleMidpointsLatLon = vehicleMidpointsLatLon...
            (vehicleShiftsCurrStart:vehicleShiftsCurrEnd,:);
        if numCommPairsPerInterval(ii)>0
            timeShiftsCurrEnd = timeShiftsCurrStart+numCommPairsPerInterval(ii)-1;
            % NB: for plotting purpose, assumption is that the time
            % interval is 1 second
            timeShifts(timeShiftsCurrStart:timeShiftsCurrEnd) = ii/24/60/60;
            
            % If V2V, use vehicles on both sides of link; if V2I, use RSUs
            % on one side.
            if strcmpi(V2XNames,'v2v')
                currObjMidpointsLatLon = currVehicleMidpointsLatLon;
            else
                currObjMidpointsLatLon = RSUMidpointsLatLon;
            end
            currRandCommPairs = randCommPairsCell{ii,1};
            if ~isempty(currRandCommPairs)
                [currRxPwrCircles,currRxPwrLines] = plotFunctions.plotRecPwr...
                    ([currObjMidpointsLatLon(currRandCommPairs(:,1),2) ...
                    currVehicleMidpointsLatLon(currRandCommPairs(:,2),2)],...
                    [currObjMidpointsLatLon(currRandCommPairs(:,1),1)...
                    currVehicleMidpointsLatLon(currRandCommPairs(:,2),1)],...
                    largeScalePwrCell{ii,1}+smScaleVarCell{ii,1}+95,1,...
                    maxRecPwr,timeShifts...
                    (timeShiftsCurrStart:timeShiftsCurrEnd)+timeNow);
                rxPwrCircles = [rxPwrCircles,currRxPwrCircles];
                rxPwrLines = [rxPwrLines,currRxPwrLines];
                timeShiftsCurrStart = timeShiftsCurrEnd+1;
                % NB: V2I received power is plotted by default. For I2V
                % received power use largeScalePwrI2V instead of
                % largeScalePwr (see end of simOneTimestep for details)
            end
        end
        vehicleShiftsCurrStart = vehicleShiftsCurrEnd+1;
    end
    % Output all lines to KML file; use the current date as file name
    % (NB: overwrites over any files generated before on the dame day!)    
    kmlFileName = [date,'_',V2XNames,'_RxPwr.kml'];
    kmlTargetDir = ['outputKML/'];
    externalCode.googleearth.ge_output([kmlTargetDir,kmlFileName],...
        [rxPwrCircles,rxPwrLines],'name',kmlFileName);
end

%% Plot the number of neighbors
% NB: analyzing neighborhood only makes sense if all (or "large enough")
% number of communicating pairs is analyzed. 
if plotNeighbors
    disp('Generating bars representing number of neighbors ...');
    vehicleIDs = cell2mat(numNeighborsPerVehPerIntervalCell(:,1));
    numNeighbors = cell2mat(numNeighborsPerVehPerIntervalCell(:,2));
    % Plot the CDF of number of neighbors.
    figure; hold on;
    plot(sort(numNeighbors),(1:length(numNeighbors))./length(numNeighbors),'k');
    grid on
    xlabel('Number of Neighbors', 'FontSize', 20);
    ylabel('CDF', 'FontSize', 20);
    set(gca, 'FontSize',20)
    
    maxNumNeighbors = max(numNeighbors);
    
    vehicleShiftsCurrStart=1;
    numNeighborCylinders=zeros(0);
    for ii=1:numSeconds-1
        currObjID = cell2mat(numNeighborsPerVehPerIntervalCell(ii,1));
        currNumNeighbors = cell2mat(numNeighborsPerVehPerIntervalCell(ii,2));        
        vehicleShiftsCurrEnd = vehicleShiftsCurrStart+numVehiclesPerTimestep(ii)-1;        
        currVehicleMidpointsLatLon = vehicleMidpointsLatLon...
            (vehicleShiftsCurrStart:vehicleShiftsCurrEnd,:);
        if strcmpi(V2XNames,'v2v')
            currObjMidpointsLatLon = currVehicleMidpointsLatLon;
        else
            currObjMidpointsLatLon = RSUMidpointsLatLon;
        end
        if ~isempty(currObjID)
        currTimeShifts = ones(size(currObjID))*ii/24/60/60;
        numNeighborCylinders = [numNeighborCylinders, ...
            plotFunctions.plotNumNeighbors(currObjMidpointsLatLon...
            (currObjID,2),currObjMidpointsLatLon(currObjID,1),...
            currNumNeighbors,1,currTimeShifts+timeNow, maxNumNeighbors)];
        end        
        vehicleShiftsCurrStart = vehicleShiftsCurrEnd+1;
    end
    % Output all lines to KML file; use the current date as file name
    % (NB: overwrites over any files generated before on the dame day!)
    kmlFileName = [date,'_',V2XNames,'_NumNeighbors.kml'];
    kmlTargetDir = ['outputKML/'];
    externalCode.googleearth.ge_output([kmlTargetDir,kmlFileName],...
        [numNeighborCylinders],'name',kmlFileName);
end