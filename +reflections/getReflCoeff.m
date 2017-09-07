function[reflCoeff] = getReflCoeff(incidentAnglesReflRays,reflRayPermittivity,polarization)
% GETREFLCOEFF Calculates reflection coefficient for reflection off
% buildings/vehicles 
%
% Input:
%   incidentAnglesReflRays: incident angles of reflected rays
%   reflRayPermittivity:    relative permittivity of the material that the
%                           reflected ray is interacting with
%   polarization:           antenna polarization: 0-vertical; 1-horizontal
%
% Output:
%   reflCoeff:              reflection coefficients
%
% Copyright (c) 2014-2015, Mate Boban

% For details on calculating reflection coefficient, see Chapter 3 in
% T. S. Rappaport, "Wireless Communications: Principles and Practice."
% Prentice Hall, 1996.

% If antenna is vertical, the E-field is perpendicular to the plane of
% incidence (and vice-versa)
if polarization == 0    
    reflCoeff = (sin(incidentAnglesReflRays) - ...
        sqrt(reflRayPermittivity-cos(incidentAnglesReflRays).^2))./...
        (sin(incidentAnglesReflRays) + ...
        sqrt(reflRayPermittivity-cos(incidentAnglesReflRays).^2));
elseif polarization == 1
    reflCoeff = (-reflRayPermittivity.*sin(incidentAnglesReflRays) + ...
        sqrt(reflRayPermittivity-cos(incidentAnglesReflRays).^2))./...
        (reflRayPermittivity.*sin(incidentAnglesReflRays) + ...
        sqrt(reflRayPermittivity-cos(incidentAnglesReflRays).^2));
else
    error('Unknown antenna polarization');
end