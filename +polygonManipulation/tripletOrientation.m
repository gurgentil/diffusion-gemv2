function[z] = tripletOrientation(x1,y1,x2,y2,x3,y3)
% TRIPLETORIENTATION Returns the orientation of point p3 [x3,y3] with
% respect to the line segment formed by point p1 [x1,y1] and p2 [x2,y2].
% the sign of z determines the orientation. Based on
% http://www.mochima.com/articles/cuj_geometry_article/cuj_geometry_article.html
% Quote from the website: "The magnitude of z is twice the area of the
% triangle p1,p2,p3. The sign of z tells whether the triplet p1,p2,p3
% represents a right-turn or left-turn (that is, if the point p3 is at the
% right or at the left of the oriented segment from p1 to p2)."
%
% Copyright (c) 2014-2015, Mate Boban

% "Given three points p1,p2,p3 in the x-y plane, the z-coordinate of the
% vector product between p2-p1 (p2 minus p1) and p3-p2 is given by the
% following formula:"
z = x1.*(y2 - y3) + x2.*(y3 - y1) + x3.*(y1 - y2);