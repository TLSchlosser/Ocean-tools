function pltanchor
% function pltanchor
% Plot an anchor% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
w=H(2,el);  % width (scaled) if cylinder element
d=H(3,el);  % diameter if sphere
zt=sum(H(1,el:nh));  % z at the top of this element
zb=zt-h; % z at the bottom

% anchors are always plotted as cylinders
x=[-w/2 -w/2 w/2 w/2 -w/2];
z=[zb zt zt zb zb];
fill(x,z,'r');
% fini
