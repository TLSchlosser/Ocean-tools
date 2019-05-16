function pltco
% function pltcp
% Plot a clamp-on device
% To be used with Mooring Design and Dynamics
% RKD 3/00

global H HCO elco chainf Jobj Pobj hghtt

figure(5)
[mh,nh]=size(HCO);
h=HCO(1,elco);	 % height of device
w=HCO(2,elco);  % width (scaled) if cylinder element
d=HCO(3,elco);  % diameter if sphere
zb=0;
realhgt=sum(H(1,:));
[m,n]=size(H);
for i=n:-1:(Jobj(elco)+1), % sum heights of all objects below the attached component
   if H(4,i)~=1,
      zb=zb+H(1,i);  % sum mooring height
   else
      zb=zb+H(1,i)/chainf;
   end
end
if H(4,Jobj(elco))~=1, % then it's attached to a component
   zb=zb + Pobj(elco)*H(1,Jobj(elco)) - HCO(1,elco)/2; % z to bottom of device
else % it attached to a piece of rope/wire/chain
   zb=zb + Pobj(elco)*(H(1,Jobj(elco))/chainf) - (HCO(1,elco)/2); % z to bottom of device
end
zb=hghtt-HCO(1,elco)/2; % z to bottom of device
zt=zb+HCO(1,elco);  % z to the top of device
iside=mod(elco,2);
isign=1;
if iside==0, isign=-1; end
if d==0, % then this is a cylinder
   dx=w/3;dz=w/2;
	x=[-dx -dx dx dx -dx];
	z=(zb+zt)/2+[-dz dz dz -dz -dz];
   fill(x,z,'y');
	x=isign*(dx+w/2)+[-w/2 -w/2 w/2 w/2 -w/2];
	z=[zb zt zt zb zb];
   fill(x,z,'b');
else %then it's a sphere
   wx=d/3;
   wz=d/3;
   dx=wx/4;dz=wz/3;
	x=[-dx -dx dx dx -dx];
	z=(zb+zt)/2+[-dz dz dz -dz -dz];
   fill(x,z,'y');
   z0=[-wz:0.01:wz];
	x0=wx*sqrt(1-(z0.^2/(wz^2)));
	z=[z0 -z0];
	x=isign*(dx+wx)+[x0 -x0];
	plot([0 0],[zb zt],'k','LineWidth',2);
   fill(x,z+zb+h/2,'b');
end

% fini
