function pltfloat
% function pltfloat
% Plot a float
% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el moorele chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
w=H(2,el);  % width (scaled) if cylinder element
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

% floats are plotted as spheres
sing=1;
if h>d & strcmp(moorele(el,1:4),'Trpl'),
   % then this is a vertical string of (3) small balls
   d=sqrt((d^2)/3);
   sing=3;
elseif h<d & strcmp(moorele(el,1:4),'Doub'),
   % then this is a horizontal sting of (2) balls
   d=sqrt((d^2)/2);
   sing=2;
elseif h>d & strcmp(moorele(el,8:11),'Clam'),
   d=h;
   sing=4; % a clam shell with a fin
end
wx=d/2;
wz=d/2;
z0=[-wz:0.01:wz];
x0=wx*sqrt(1-(z0.^2/wz^2));
z=[z0 -z0];
x=[x0 -x0];
plot([0 0],[zb zt],'k','LineWidth',2);
if sing==1,
   fill(x,z+zb+h/2,[1 .5 0]);
elseif sing==2,
   fill(x-d/2,z+zb+h/2,[.8 .8 0]);
   fill(x+d/2,z+zb+h/2,[.8 .8 0]);
elseif sing==3,
   for ii=1:3,
      h2=(h-3*d)/2+d/2+(ii-1)*d;
      fill(x,z+zb+h2,[1 .7 0]);
   end
elseif sing==4,
   fill([x0 h*.7 h*.7 0],[z0 wz -wz -wz]+zb+h/2,[1 .7 .7]);
   fill(x,z+zb+h/2,[1 .5 0]);
end

   

% fini
