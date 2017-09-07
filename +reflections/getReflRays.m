function[currReflRays] = getReflRays(commPair,segments,commPairID,...
    vehicleReflection,vehicleMidpoints,objectCellsVehicles)
% GETREFLRAYS Finds potential reflections off buildings and vehicles.
% Does not check whether the reflecting rays are obstructed.
%
% Input:
%   see reflect.m and getReflections.m
%
% Output:
%   currReflRays:      potential reflections for current communication pair
%
% Copyright (c) 2014-2015, Mate Boban

%% Get transmitter and receiver from current comm. pair
Tx = vehicleMidpoints(commPair(1),:);
Rx = vehicleMidpoints(commPair(2),:);

%% Put the input in more compact variable names
x1 = segments(:,2);
y1 = segments(:,3);
x2 = segments(:,5);
y2 = segments(:,6);
x3 = Rx(1);
y3 = Rx(2);
x4 = Tx(1);
y4 = Tx(2);

%% Code below based on the ideas from:
% http://www.mochima.com/articles/cuj_geometry_article/cuj_geometry_article.html
% Given two segments (p1,P) and (q1,q2), they intersect if and only if the
% orientation of the triplet (p1,P,q1) is different from the orientation
% of the triplet (p1,P,q2) and the orientation of the triplet (q1,q2,p1)
% is different from the orientation of the triplet (q1,q2,P).

%% Find points P which are mirrored images of Rx (x3,y3) with respect to segment
% Find point V which, when added to Rx, translates Rx to segment(s)
V = zeros(size(x1,1),2);
V(:,1) = ((x2-x1).*(y3-y1)-(y2-y1).*(x3-x1))./((x2-x1).^2+(y2-y1).^2).*(y2-y1);
V(:,2) = ((x2-x1).*(y3-y1)-(y2-y1).*(x3-x1))./((x2-x1).^2+(y2-y1).^2).*-(x2-x1);
% P is a mirrored image of Rx with respect to segment(s)
P = zeros(size(V,1),2);
P(:,1) = x3 + 2.*V(:,1);
P(:,2) = y3 + 2.*V(:,2);

%% Get potentially reflecting segments
% Potentially reflecting segments are those that would geometrically 
% generate a reflection, were there no obstructions.
% Check whether segment Tx-P intersects with current segment. If it does,
% current segment(s) could create reflection between Tx and Rx
possiblyReflSegments = polygonManipulation.segmentIntersect...
    (x1,y1,x2,y2,x4,y4,P(:,1),P(:,2));
if sum(possiblyReflSegments)>0
    % Get the potentially reflecting segments and mirrored images of Rx
    P = P(possiblyReflSegments,:);
    x1 = x1(possiblyReflSegments);
    x2 = x2(possiblyReflSegments);
    y1 = y1(possiblyReflSegments);
    y2 = y2(possiblyReflSegments);    
    % Get the intersection point between Tx-P and segments [(x1,y1),(x2,y2)]
    PSegment = reflections.findIntersectionVector(Tx,P,[x1, y1], [x2, y2]);
    % If checking reflections off vehicles, make sure that other segments
    % on the vehicle do not block the reflection.
    if vehicleReflection
        % Get possibly reflecting segments
        segmentsPossible = segments(possiblyReflSegments,:);
        PHasLOSTxRx = zeros(size(PSegment,1),1);
        for jj=1:size(PSegment,1)
            % Get the segments of the vehicle on which the current PSegment
            % is located 
            currVeh = objectCellsVehicles{segmentsPossible(jj,1)};            
            % Check if the vehicle itself blocks the reflection (i.e., if
            % Tx-PSegment or PSegment-Rx is blocked by any of the vehicle
            % segments)
            if sum(polygonManipulation.segmentIntersect...
                    (Tx(1),Tx(2),PSegment(jj,1),PSegment(jj,2),...
                    currVeh(1:end-1,2),currVeh(1:end-1,3),...
                    currVeh(2:end,2),currVeh(2:end,3)))==0 && ...
               sum(polygonManipulation.segmentIntersect...
                    (Rx(1),Rx(2),PSegment(jj,1),PSegment(jj,2),...
                    currVeh(1:end-1,2),currVeh(1:end-1,3),...
                    currVeh(2:end,2),currVeh(2:end,3)))==0
               PHasLOSTxRx(jj)=1;
            end            
        end        
        PSegment = PSegment(logical(PHasLOSTxRx),:);
    end        
    % Reflected rays for each comm. pair have 2 parts: Tx-PSegment and
    % PSegment-Rx. Put them in an array one after the other 
    currReflRays = zeros(size(PSegment,1)*2,5);
    %all rays emmanate from the same comm pair
    currReflRays(:,5) = commPairID;
    % Rays from Tx to PSegment
    currReflRays(1:2:end-1,1) = Tx(1);
    currReflRays(1:2:end-1,2) = Tx(2);
    currReflRays(1:2:end-1,[3,4]) = PSegment;
    % Rays from PSegment to Rx
    currReflRays(2:2:end,1) = Rx(1);
    currReflRays(2:2:end,2) = Rx(2);
    currReflRays(2:2:end,[3,4]) = PSegment;
else
    currReflRays = [];
end
end