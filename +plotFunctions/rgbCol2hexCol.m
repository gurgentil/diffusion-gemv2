function[hexCol] = rgbCol2hexCol(rgbCol)
% RGBCOL2HEXCOL Converts rgbCol, rgb color input in [0-1] range to hex
% color. Processes one input per run. 
%
% Copyright (c) 2014-2015, Mate Boban

hexCol = dec2hex(round(255*rgbCol));
hexCol = reshape(hexCol',1,6);

