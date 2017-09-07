function[dist,P] = getLinePointDist(x1,y1,x2,y2,x0,y0)
% GETLINEPOINTDIST Find the distance between a line segment (not a line)
% defined by points (x1,y1) and (x2,y2) and a point (x0,y0). Based on:
% http://www.mathworks.com/matlabcentral/newsreader/view_thread/164048).
% Output:
%   dist:           distance between the segment and the point
%   P:              projection of (x0,y0) on the line defined by (x1,y1)
%                   and (x2,y2) (i.e., not on a line segment)
%
% Copyright (c) 2014-2015, Mate Boban

Vx = ((x2-x1).*(y0-y1)-(y2-y1).*(x0-x1))./((x2-x1).^2+(y2-y1).^2).*(y2-y1);
Vy = ((x2-x1).*(y0-y1)-(y2-y1).*(x0-x1))./((x2-x1).^2+(y2-y1).^2).*-(x2-x1);
P = [x0,y0]+[Vx,Vy]; 
dist = sqrt(Vx.^2+Vy.^2);
