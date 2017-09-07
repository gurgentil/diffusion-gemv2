function[theta] = getAngles(lineSegments)
% GETANGLES Function for calculating angles between line segments defined
% by four coordinates (placed in four columns [xx1,yy1,xx2,yy2]). At least
% two rows need to exist (i.e., two lines for one angle). Outputs angle in
% radians
%
% Input:
%   lineSegments:           array of line segments; each row defines a
%                           line segment with two endpoints
%                           [xx1,yy1,xx2,yy2]
%
% Output:
%   theta:                  angle in radians between line segments
%
% Copyright (c) 2014-2015, Mate Boban

if size(lineSegments,1)>=2
    xx1 = lineSegments(:,1);
    yy1 = lineSegments(:,2);
    xx2 = lineSegments(:,3);
    yy2 = lineSegments(:,4);
    
    x1 = xx1(1:end-1)-xx2(1:end-1);
    y1 = yy1(1:end-1)-yy2(1:end-1);
    x2 = xx1(2:end)-xx2(2:end);
    y2 = yy1(2:end)-yy2(2:end);
    
    theta = atan2(x1.*y2-y1.*x2,x1.*x2+y1.*y2);
else
    error('Insufficient number of line segments');
end