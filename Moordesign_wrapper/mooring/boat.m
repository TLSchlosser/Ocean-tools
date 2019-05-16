function boat
% script to draw boat and wire out of water
global VWa HWa ba ha wpm afh Usp Vsp xair yair lgth
global theta 
%
bs=afh/3; % scale the size of boat for the height of the A-frame 
angle=atan2(Vsp,Usp)*180/pi; % orientation of boat is ship speed direction
if Usp==0 & Vsp==0, angle=ha; end
% draw boat
boatx=bs*([0 0.5 2 13 15 0]+3);
boatz=bs*[1 0 -0.7 -0.7 1 1];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.85 0.2 0.2]); % the hull
boatx=bs*([15 18 21 23 16 15]+3);
boatz=bs*[-0.7 -0.7 0 1.6 1 -0.7];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.85 0.2 0.2]); % the hull
boatx=bs*([16 14 13 15 16]+3);
boatz=bs*[1 1 -0.7 -0.7 1];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[1 1 1]); % the CCG White Stripe
boatx=bs*([7 16 14 7 6]+3);
boatz=bs*[1 1 2 2 1];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.7 0.7 0.4]); % the lower super
boatx=bs*([10 14 13.5 14 10 10]+3);
boatz=bs*[2 2 3 3.5 3 2];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.8 0.8 0.6]);% the upper super
boatx=bs*([10.6 11.5 11.5 10.6 10.6]+3);
boatz=bs*[2.2 2.2 2.8 2.8 2.2];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.2 0.2 0.2]); % window1
boatx=bs*([10.6 11.95 11.65 10.6 10.6]+3+1.5);
boatz=bs*[2.2 2.2 2.8 2.8 2.2];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[0.2 0.2 0.2]); % window 2
boatx=bs*([0 -3 -2.6 1 0]+3);
boatz=bs*[1 3 3.3 1 1];
boaty=zeros(size(boatx));
[boatx,boaty]=vrotate(boatx,boaty,angle);
fill3(boatx,boaty,boatz,[1 1 0]); % the A-frame
%
h=plot3(0.3*bs,0,afh,'ob','MarkerFaceColor','r','MarkerSize',3);
%
psi(1)=pi-ba; % vertical angle of wire at surface 
T(1)=sqrt(VWa^2+HWa^2);
angle=-(pi-theta(end-1)); % the angle of the wire, is the angle it leaves the surface of the water
icnt=1;
x(1)=0;z(1)=0.0;
x(icnt+1)=sin(psi(icnt));
z(icnt+1)=cos(psi(icnt));
hght=z(icnt+1);
lg=0.20;
while hght < afh, % find the length of cable to reach a block at afh m height
   icnt=icnt+1; % count number of lgth segments of cable
   Tv=cos(psi(icnt-1))*T(icnt-1) + wpm*lg;
   T(icnt)=sqrt(Tv^2 + HWa^2); % note that no drag on wire in air means no change to Hor tension
   psi(icnt)=atan(HWa/Tv);
   x(icnt+1)=x(icnt)+sin(psi(icnt))*lg;
   z(icnt+1)=z(icnt)+cos(psi(icnt))*lg;
   hght=z(icnt+1);
end
lgth=icnt*lg;
xa=x-x(end);
za=z;
ya=zeros(size(x));
[xa,ya]=vrotate(xa,ya,angle*180/pi); % rotate air-wire to align with direction or horizontal wire angle
plot3(xa,ya,za,'k'); % draw the wire
xair=xa(1); % figure out displacement of wire in air for plotting
yair=ya(1);
% fini