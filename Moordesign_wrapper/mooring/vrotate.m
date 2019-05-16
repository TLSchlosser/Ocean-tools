function [u2, v2] = vrotate(u1,v1,theta)
%    Function to perform 2-D vector rotation
%    Usage: [u2 v2] = vrotate(u1,v1,theta)
%    Where: u1, v1 = input vector coordinates
%           theta = rotation angle in degrees (- is clockwise)
%    RKD 4/97
if size(u1) ~= size(v1), disp(['Vectors must be the same size.']); return; end
% Use complex notation
z1=u1 + sqrt(-1)*v1;
%
z=z1.*exp(sqrt(-1)*theta*pi/180);  % Rotate
%
u2=real(z);  % separate real and imaginary parts
v2=imag(z);
% fini
