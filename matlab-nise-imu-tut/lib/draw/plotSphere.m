% Use surf() to plot a hemisphere
%
%   [h] = plotSphere(varargin)
%
function [h] = plotSphere(rho,varargin)

% get sphere with 40 faces
[x,y,z] = sphere(40);          

% get the northern hemisphere
% x = x(21:end,:);           
% y = y(21:end,:);           
% z = z(21:end,:);

% Adjust radius
x = x.*rho;
y = y.*rho;
z = z.*rho;
h = surf(x,y,z);      

% blue, transparent
h.FaceColor = 'b';
h.FaceAlpha = 0.1;
% h.FaceLighting = 'gouraud';
h.EdgeColor = 'none';

end