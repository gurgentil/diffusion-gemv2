function[intersect] = segmentIntersect(x1,y1,x2,y2,x3,y3,x4,y4)
% SEGMENTINTERSECT Checks whether the line segment formed by point1 [x1,y1]
% and point2 [x2,y2] is intersecting with line segment(s) defined by an Nx4
% matrix of the form [x3,y3,x4,y4]. Each row of the matrix represents one
% segment.
%
% Output
%   intersect:      column vector indicating which segment from matrix
%                   intersects the segment between point1 and point2
%
% Copyright (c) 2014-2015, Mate Boban

% Given two segments (p1,p2) and (q1,q2), they intersect if and only if the
% orientation of the triplet (p1,p2,q1) is different from the orientation
% of the triplet (p1,p2,q2) and the orientation of the triplet (q1,q2,p1)
% is different from the orientation of the triplet (q1,q2,p2). The first
% condition means that q1 is on one side of the segment (p1,p2), and q2 is
% on the other side. The second condition means that p1 is on one side of
% the segment (q1,q2), and p2 is on the other side. Clearly, the segments
% intersect if and only if both conditions are met.

intersect = ((x1.*(y2 - y3) + x2.*(y3 - y1) + x3.*(y1 - y2)).*...
             (x1.*(y2 - y4) + x2.*(y4 - y1) + x4.*(y1 - y2))<=0) &...
            ((x3.*(y4 - y1) + x4.*(y1 - y3) + x1.*(y3 - y4)).*...
             (x3.*(y4 - y2) + x4.*(y2 - y3) + x2.*(y3 - y4))<=0);