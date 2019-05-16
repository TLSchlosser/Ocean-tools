function pltcm
% function pltcm
% Plot a current meter
% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
w=H(2,el);  % width (scaled) if cylinder element
d=H(3,el);  % diameter if sphere
zb=0;
realhgt=sum(H(1,:));
for i=nh:-1:(el+1),
   if H(4,i)~=1,
      zb=zb+H(1,i);  % sum mooring height
   else
      zb=zb+H(1,i)/chainf;
   end
end
zt=zb+H(1,el);  % z at the top of this element

%
if w==0.128, % then this is an Aanderaa cm
   zg=[0 (h/2)-0.02 (h/2)-0.02 0 0 (h/2)+0.1 (h/2)+0.1 (h/2)+.02 ...
         (h/2)+0.02 h h (h/2)+0.02 (h/2)+0.02 (h/2)-0.02 (h/2)-0.02 0 0];
   xg=1.5*[-.01 -.01 -.15 -.15 -(.15+.13) -(.15+.13) -.15 -.15 ...
       -.01 -.01 .01 .01 .15 .15 .01 .01 -.01];
   zr1=(h/2)+[0.1 0.2 0.2 0.1 0.1];
   xr1=1.5*([-.13 -.13 0 0 -.13]-0.15);
   zr2=(h/2)+[0.02 0.15 0.15 -0.15 -0.15 -0.02 0.02];
   xr2=1.5*(0.15+[0 .1 .5 .5 .1 0 0]);
   fill(xg,zg+zb,[0 .8 0]);
   fill(xr1,zr1+zb,'r');
   fill(xr2,zr2+zb,'r');
elseif w==0, % then its an S4
   wx=d/2;
   wz=d/2;
   z=[-wz:0.01:wz];
   x=wx*sqrt(1-(z.^2/wz^2));
   z=[z -z];
   x=[x -x];
   plot([0 0],[zb zt],'k','LineWidth',2);
   fill(x,z+zb+h/2,'y');
elseif d==0, % then its a cylinder/generic type
   x=[-w/2 -w/2 w/2 w/2 -w/2];
   z=[zb zt zt zb zb];
   fill(x,z,'y');
end

% fini
