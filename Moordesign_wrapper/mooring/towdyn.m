function [X,Y,Z,iobj,psi,Wa]=towdyn(U,z,Ht,Bt,Cdt,MEt,V,W,rho,Usp,Vsp,uw,vw)
% function [X,Y,Z,iobj]=towdyn(U,z,H,B,Cd,ME,V,W,rho,Usp,Vsp)
%
% Calculate the towed body positions relative to surface, 
% X (+East), Y (+North) and Z (+Up) all in metres
%    given a velocity profile U(z) at depths z [m] (+up), with U(0)=0 
% For an oceanographic towed body from bottom to top
%    with N elemental components (including wire sections as elements),
%    dimensions Ht(L W D i,N) [m] of each different mooring component/element, 
%    mass/buoyancies Bt(N) [in kg, or kg/m for wire/chain] (+up),
%    Drag coefficients (Cdt(N)). MEt (modulus of elasticity indecies)
%    where 1=steel,2=Nylon,3=Dacron,4=Polyprop,5=Polyethy,6=Kevlar,7=Aluminum, 8=Dyneema
% Output iobj are the idecices of the mooring "elements" not
%    including wire or chain [Ht(4,:)=1] elements.
%    Note: U (and V, W, and rho if provided) must extend to bottom (z=0).
%          Usp and Vsp are the speed velocities in the east and north dir. respec.
% Optional inputs:
%    velocity components V(z) and W(z), rho(z)=density profile
%
% Ht(1,:) = Length/height of object/element including strength member [m]
%          H(1,N) is the height of the anchor [m]
% Ht(2,:) = Width of cylinder (0=zero if sphere) [m]
% Ht(3,:) = Diameter of sphere (0=zero if cylinder or wire/chain) [m]
% Ht(4,:) = 1 for wire/chain, 2 for fastener, 0 otherwise. Divide wire/chain into 1 m lengths
%
% May be passed with no arguments, assuming: global U z H B Cd V W rho
% RKD 03/00 03/01

if nargin == 0,
   global U V W z rho uw vw Usp Vsp
   global Ht Bt Cdt MEt
end
global VWa HWa ba ha wpm
global Hs Bs Cds MEs iss % saved for multiple float or "S" moorings
global moorelet X Y Z Ti iobj jobj psi theta
global HCO BCO CdCO ZCO Iobj Jobj Pobj % any clamped on devices
global Z0co Zfco Xfco Yfco psifco
global nomovie
global Zoo DD iss ztmp Utmp Vtmp Wtmp rhotmp im1

% global Qx Qy Qz theta Hi Cdi Ui Vi Wi zi U V z psi phix phiy

if isempty(DD), DD=0; end

upfac=1.01;dnfac=0.99;
bw=0;icprt=1;ist=[];im1=[];
%
iprt=0; % set to 1 for a plot and display of convergence used during gde-bugging
%
ss=get(0,'ScreenSize');
X=[];Y=[];Z=[];Ti=[];iobj=[];jobj=[];psi=[];theta=[];Zoo=[]; % initialize arrays to empty
Zi=[];Bi=[];Cdi=[];MEi=[];Hi=[];
%
[mu,nu]=size(U);
if z(1)>z(end), z=z(end:-1:1); end
% Note for a towed body problem, velocities are measured from surface z=0 down
if isempty(U), % if environmental variable haven't been set
   U=[0 0 0]';V=U;W=U;z=fix(sum(Ht(1,:))*[0 0.2 1.2]');rho=[1024 1025 1026]';
end

if isempty(iss),
   Hs=Ht;Bs=Bt;Cds=Cdt;MEs=MEt; % save the original tow body design.
   ztmp=z;Utmp=U;Vtmp=V;Wtmp=W;rhotmp=rho;
   iss=1;
end
% add ship speed to current profile, temp velocities subscript s
Us=U-Usp;  % a ship speed in +x is like a current in -x
Vs=V-Vsp;
Ws=W;
%
[mu,nu]=size(Us);
if mu ~= 1 & nu ~= 1, % then pickoff the first velocity profile.
   if mu==length(z),
      Us=Us(:,1);
      Vs=Vs(:,1);
      Ws=Ws(:,1);
   else
      Us=Us(1,:)';
      Vs=Vs(1,:)';
      Ws=Ws(1,:)';
   end
end
% Add 2% of wind speed to top current value(s)
windepth=sqrt(uw^2+vw^2)/0.02; % wind penetrates about 1m for every 1m/s, otherwise shears too high
if windepth > z(end), windepth==0.8*z(end); end % maximum wind depth is 80% of water depth
if (uw^2+vw^2)>0,
   if (z(2)-z(1)) > windepth,
   mu=length(z);
   z(3:mu+1)=z(2:mu);
   z(2)=windepth;
   Us(3:mu+1)=Us(2:mu);
   Us(2)=interp1([z(1) z(3)],[Us(1) Us(3)],z(2),'linear');
   Us(1)=Us(1)+uw;
   Vs(3:mu+1)=Vs(2:mu);
   Vs(2)=interp1([z(1) z(3)],[Vs(1) Vs(3)],z(2),'linear');
   Vs(1)=Vs(1)+vw;
   Ws(3:mu+1)=Ws(2:mu);
   Ws(2)=interp1([z(1) z(3)],[Ws(1) Ws(3)],z(2),'linear');
   rho(3:mu+1)=rho(2:mu);
   rho(2)=rho(1);
else
   uwindx=find(z < windepth);
   uw1=interp1([z(1) windepth],[uw 0],z(uwindx),'linear');
   vw1=interp1([z(1) windepth],[vw 0],z(uwindx),'linear');
   Us(uwindx)=Us(uwindx)+uw1;
   Vs(uwindx)=Vs(uwindx)+vw1;
end
end
% first change masses/buoyancies into forces (Newtons)
Bw=Bt*9.81; % Turn masses/buoyancies [kg] into forces [N]
Bmax=Bw(1); % maximum buoyancy/weight at end of tow cable
BwCO=BCO*9.81;
Zw=max(z);  % The water depth!
S=sum(Ht(1,:)); % maximum length of the tow cable
%
N=length(Bt); % initial number of elements, before segmenting wire/chain into 1 m lengths
%
disp('Searching for a converged solution.');
%
j=1; % for node setup, segment from top down
Zi(1)=Ht(1,N);  % height of the top element
Hi(:,1)=Ht(:,N); % setup interpolated Ht,Bt,Cdt variables (from top down)
Bi(:,1)=Bw(:,N);
Cdi(1)=Cdt(N);
MEi(1)=MEt(N);
z0=Ht(1,N)/2; % initial depth of top of element (float)
% Note all z's are now depths below surface
for i=N-1:-1:1, % setup initial heights of interpolated elements
   j=j+1;
   if Ht(4,i)==1,  % this section is wire/chain
      n=fix(Ht(1,i));
      if n < 5, % make it at least 5 segments long, no more than 50
         n=5;
      elseif n > 50,
         n=50;
      end 
      dz=Ht(1,i)/n;
      Elindx(i,1)=j;
      for jj=j:j+n-1, 
         Zi(jj)=z0+dz/2;
         z0=z0+dz;
         Hi(:,jj)=[dz Ht(2,i) Ht(3,i) Ht(4,i)]';
         Bi(jj)=Bw(i)*dz; % the stored mass is per unit metre
         Cdi(jj)=Cdt(i);
         MEi(jj)=MEt(i);
      end
      j=j+n-1;
      Elindx(i,2)=j;
   else
      Elindx(i,1:2)=[j j];
      Zi(j)=z0 + Ht(1,i)/2;
      z0=z0+Ht(1,i);
      Hi(:,j)=Ht(:,i);
      Bi(j)=Bw(i);
      Cdi(j)=Cdt(i);
      MEi(j)=MEt(i);
   end
end
Elindx=j+1-Elindx;
%
% find interpolated indecise for any clamp-on devices
if ~isempty(ZCO),
	mmCO=length(BCO);
	mm=length(Bi);
	for ico=1:mmCO,
	   for i=mm-1:-1:2,  % bottom up
	        if ZCO(ico)>sum(Hi(1,mm:-1:i)) & ZCO(ico)<=sum(Hi(1,mm:-1:(i-1))),
	  	         Iobj(ico)=mm-(i-1); % moorele object onto which we've clamped, top down!
	  	         dz=ZCO(ico)-sum(Hi(1,mm:-1:i));
	  	         Piobj(ico)=1 - dz/Hi(1,i-1); % percentage of length down segment i-1 where we've clamped.
	  	         i=2;
	  	      end	
		end	
   end
end

% Sum up vertical depth for hanging tow
[m,N]=size(Hi);
Zoo(N)=0;dz0=0;
for ii=N-1:-1:1,
   Zoo(ii)=Zoo(ii+1) + Hi(1,ii)/2 + dz0;
   dz0=Hi(1,ii)/2;
end
%
% now interpolate the velocity profile to 1 m estimates
dz=1;
dz0=mean(abs(diff(z)));
maxz=sum(Ht(1,:));
if DD>0 & max(z) < maxz,
   indxz=length(z);
   z(indxz+1)=1.2*maxz; % deepen water depth to account for long tow wires
   Us(indxz+1)=Us(indxz);
   Vs(indxz+1)=Vs(indxz);
   Ws(indxz+1)=Ws(indxz);
   rho(indxz+1)=rho(indxz);
end  
if dz0<1,   % if velocity profile is already 1m or less.
   Ui=Us;
   Vi=Vs;
   Wi=Ws;
   rhoi=rho;
   zi=z;
else
   if z(1)>z(2), dz=-1; end
   if abs(z(end)-z(1)) < 10, dz=sign(dz)*0.1; end
	zi=[z(1):dz:z(end)];
   Ui=interp1(z,Us,zi,'linear');
   Vi=interp1(z,Vs,zi,'linear');
   Wi=interp1(z,Ws,zi,'linear');
   rhoi=interp1(z,rho,zi,'linear');
end
%
N=length(Bi); % the new number of "interpolated" mooring elements

% Now find the drag on each element assuming first a vertical tow line.
Umag=sqrt(Ui.^2 + Vi.^2 + Wi.^2);  % the total current speed
for j=1:N,
   ico=[];if ~isempty(Iobj),ico=find(Iobj==j); end % If ~isempty(ico), then there is a clamp on device here
   i=find(zi >= (Zi(j)-0.5) & zi <= (Zi(j)+0.5));
   i=i(1); % just in case it got more than one value/index
   if Hi(3,j)==0, % then this is a cylinder/wire/chain section
      A=Hi(1,j)*Hi(2,j); % exposed area of cylinder/wire/chain
   else
      A=pi*(Hi(3,j)/2)^2; % exposed area of sphere
   end
   Qx(j)=0.5*rhoi(i)*Cdi(j)*A*Umag(i)*Ui(i); % drag in X-direction
   Qy(j)=0.5*rhoi(i)*Cdi(j)*A*Umag(i)*Vi(i); % drag in Y-direction
   % if there are clamp-o devices here
   Qxco=0;Qyco=0;
   if ~isempty(ico),
      for icoc=ico,  % loop through if there is more than one clamp-on device here 
      	if HCO(3,icoc)==0, % then this is a cylinder device
         	Axco=HCO(1,icoc)*HCO(2,icoc); % area of cylinder/wire/chain
		   	Ayco=HCO(1,icoc)*HCO(2,icoc); % area of cylinder/wire/chain
	 	   	Cdjxco=CdCO(icoc);
	  	   	Cdjyco=CdCO(icoc);
	  		else % this is a sphere device
	  		   Axco=pi*(HCO(3,icoc)/2)^2;
	  		   Ayco=Axco;
	  		   Cdjxco=CdCO(icoc);
	  		   Cdjyco=Cdjxco;
      	end
      	Qxco=Qxco + 0.5*rhoi(i)*Cdjxco*Axco*Umag(i)*Ui(i);
      	Qyco=Qyco + 0.5*rhoi(i)*Cdjyco*Ayco*Umag(i)*Vi(i);
      end
   end
   Qx(j)=Qx(j)+Qxco;
   Qy(j)=Qy(j)+Qxco;

   if Hi(3,j)==0, % then this is a cylinder/wire/chain section
      A=pi*(Hi(2,j)/2)^2; % area of bottom of cylinder
      if Hi(4,j)==1, A=0; end % if wire, vertical area =0
   end   
   Qz(j)=0.5*rhoi(i)*Cdi(j)*A*Umag(i)*Wi(i);
   % now for clamp-on
   Qzco=0;
   if ~isempty(ico),
      for icoc=ico,
	   	if HCO(3,icoc)==0, % then this is a cylinder/wire/chain section
	   	   Azco=pi*(HCO(2,icoc)/2)^2; % area of cylinder looking up
	   	   Cdjzco=CdCO(icoc);
	   	else % then this is a sphere
	   	   Azco=pi*(HCO(3,icoc)/2)^2;
	   	   Cdjzco=CdCO(icoc);
         end
      Qzco=Qzco + 0.5*rhoi(i)*Cdjzco*Azco*Umag(i)*Wi(i); 
      end
   end
   Qz(j)=Qz(j)+Qzco;
end
% Flip tow cable right side up, indecies start at bottom.
Qx=fliplr(Qx);Qy=fliplr(Qy);Qz=fliplr(Qz); 
Hi=fliplr(Hi);Bi=fliplr(Bi);Cdi=fliplr(Cdi);MEi=fliplr(MEi);
HCO=fliplr(HCO);BwCO=fliplr(BwCO);CdCO=fliplr(CdCO);
%
% First Pass
% Now we solve for first order wire angles, starting at the top of the mooring, 
%  where there is no tension from above, Ti=0.
% Then there are three equations and three unknowns at each element.
% 1) Qx(i) + T(i)*cos(theta(i))*sin(psi(i)) = T(i+1)*cos(theta(i+1))*sin(psi(i+1))
% 2) Qy(i) + T(i)*sin(theta(i))*sin(psi(i)) = T(i+1)*sin(theta(i+1))*sin(psi(i+1))
% 3) Wz(i) + Qz(i) + T(i)*cos(psi(i)) = T(i+1)*cos(psi(i+1))
% where the Q's are the drags, Wz is the weight/buoyancy, 
%    T(i) is the tension from above, T(i+1) is the tension from below,
%    psi(i) is the wire angle from z, theta(i) angle in x-y plane
%    Calculate T(i+1), phi(i+1) and theta(i+1) at element i, 
%    working from the top T(1)=0, to the bottom.
%  All cylinders have a tangential drag coefficient of 0.01
%  Here it is assumed that the top of the mooring is a float, or 
%  at least has positive buoyancy and will "lift" the first few elements.
%
Ti(1)=0; % tension from below bottom device==0
theta(1)=0;
psi(1)=0;
b=Bi(1)+Qz(1); % downward force is sum of weight and vertical drag
theta(2)=atan2(Qy(1),Qx(1));
Ti(2)=sqrt(Qx(1)^2 + Qy(1)^2 + b^2); % initial tension is likely downward
psi(2)=atan2(sqrt(Qx(1)^2+Qy(1)^2),b);
% Now Solve from bottom to top.
for i=2:N-1, % N-1
   ico=[];if ~isempty(Iobj),ico=find(Iobj==i);end % If ~isempty(ico), then there is a clamp on device here
   ip1=i+1;
   xx=Qx(i)+Ti(i)*cos(theta(i))*sin(psi(i));
   yy=Qy(i)+Ti(i)*sin(theta(i))*sin(psi(i));
   zz=Bi(i)+Qz(i)+Ti(i)*cos(psi(i));
   if ~isempty(ico), zz=zz + sum(BwCO(ico)); end % add buoyancy of clamp-on devices
   theta(ip1)=atan2(yy,xx);
   Ti(ip1)=sqrt(xx^2 + yy^2 + zz^2);
   if Ti(ip1) ~= 0, % this is unlikely, but...
      psi(ip1)=atan2(sqrt(xx^2+yy^2),zz);
   else
      psi(ip1)=psi(i);
   end
end
%
% Now integrate from the top to bottom to get the first order [x,y,z] relative to top
% Allow wire/rope sections to stretch under tension
%
	X(N)=0;Y(N)=0;Z(N)=Hi(1,N);  % reference things to bottom of top device.
	dx0=0;dy0=0;dz0=0;
	for i=N-1:-1:1, % in flippd indicies, sum from top down       N-1
  		if Hi(2,i)~=0,
  		   dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i)));
  		else
  		   dL=1;
  		end
  		LpdL=Hi(1,i)*dL;
  		X(i)=X(i+1) + LpdL*cos(theta(i))*sin(psi(i))/2 + dx0;
  		Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(psi(i))/2 + dy0;
  		Z(i)=Z(i+1) - LpdL*cos(psi(i))/2 - dz0;
  		dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
  		dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
  		dz0=LpdL*cos(psi(i))/2;
   end
%
% Now with the first order positions, we must re-estimate the new
% drags at the new heights (Zi) and for cylinders tilted by psi in flow.
% If this is a surface float mooring, then increase the amount of the
% surface float that is submerged until the height to the bottom of the float is 
% within the range Zw > Zf > (Zw - H(1,1)) 
%
rand('state',sum(100*clock));
breaknow=0;iconv=0;
icnt=0;
iavg=0;
isave=0;
dg=0.1;gf=0.75;
dgc=0;
deltaz=0.01; % how close to convergence
im1=[];bw=0;
Cdskin=0.01;
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%                                    % 
		% Main iteration/convergence loop    %
		%                                    % 
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dZsave(1:2)=1000;
zcor=0;
ico=0;
iavgc=2;ias=20;
Umag=sqrt(Ui.^2 + Vi.^2 + Wi.^2); % total velocity, used in drag calculations
while breaknow==0,  % loop through a few times to converge solution.
   %
   ist=[];
    isave=isave+1;
	Zf=Z(1)-Hi(1,1)/2;  % depth to top of deepest device/towed body 
   icnt=icnt+1;
   if iprt==0,
		if mod(icnt,icprt)==0, fprintf(1,'.');end
   	if icnt==60*icprt, icnt=0; icprt=icprt+1;fprintf(1,'%8i',isave);disp(' ');end
   end
   %  
   phix=atan2((Ti.*cos(theta).*sin(pi-psi)),(Ti.*cos(pi-psi))); 
   phiy=atan2((Ti.*sin(theta).*sin(pi-psi)),(Ti.*cos(pi-psi)));
   Qx=ones(1,N)*0.0;  % initialize all drags forces to zero
   Qy=Qx;Qz=Qx;
   psi1=pi-psi;
   for j=1:N, % from bottom up
      ico=[];
      if ~isempty(Iobj),ico=find(Iobj==j); end % If ~isempty(ico), then there is a clamp on device here
      if min(Z)<0, indx=find(Z<=0);Z(indx)=0.01; end % force to be in water
	   i=find(zi>(Z(j)-1.0)&zi<(Z(j)+1.0)); % find the depth of this device
	   if isempty(i), 
	      disp(['Check this configuration: ',num2str([j Z(1) Z(j)])]);
	      error(' Can''t find the velocity at this element! Near line 352 of towdyn.m');
	   end
      i=i(1); % just in case it got more than one value/index
      %
      theta2=atan2(Vi(i),Ui(i)); % the horizontal current vector angle
      UVLmag=sqrt(Ui(i)^2 + Vi(i)^2)*cos(theta(j)-theta2); % the magnitude of the horizontal current in the plane of the tilted element
      UL=UVLmag*cos(theta(j)); % break horizontal current into part in theta plane [UL,VL] and perpendicular part [Up,Vp]
      VL=UVLmag*sin(theta(j));
      Up=Ui(i)-UL; % remainder is perpendicular velocity component
      Vp=Vi(i)-VL;
      theta3=atan2(VL,UL);  % should be aligned with theta
      thetap=atan2(Vp,Up);  % perpendicular to theta3 and theta
      psi2=psi1(j)-pi/2;
      %
      % The exposed area must be a positive number, but the drag coefficient may
      %     have to change sign in order to get the proper lift characteristics.
      % We will now (April 2009) split the drag on tilted cylinders into two calculations:
      %    1) the portion due to flow in the theta (tilt) plane and 
      %    2) the flow perpendicular to the theta plane
      % For spheres, the drag is more classic rho/2*Cd*A*U^2
      %
      if Hi(3,j)==0, % then this is an in-line cylinder/wire/chain section
          A=Hi(1,j)*Hi(2,j); % area of cylinder/wire/chain
         % first estimate the horizontal drag vector from Up & Vp, then break into components
          Qh=0.5*rhoi(i)*Cdi(j)*A*(Up^2 + Vp^2);
          Qx(j)=Qh*cos(thetap);
          Qy(j)=Qh*sin(thetap);
	   else % this is an in-line sphere and all the drag is calculated here
	      A=pi*(Hi(3,j)/2)^2;
          Qh=0.5*rhoi(i)*Cdi(j)*A*(Ui(i)^2 + Vi(i)^2);
          Qx(j)=Qh*cos(theta2);
          Qy(j)=Qh*sin(theta2);
          Qz(j)=0.5*rhoi(i)*Cdi(j)*A*abs(Wi(i))*Wi(i);
      end
      Qxco=0;Qyco=0;Qzco=0; 
      if ~isempty(ico),
         if HCO(3,ico)==0, % then this is a clamp-on cylinder device, do perpendicular drag first
             A=HCO(1,ico)*HCO(2,ico);
             Cdjco=CdCO(ico) + HCO(2,ico)*pi*0.01*(1-((pi/2-psi1(j))/(pi/2)));
             Qhco=0.5*rhoi(i)*Cdjco*A*(Up^2 + Vp^2);
             Qxco=Qhco*cos(thetap);
             Qyco=Qhco*sin(thetap);
	   	 else % this is a clamp-on sphere, this is the only drag on this clamp-on device
	   	     A=pi*(HCO(3,ico)/2)^2;
             Qhco=0.5*rhoi(i)*CdCO(ico)*A*(Ui(i)^2 + Vi(i)^2);
             Qxco=Qhco*cos(theta2);
             Qyco=Qhco*sin(theta2);
             Qzco=0.5*rhoi(i)*CdCO(j)*A*abs(Wi(i))*Wi(i);
         end
       end
       Qx(j)=Qx(j) + Qxco;
	   Qy(j)=Qy(j) + Qyco;
       Qz(j)=Qz(j) + Qzco;
       %
       % This next section then estimates the drag associated with a lift/normal force in the theta plane
       % From Hoerner(1965) pages 3-11.
       % Because we are up-side down with a towed body, we use psi1=pi-psi and psi2=psi1-pi/2 (normal)
       %
	   if Hi(3,j)==0, % then this is a tilted cylinder device, now calcualte lift forces
         A=Hi(1,j)*Hi(2,j);
         CdUV=Cdi(j)*cos(psi1(j))^3 + Hi(2,j)*pi*0.01*(1-((pi/2)-psi1(j))/(pi/2));
         CdW=Cdi(j)*cos(psi2)^3 + Hi(2,j)*pi*0.01*(1-((pi/2)-psi1(j))/(pi/2));
         sl=sign(sin(theta(j)))*sign(sin(theta3));
         if sl==0,sl=1; end
         CdLUV=-Cdi(j)*cos(psi1(j))^2*sin(psi1(j));
         CdLW=Cdi(j)*cos(psi2)^2*sin(psi2);
         %
         QhUV=0.5*rhoi(i)*CdUV*A*UVLmag^2;
         Qx(j)=Qx(j) + QhUV*cos(theta3);
         Qy(j)=Qy(j) + QhUV*sin(theta3);
         %
         QhLW=0.5*rhoi(i)*CdLW*A*abs(Wi(i))*Wi(i);
         Qx(j)=Qx(j) + QhLW*cos(theta(j));
         Qy(j)=Qy(j) + QhLW*sin(theta(j));
         %
         Qz(j)=Qz(j) + 0.5*rhoi(i)*CdLUV*A*UVLmag^2*sl;
         Qz(j)=Qz(j) + 0.5*rhoi(i)*CdW*A*abs(Wi(i))*Wi(i);
      end
      Qxco=0;Qyco=0;Qzco=0;
      if ~isempty(ico),
	   	if HCO(3,ico)==0, % then this is a tilted cylinder/wire/chain section
	   	   Aco=HCO(1,ico)*HCO(2,ico); % area of tilted cylinder
           Aeco=pi*(HCO(1,ico)/2)^2; % area of end of cylinder
           CdUV=CdCO(ico)*cos(psi1(j))^3 + HCO(2,j)*pi*0.01*(1-((pi/2)-psi1(j))/(pi/2));
           CdW=CdCO(ico)*cos(psi2)^3 + HCO(2,j)*pi*0.01*(1-((pi/2)-psi1(j))/(pi/2));
           sl=sign(sin(theta(j)))*sign(sin(theta3));
           if sl==0,sl=1; end
           CdLUV=-CdCO(ico)*cos(psi1(j))^2*sin(psi1(j));
           CdLW=CdCO(ico)*cos(psi2)^2*sin(psi2);
           %
           QhUV=0.5*rhoi(i)*CdUV*Aco*UVLmag^2;
           Qxco=QhUV*cos(theta3);
           Qyco=QhUV*sin(theta3);
           Qzco=0.5*rhoi(i)*CdLUV*Aco*UVLmag^2*sl;
           %
           QhLW=0.5*rhoi(i)*CdLW*Aco*abs(Wi(i))*Wi(i);
           Qxco=Qxco + QhLW*cos(theta(j));
           Qyco=Qyco + QhLW*sin(theta(j));
           Qzco=Qzco + 0.5*rhoi(i)*CdW*Aco*abs(Wi(i))*Wi(i);
           %
           Qhe=0.5*rhoi(i)*0.65*abs(sin(psi1(j)))*Aeco*UVLmag^2;
           Qxco=Qxco + Qhe*cos(theta3);
           Qyco=Qyco + Qhw*sin(theta3);
           Qzco=Qzco + 0.5*rhoi(i)*0.65*abs(cos(psi1(j)))*Aeco*abs(Wi(i))*Wi(i);
         end
      end
      Qx(j)=Qx(j) + Qxco;
      Qy(j)=Qy(j) + Qyco;
      Qz(j)=Qz(j) + Qzco;
   end
   % Now re-solve for displacements with new tensions/drags.
   Ti(1)=0; % no tension below bottom device.
   b=Bi(1)+Qz(1); % vertical force at bottom is weight of bottom device is weight plus vertical drag
   theta(2)=atan2(Qy(1),Qx(1)); % angle in horizontal plane
   theta(1)=theta(2);
   Ti(2)=sqrt(Qx(1)^2 + Qy(1)^2 + b^2); % total tension above is due to horizontal drag and vertical forces
   %
   psi(1)=atan2(sqrt(Qx(1)^2+Qy(1)^2),b);  % angle/tilt to the second element (of wire)
   psi(2)=psi(1); % BUG Nov 2016: was psi(1)=0; This matters for bottom of towed cylinder bodies!!
                  % For sphere objects, this changes nothing, for cylinders it matters.
   %
   % Now Solve from bottom to top
	for i=2:N-1,  % N-1
      ico=[];if ~isempty(Iobj),ico=find(Iobj==i);end % If ~isempty(ico), then there is a clamp on device here
      ip1=i+1;
      if (Z(i)+Hi(1,i)*cos(psi(i))/2) > 0 & (Z(i)-Hi(1,i)*cos(psi(i))/2) < 0 & Bi(i) > 0, % then this buoyant device is at the surface
         perofB=abs((Z(i)+(Hi(1,i)*cos(psi(i))/2)/Hi(1,i))); % percentage of object in water
         perofB=min([1 perofB]);perofB=max([0.01 perofB]); % force the fraction of buoyancy between 0 and 1 
      else
         perofB=1; % if totally submerged, use all drag/buoyancy
      end
      xx=perofB*Qx(i)+Ti(i)*cos(theta(i))*sin(pi-psi(i)); % force in x-direction on next element
	  yy=perofB*Qy(i)+Ti(i)*sin(theta(i))*sin(pi-psi(i)); % force in y-direction on next element
      zz=perofB*(Bi(i)+Qz(i))+Ti(i)*cos(psi(i)); % force in z-direction on next element
      if ~isempty(im1) & ~isempty(ist),
         if im1==i, zz=zz+sum(Bi(ist+1:end-1))/2; end % add the weight of the remaining wire above/hanging from this float
      end
      if ~isempty(ico), zz=zz+sum(BwCO(ico)); end % add buoyancy of clamp-on devices
	  theta(ip1)=atan2(yy,xx);
	  Ti(ip1)=sqrt(xx^2 + yy^2 + zz^2);
	  if Ti(ip1) ~= 0,
	  	 psi(ip1)=atan2(sqrt(xx^2+yy^2),zz);
	  else
	  	 psi(ip1)=psi(i);
      end
     end
   %  
	%
	% Now integrate from the bottom to top to get the second order [x,y,z] relative to the bottom
	% Allow wire/rope to stretch under tension
   %
	   X(N)=0;Y(N)=0;Z(N)=0;  % reference things to ocean surface.
	   dx0=0;dy0=0;dz0=0;
		for i=N-1:-1:1,        % N-1
		   if Hi(2,i)~=0,
		      dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i))); % wire/rope may stretch
		   else
		      dL=1; % otherwise no stretching (unit length)
		   end
		   LpdL=Hi(1,i)*dL;
		   X(i)=X(i+1) + LpdL*cos(theta(i))*sin(pi-psi(i))/2 + dx0;
		   Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(pi-psi(i))/2 + dy0;
		   Z(i)=Z(i+1) - LpdL*cos(psi(i))/2 - dz0;
		   dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
		   dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
		   dz0=LpdL*cos(psi(i))/2;
      end
   psi(N)=psi(N-1); % angle of top device equals angle just below surface
   im1=[];iup=0;
   indx0=find(Z==min(Z));
   Znew=0;
   % if the top device is a mid-way float, re-calculate the positions of the lower postion only
   if min((Z(1:end-1)-Hi(1,1:end-1)/2))<0 & sum(find(Bi(find((Z(1:end-1)-Hi(1,1:end-1)/2)<0))>0))>0,
      indx=find((Z(1:end-1)-Hi(1,1:end-1)/2)<0); % find the indecises of the "out of the water" devices
      im1=find(Bi(indx)>0);
      if ~isempty(im1), % then we have a buoyany device, that is "out of the water"
         im1=indx(im1(1));
         ist=im1+1;
         peroffiw=(abs(Ti(im1-1)*cos(psi(im1-1)))+abs(sum(Bi(im1+1:end))/2))/Bi(im1); % percentage of float in water
         peroffiw=max([0 peroffiw]);peroffiw=min([1 peroffiw]);
         Znew=peroffiw*Hi(1,im1) - Hi(1,im1)/2;
         Zist=Znew-Hi(1,im1)/4;
         X(im1)=0;Y(im1)=0;Z(im1)=Znew;
		 dx0=(Hi(1,im1)/2)*cos(theta(i))*sin(psi(i))/2;
         dy0=(Hi(1,im1)/2)*sin(theta(i))*sin(psi(i))/2;
         dz0=(Hi(1,im1)/2)*cos(psi(i))/2;
		 for i=im1-1:-1:1,        % from here to the end
			if Hi(2,i)~=0,
                dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i))); % wire/rope may stretch
            else
                dL=1; % otherwise no stretching (unit length)
            end
            LpdL=Hi(1,i)*dL;
            X(i)=X(i+1) + LpdL*cos(theta(i))*sin(psi(i))/2 + dx0;
            Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(psi(i))/2 + dy0;
            Z(i)=Z(i+1) - LpdL*cos(psi(i))/2 - dz0;
            dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
            dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
            dz0=LpdL*cos(psi(i))/2;
	     end
       	iup=1;
      end
   end
   %
   %
	if isave >= 20, % start averaging positions, solution is bouncing between un-stable positions
	   iavg=iavg+1;
	   if iavg==1,
	      Tiavg=Ti;
	      psiavg=psi;
          Zavg=Z;
          Z1(1)=Z(1);
	      Xavg=X;
	      Yavg=Y;
	   else
	      Tiavg=Tiavg+Ti;
	      psiavg=psiavg+psi;
          Zavg=Zavg+Z;
          Z1(isave)=Z(1);
	      Xavg=Xavg+X;
	      Yavg=Yavg+Y;
          Z1std=std(Z1);
	   end
   end
   %
   if isave==1&iprt==1, hf9=figure(9);set(hf9,'Position',[ss(3)-220 10 190 100]);clf; end
   if iprt==1 & isave>20, 
      figure(9);hold on;
      plot(isave,Z(1),'ob'); drawnow;
      disp([iavg Z(1) Zavg(1)/iavg dZsave(isave-1)]);
   end
	if isave > 2, % must do at least three iterations to check convergence
      if abs(Zsave(isave-1)-Z(1)) < deltaz & abs(Zsave(isave-2)-Zsave(isave-1)) < deltaz, % 2 close calls...
         breaknow=1; % then the solution has converged.
      end
	   if iavg == 200, % after 400 averaging iterations, assume converged!
	      X=Xavg/iavg;
	      Y=Yavg/iavg;
	      Z=Zavg/iavg;
	      Ti=Tiavg/iavg;
	      psi=psiavg/iavg;
         breaknow=1;
         iconv=1;
      end
      dZsave(isave)=(Zsave(isave-1)-Z(1));
   end
   Zsave(isave)=Z(1);
   %
   if iavg > ias, % after 20 avg iterations, start using the average height to assist convergence
      Z=Zavg/iavg; % if solution is "bouncing", then help converge faster to average.
      psi=psiavg/iavg;
		if iavg > ias*iavgc, % and later, converge average
         Tiavg=ias*Tiavg/iavg;
         psiavg=ias*psiavg/iavg;
         Zavg=ias*Zavg/iavg;
         Yavg=ias*Yavg/iavg;
         Xavg=ias*Xavg/iavg;
         iavg=ias;
         iavgc=iavgc+1;
      end
   end
   %
   %
end % end convergence/while loop
%
tenfac=1.0;
decr=0.99;incr=1.005;
iincr=-1;
%
% The next section is for a tow with float configuration only, with the float on/near the surface
%  This solution has been broken into two separate "solutions", matched at the float
if iup==1 & ~isempty(ist),
   if ist < N | (min((Z(1:end-1)-Hi(1,1:end-1)/2))<0 & sum(find(Bi(find((Z(1:end-1)-Hi(1,1:end-1)/2)<0))>0))>0),
      indx=find((Z(1:end-1)-Hi(1,1:end-1)/2)<0); % find the indecises of the "out of the water" devices
      im1=find(Bi(indx)>0);
      if ~isempty(im1), % then we have a buoyany device, that is "out of the water"
         disp('Solving for upper "loop".');
			im1=indx(im1(1));
         ist=im1+1;
         Thx=Qx(im1)+Ti(im1-1)*cos(theta(im1))*sin(pi-psi(im1));
         Thy=Qy(im1)+Ti(im1-1)*sin(theta(im1))*sin(pi-psi(im1));
         break2=1;
         icl2=0;
         while break2, % now loop to get top wire hanging from surface back to surface
            icl2=icl2+1;
				phix=atan2((Ti.*cos(theta).*sin(pi-psi)),(Ti.*cos(pi-psi))); 
   			phiy=atan2((Ti.*sin(theta).*sin(pi-psi)),(Ti.*cos(pi-psi)));
   			for j=ist:N, % from after float to top
			      ico=[];if ~isempty(Iobj),ico=find(Iobj==j);end % If ~isempty(ico), then there is a clamp on device here
			      if Z(j)<0, Z(j)=0.01; end % force to be in water
				   i=find(zi>(Z(j)-1.0)&zi<(Z(j)+1.0)); % find the depth of this device
				   i=i(1); % just in case it got more than one value/index
				   if Hi(3,j)==0, % then this is a cylinder/wire/chain section
				      Ax=Hi(1,j)*Hi(2,j)*abs(cos(phix(j))); % area of cylinder/wire/chain
				      Ay=Hi(1,j)*Hi(2,j)*abs(cos(phiy(j))); % area of cylinder/wire/chain
				      Cdjx=Cdi(j)*cos(phix(j))^2 + pi*0.01*abs(sin(phix(j))); % the tangential drag goes from 0 to 0.0314 with tilt.
				      Cdjy=Cdi(j)*cos(phiy(j))^2 + pi*0.01*abs(sin(phiy(j)));
         			  if Cdi(j)==0.0, Cdjx=0;Cdjy=0; end
				   else % this is a sphere
				      Ax=pi*(Hi(3,j)/2)^2;
				      Ay=Ax;
				      Cdjx=Cdi(j);
				      Cdjy=Cdjx;
			      end
			      Qxco=0;Qyco=0; % assume no clamp-on devices (zero drag)
			      if ~isempty(ico),
			         if HCO(3,ico)==0, % then this is a cylinder device
			            Axco=HCO(1,ico)*HCO(2,ico)*abs(cos(phix(j))); % area of cylinder/wire/chain
				   	    Ayco=HCO(1,ico)*HCO(2,ico)*abs(cos(phiy(j))); % area of cylinder/wire/chain
				   	    Cdjxco=CdCO(ico)*cos(phix(j))^2 + pi*0.01*abs(sin(phix(j)));
				   	    Cdjyco=CdCO(ico)*cos(phiy(j))^2 + pi*0.01*abs(sin(phiy(j)));
         				if CdCO(ico)==0.0, Cdjxco=0;Cdjyco=0; end
				   	else % this is a sphere device
				   	    Axco=pi*(HCO(3,ico)/2)^2;
				   	    Ayco=Axco;
				   	    Cdjxco=CdCO(ico);
				   	    Cdjyco=Cdjxco;
			      	end
				   	Qxco=0.5*rhoi(i)*Cdjxco*Axco*Umag(i)*Ui(i); % drag for clamp-on devices
				   	Qyco=0.5*rhoi(i)*Cdjyco*Ayco*Umag(i)*Vi(i);
			      end
			      Qx(j)=0.5*rhoi(i)*Cdjx*Ax*Umag(i)*Ui(i) + Qxco;
				   Qy(j)=0.5*rhoi(i)*Cdjy*Ay*Umag(i)*Vi(i) + Qyco;
				   if Hi(3,j)==0, % then this is a tilted cylinder device
				      Az=Hi(1,j)*abs(sin(psi(j)))*Hi(2,j) + abs(cos(psi(j)))*pi*(Hi(2,j)/2)^2; % area of tilted cylinder looking up
				      Cdjz=Cdi(j) + pi*0.01*(1-(psi(j)/(pi/2)));
				      Cdjx=sign(sign(phix(j))*cos(phix(j)))*(Cdi(j)*abs(cos(phix(j)))*sin(phix(j))^2 + pi*0.01*abs(sin(phix(j)))); % these provide lift
				      Cdjy=sign(sign(phiy(j))*cos(phiy(j)))*(Cdi(j)*abs(cos(phiy(j)))*sin(phiy(j))^2 + pi*0.01*abs(sin(phiy(j)))); % lift
         			  if Cdi(j)==0.0, Cdjx=0;Cdjy=0; end
				   else % then this is a sphere device
				      Az=pi*(Hi(3,j)/2)^2;
				      Cdjz=Cdi(j);
				      Cdjx=0;Cdjy=0;
			      end
			      Qzco=0;
			      if ~isempty(ico),
				   	if HCO(3,ico)==0, % then this is a tilted cylinder/wire/chain section
				   	   Azco=HCO(1,ico)*abs(sin(psi(j)))*HCO(2,ico) + abs(cos(psi(j)))*pi*(HCO(2,ico)/2)^2; % area of tilted cylinder looking up
				   	   Cdjzco=CdCO(ico) + pi*0.01*(1-(psi(j)/(pi/2)));
				   	   Cdjxco=sign(sign(phix(j))*cos(phix(j)))*(CdCO(ico)*abs(cos(phix(j)))*sin(phix(j))^2 + pi*0.01*abs(sin(phix(j)))); % these provide lift
				   	   Cdjyco=sign(sign(phiy(j))*cos(phix(j)))*(CdCO(ico)*abs(cos(phiy(j)))*sin(phiy(j))^2 + pi*0.01*abs(sin(phiy(j)))); % lift
         				if CdCO(ico)==0.0, Cdjxco=0;Cdjyco=0; end
				   	else % then this is a sphere
				   	   Azco=pi*(HCO(3,ico)/2)^2;
				   	   Cdjzco=CdCO(ico);
				   	   Cdjxco=0;Cdjyco=0;
 						end
					   	Qzco=0.5*rhoi(i)*Azco*Umag(i)*(Cdjzco*Wi(i) + Cdjxco*Ui(i) + Cdjyco*Vi(i)); 
			      end
				   Qz(j)=0.5*rhoi(i)*Az*Umag(i)*(Cdjz*Wi(i) + Cdjx*Ui(i) + Cdjy*Vi(i)) + Qzco; 
			   end
%
	         Qzz=Qz(ist:N-1); % the vertical drag of remaining components
	         Tv1=tenfac*sum(Bi(ist+1:end-1))/2 + sum(Qzz(find(Qzz<0)))*0.9; % the initial vertical tension is half the weight of last section of wire
         	Ti(ist)=sqrt(Thx^2 + Thy^2 + Tv1^2);
         	psi(ist)=atan2(sqrt(Thx^2+Thy^2),Tv1);
       		theta(ist)=atan2(Thy,Thx);
            for i=ist:N-1, % now solve caternary shape from surface down and up to surface
        		   ip1=i+1;
        		   xx=Qx(i)+Ti(i)*cos(theta(i))*sin(pi-psi(i)); % note here we're dealing with negative tension contributions
     	  		   yy=Qy(i)+Ti(i)*sin(theta(i))*sin(pi-psi(i));
        		   zz=Ti(i)*cos(psi(i))-Bi(i)-Qz(i); % to get it to come back up to the surface, -buoyancy
        		   theta(ip1)=atan2(yy,xx);
        		   Ti(ip1)=sqrt(xx^2 + yy^2 + zz^2);
	   			   if Ti(ip1) ~= 0,
	   		   	      psi(ip1)=atan2(sqrt(xx^2+yy^2),zz);
                   else
	   		   	      psi(ip1)=psi(i);
	   			   end
        	end
            psi(ist:N)=pi-psi(ist:N); % note for this section, psi has been up from vertical!
            X(N)=0;Y(N)=0;Z(N)=0;dx0=0;dy0=0;dz0=0;
        	for i=N-1:-1:ist,
                    if Hi(2,i)~=0,
				   	   dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i))); % wire/rope may stretch
                    else
				   	   dL=1; % otherwise no stretching (unit length)
				    end
				   LpdL=Hi(1,i)*dL;
				   X(i)=X(i+1) + LpdL*cos(theta(i))*sin(psi(i))/2 + dx0;
				   Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(psi(i))/2 + dy0;
				   Z(i)=Z(i+1) - LpdL*cos(psi(i))/2 - dz0;
				   dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
				   dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
				   dz0=LpdL*cos(psi(i))/2;
            end
            if icl2>50, disp([Zist Z(ist) Ti(ist) psi(ist)*180/pi tenfac]);end
            if abs(Z(ist)-Zist)<(2*Hi(1,ist)),
           	   break2=0;
           	else
               if Z(ist)<Zist, % then the float end is too high
                  if iincr==1, decr=decr^0.5; end
                  tenfac=tenfac*decr;
                  iincr=-1;
               else % then the float end is too deep
                  if iincr==-1, incr=incr^0.5; end
                  tenfac=tenfac*incr;
                  iincr=1;
           	   end
           	end
           end % end this second while
           X(N)=0;Y(N)=0;Z(N)=0;dx0=0;dy0=0;dz0=0;
           for i=N-1:-1:1, % recalculate all the tow positions
			  	   if Hi(2,i)~=0,
				   	dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i))); % wire/rope may stretch
					else
				   	dL=1; % otherwise no stretching (unit length)
				   end
			   	LpdL=Hi(1,i)*dL;
				   X(i)=X(i+1) + LpdL*cos(theta(i))*sin(psi(i))/2 + dx0;
				   Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(psi(i))/2 + dy0;
				   Z(i)=Z(i+1) - LpdL*cos(psi(i))/2 - dz0;
				   dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
				   dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
				   dz0=LpdL*cos(psi(i))/2;
           end
		end
   end
end % iup
%
%
if ~isempty(ZCO), % then we've got clamp-on devices, and we need to find the initial height for them
   mmco=length(ZCO);
   for jco=1:mmco,
      el=Jobj(jco); % this is the element it's attached to
      Z0co(jco)=Z(Iobj(jco)) - Piobj(jco)*(Z(Iobj(jco)-1)-Z(Iobj(jco)));
   end
end
% if there are clamp-on device, figure out there position.
if ~isempty(ZCO), % then we've got clamp-on devices, and we need to find the positions of them
      mmco=length(ZCO);
      for jco=1:mmco,
         el=Iobj(jco); % this is the element it's attached to
         Zfco(jco)=Z(el) - Piobj(jco)*(Z(el-1)-Z(el));
         Xfco(jco)=X(el) - Piobj(jco)*(X(el-1)-X(el));
         Yfco(jco)=Y(el) - Piobj(jco)*(Y(el-1)-Y(el));
         psifco(jco)=psi(el) - Piobj(jco)*(psi(el-1)-psi(el));
         disp([Z(el) Zfco(jco) X(el) Xfco(jco)]);
      end
end
%
I=(2:N-1);
iobj=find(Hi(4,:) ~=1); % indices of the non-wire/joiner elements
jobj=1+find(Hi(4,I) == 1 & (Hi(4,I-1) ~= 1|Hi(4,I+1) ~= 1)); % indices of wire/rope/chain elements
ba=psi(N-1); % vertical angle of tension at surface
ha=theta(N-1);
wpm=(1024*(pi*(Hi(2,N-1)/2)^2))-(Bi(N-1)/9.81); % weight of wire out of water
Wa=Ti(N)/9.81;
VWa=Wa*cos(ba);
HWa=Wa*sin(ba);
disp('  ');
%
disp([' Total Tension at Surface [kg] = ',num2str(Wa,'%8.1f')]);
disp([' Vertical load [kg] = ',num2str(VWa,'%8.1f'),'  Horizontal load [kg] = ',num2str(HWa,'%8.1f')]);
disp([' Depth of End Device [m] = ',num2str(Z(1),'%8.1f')]);
% reset original current profile.
z=ztmp;U=Utmp;V=Vtmp;W=Wtmp;rho=rhotmp;
if iprt==1, close(9); end
% fini
