function pltchain
% function pltchain
% Plot a section of chain
% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
w=H(2,el);  % width (scaled) if cylinder element
zb=0;
for i=nh:-1:(el+1),
   if H(4,i)~=1,
      zb=zb+H(1,i);  % sum mooring height
   else
      zb=zb+H(1,i)/chainf;
   end
end
zt=zb+H(1,el);  % z at the top of this element

% chain is plotted as series of links
if H(4,el)==1,
   wx=w/2;
   wz=w/2;
   h=h/chainf;
else
   wx=h/2;
   wz=h/2;
end
z=[-wz:0.001:wz];
dz=2*wz;
x=wx*sqrt(1-(z.^2/wz^2));
z=[z fliplr(z)];
x=[x -x];
Nlinks=ceil(h/dz);
dz=h/Nlinks;
for i=1:Nlinks,
   zo=zb+dz*(i-1)+dz/2;
   plot(x,z+zo,'k');
end
% fini
