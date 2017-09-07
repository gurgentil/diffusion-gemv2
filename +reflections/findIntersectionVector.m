function [intersectionP] = findIntersectionVector(point1,point2,point3,point4)
% FINDINTERSECTIONVECTOR Computes the intersetion of lines in a plane. Line
% 1 is defined by points point1-point2; Line 2 is defined by points
% point3-point4. Each row in pointX defines a point. 
%
% Output:
%   intersectionP:           intersecting points
%
% Copyright (c) 2014-2015, Mate Boban

x1=point1(:,1);
x2=point2(:,1);
x3=point3(:,1);
x4=point4(:,1);
y1=point1(:,2);
y2=point2(:,2);
y3=point3(:,2);
y4=point4(:,2);

ua = ((x4-x3).*(y1-y3)-(y4-y3).*(x1-x3))./((y4-y3).*(x2-x1)-(x4-x3).*(y2-y1));
x = x1 + ua.*(x2 - x1);
y = y1 + ua.*(y2 - y1);
intersectionP = [x,y];