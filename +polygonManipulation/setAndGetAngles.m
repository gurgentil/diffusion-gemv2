function angles = setAndGetAngles(P1,P2,pointList)
% SETANDGETANGLES Set up an array and get the angles between points P1, P2,
% and an array of points in pointList. Put the "lines" in the right format
% for the getAngles function.
%
% Structure of array: alpha (angle (Tx,Rx,P)) and beta (angle (Rx,Tx,P))
% alpha: [XRx YRx XTx YTx;
%         XRx YRx XP  YP]
% beta:  [XTx YTx XRx YRx;
%         XTx YTx XP  YP]
%
% Order of the points matter: the angle's vertex will be at the point in
% the first two columns.
%
% Copyright (c) 2014-2015, Mate Boban

segments = ones(size(pointList,1)*2,4)*Inf;
segments(:,1) = P1(1);
segments(:,2) = P1(2);
segments(1:2:end-1,3) = P2(1);
segments(1:2:end-1,4) = P2(2);
segments(2:2:end,[3 4]) = pointList;
% Get the alpha angles
if exist('rad2deg')==5
    angles = rad2deg(polygonManipulation.getAngles(segments));
else
    % No mapping toolbox available...
    angles = polygonManipulation.rad2deg(polygonManipulation.getAngles(segments));
end
% Don't need all angles: get odd ones only
angles = angles(1:2:end);
