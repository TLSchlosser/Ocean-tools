function pltrelease
% function pltrelease
% Plot an acoustic release
% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
w=H(2,el)*2;  % width (scaled) if cylinder element
d=H(3,el);  % diameter if sphere
zb=0;
for i=nh:-1:(el+1),
   if H(4,i)~=1,
      zb=zb+H(1,i);  % sum mooring height
   else
      zb=zb+H(1,i)/chainf;
   end
end
zt=zb+H(1,el);  % z at the top of this element

% releases are always plotted as cylinders
x=[-w/2 -w/2 w/2 w/2 -w/2];
z=[zb zt zt zb zb];
fill(x,z,'b');
% fini
