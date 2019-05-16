function [X,Y,Z,iobj]=moordyn(U,z,H,B,Cd,ME,V,W,rho)
% function [X,Y,Z,iobj]=moordyn(U,z,H,B,Cd,ME,V,W,rho)
%
% Calculate the mooring element positions relative to anchor, 
% X (+East), Y (+North) and Z (+Up) all in metres
%    given a velocity profile U(z) at depths z [m] (+up), with U(0)=0 
% For an oceanographic mooring from top to bottom
%    with N elemental components (including wire sections as elements),
%    dimensions H(L W D i,N) [m] of each different mooring component/element, 
%    mass/buoyancies B(N) [in kg, or kg/m for wire/chain] (+up),
%    Drag coefficients (Cd(N)). ME (modulus of elasticity indecies)
%    where 1=steel,2=Nylon,3=Dacron,4=Polyprop,5=Polyethy,6=Kevlar,7=Aluminum
% Output iobj are the idecices of the mooring "elements" not
%    including wire or chain [H(4,:)=1] elements.
%    Note: U (and V, W, and rho if provided) must extend to bottom (z=0).
% Optional inputs:
%    velocity components V(z) and W(z), rho(z)=density profile
%
% H(1,:) = Length/height of object/element including strength member [m]
%          H(1,N) is the height of the anchor [m]
% H(2,:) = Width of cylinder (0=zero if sphere) [m]
% H(3,:) = Diameter of sphere (0=zero if cylinder or wire/chain) [m]
% H(4,:) = 1 for wire/chain, 2 for fastener, 0 otherwise. Divide wire/chain into 1 m lengths
%
% May be passed with no arguments, assuming: global U z H B Cd V W rho
% RKD 12/97

if nargin == 0,
   global U V W z rho uw vw
   global H B Cd ME
end
global Hs Bs Cds MEs iss % saved for multiple float or "S" moorings
global moorele X Y Z Ti iobj jobj psi iEle theta
global HCO BCO CdCO mooreleCO ZCO Jobj Pobj PIobj IEle % any clamped on devices
global Z0co Zfco Xfco Yfco psifco
global Iobj
global nomovie
global Zoo
global Zi

iprt=50; % If solution isn't converging, set this to 50-100 and watch to see what's happening.

X=[];Y=[];Z=[];Ti=[];iobj=[];jobj=[];psi=[];
if isempty(iss), Hs=H;Bs=B;Cds=Cd;MEs=ME; end % save the original mooring design.
if ~isempty(find(B==0)), B(find(B==0))=-0.0001; end  % things can go horribly wrong with neutral buoyancy
[mu,nu]=size(U);
if (mu==0 & nu==0) | max(z)==0, % if environmental variable haven't been set
   U=[0.1 0.1 0];U=U(:);V=U;W=U;z=fix(sum(H(1,:))*[1.5 0.1 0]');z=z(:);rho=[1024 1025 1026]';rho=rho(:);
end
z(find(z(1:end-1)==0))=0.1; % make sure only last depth is zero
Zoo=[];Z0co=[];
Utmpo=U;Vtmpo=V;Wtmpo=W;
U=ones(size(z))*0;
V=U;W=U;
%
for izloop=1:2, % loop through at least twice with this mooring.
   % the first loop to estimate the initial component heights with no currents
   if izloop==2, % now use full current profile
      U=Utmpo;
      V=Vtmpo;
      W=Wtmpo;
   end
% Add 2% of wind speed to top current (10m) value
ztmp=z;Utmp=U;Vtmp=V;Wtmp=W;rhotmp=rho;
if mu ~= 1 & nu ~= 1, % then pickoff the first velocity profile.
   if mu==length(z),
      U=U(:,1);
      V=V(:,1);
      W=W(:,1);
   else
      U=U(1,:)';
      V=V(1,:)';
      W=W(1,:)';
   end
end
%
% Add 2% of wind speed to top current value(s)
    if uw~=0 | vw ~=0,
    windepth=sqrt(uw^2+vw^2)/0.02; % wind penetrates about 1m for every 1m/s, otherwise shears too high
    if (uw^2+vw^2)>0, % we actually have a wind
    if windepth > z(1), windepth==0.8*z(1); end % maximum wind depth is 80% of water depth
    if z(2)<(z(1)-windepth),  % add a new velocity at depth with no wind effect
      mu=length(z);
      z(3:mu+1)=z(2:mu);
      z(2)=z(1)-windepth;
      U(3:mu+1)=U(2:mu);
      U(2)=interp1([z(1) z(3)],[U(1) U(3)],z(2),'linear');
      U(1)=U(1)+uw;
      V(3:mu+1)=V(2:mu);
      V(2)=interp1([z(1) z(3)],[V(1) V(3)],z(2),'linear');
      V(1)=V(1)+vw;
      W(3:mu+1)=W(2:mu);
      W(2)=interp1([z(1) z(3)],[W(1) W(3)],z(2),'linear');
      rho(3:mu+1)=rho(2:mu);
      rho(2)=rho(1);
   else % this is affecting more than one velocity value
      uwindx=find(z > (z(1)-windepth));
      uw1=interp1([z(1) z(1)-windepth],[uw 0],z(uwindx),'linear');
      vw1=interp1([z(1) z(1)-windepth],[vw 0],z(uwindx),'linear');
      izero=find(abs(uw1)<0.01);uw1(izero)=0;
      izero=find(abs(uw1)<0.01);uw1(izero)=0;
      qq=0;
      for wi=uwindx,
          qq=qq+1;
          U(wi)=U(wi)+uw1(qq);
          V(wi)=V(wi)+vw1(qq);
      end
   end
   end
   end
%
% first change masses/buoyancies into forces (Newtons)
Bw=B*9.81; % Turn masses/buoyancies into forces
BwCO=BCO*9.81;
Bmax=Bw(1); % maximum buoyancy available at top of mooring
%
N=length(B); % initial number of elements, before segmenting wire/chain into 1 m lengths
%
% First determine if this is a sub-surface or surface float mooring.
% This is determined by the maximum height of the velocity profile as the water depth
Zw=max(z);  % The water depth!
S=sum(H(1,:)); % maximum length of the mooring
if isempty(nomovie), disp('  '); end
gamma=1;
if Zw > S, % then this is a sub-surface mooring
   ss=1;
   if isempty(nomovie) & izloop==2,disp('This is (starting off as) a sub-surface mooring');end
else % this is a surface float mooring
   ss=0;
   if isempty(nomovie) & izloop==2,disp('This is (starting off as) a potential surface float mooring');end
end
if izloop==1,
   disp('First, find neutral (no current) mooring component positions.'); 
   else
   disp('Searching for a converged solution.');
end
%
Zi=[];Hi=[];Bi=[];Cdi=[];MEi=[];iobj=[];
j=1; % for node setup, segment from bottom to top
Zi(1)=H(1,N);  % height of the top of the anchor, start of mooring
Hi(:,1)=H(:,N); % setup interpolated H,B,Cd variables
Bi(:,1)=Bw(:,N);
Cdi(1)=Cd(N);
MEi(1)=ME(N);
z0=H(1,N); % height of top of first element (anchor)
for i=N-1:-1:1, % setup initial heights of interpolated elements
   j=j+1;
   if H(4,i)==1,  % this section is wire/chain
      Hw=fix(H(1,i));
      dz=0.2;
      if Hw > 5 & Hw <=50
          dz=1;
      elseif Hw > 50 & Hw <= 100,
          dz=5;
      elseif Hw > 100 & Hw <= 500,
          dz=10;
      elseif Hw > 500,
          dz=50;
      end
      n=fix(H(1,i)/dz);
      Elindx(i,1)=j;
      for jj=j:j+n-1, 
         Zi(jj)=z0+dz/2;
         z0=z0+dz;
         Hi(:,jj)=[dz H(2,i) H(3,i) H(4,i)]';
         Bi(jj)=Bw(i)*dz; % the stored mass is per unit metre
         Cdi(jj)=Cd(i);
         MEi(jj)=ME(i);
      end
      j=j+n-1;
      Elindx(i,2)=j;
   else
      Elindx(i,1:2)=[j j];
      Zi(j)=z0 + H(1,i)/2;
      z0=z0+H(1,i);
      Hi(:,j)=H(:,i);
      Bi(j)=Bw(i);
      Cdi(j)=Cd(i);
      MEi(j)=ME(i);
   end
end
J=j;
% find interpolated indecise for the clamp-on devices
if ~isempty(ZCO), % then we've got clamp-on devices, and we need to find the indecies for them
   Iobj=[];PIobj=[];
   mmco=length(ZCO);
   ZiCO(1:mmco)=ZCO(mmco:-1:1); % originally clamp-on listed top to bottom
   HiCO(:,1:mmco)=HCO(:,mmco:-1:1);
   CdiCO(1:mmco)=CdCO(mmco:-1:1);
   Piobj(1:mmco)=Pobj(mmco:-1:1);
   Jiobj(1:mmco)=Jobj(mmco:-1:1);
   for jco=1:mmco,
      Iobj(jco)=fix((abs(Elindx(Jiobj(jco),2)-Elindx(Jiobj(jco),1))+1)*Piobj(jco))+Elindx(Jiobj(jco),1); % this is the interpolated element index
      PIobj(jco)=(ZiCO(jco)-Zi(Iobj(jco))+Hi(1,Iobj(jco))/2)/Hi(1,Iobj(jco)); % along this segment
   end
   % precently, Iobj and PIobj are indexed from bottom to top, flip later
end
Elindx=J+1-Elindx; % effectively flip this, now top to bottom
%
% now interpolate the velocity profile to 1 m estimates
dz=1;
dz0=mean(abs(diff(z)));
maxz=sum(H(1,:));
if dz0<1,   % if velocity profile is already 1m or less.
   Ui=U;
   Vi=V;
   Wi=W;
   rhoi=rho;
   zi=z;
else
   if z(1)>z(2), dz=-1; end
   if abs(z(end)-z(1)) < 10, dz=sign(dz)*0.1; end
	zi=[z(1):dz:z(end)];
	if ~isempty(U),
	  Ui=interp1(z,U,zi);
    else
      zi=[maxz:-1:0];
	  Ui=interp1([maxz+1 20 0],[0 0 0],zi,'linear');
    end
   %figure(9);plot(Ui,zi);drawnow
	if ~isempty(V),
	   Vi=interp1(z,V,zi,'linear');
	else
	   Vi=zeros(size(Ui));  % default to V=0
	end
	if ~isempty(W),
	   Wi=interp1(z,W,zi,'linear');
	else
	   Wi=zeros(size(Ui)); % default to W=0
	end
	if ~isempty(rho),
	   rhoi=interp1(z,rho,zi,'linear');
	else
	   rhoi=ones(size(Ui))*1025; % default density is 1025 kg/m^3
	end
end
Umag=sqrt(Ui.^2 + Vi.^2 + Wi.^2);  % the total current speed, needed for drag calculations
%
N=length(Bi); % the new number of "interpolated" in-line mooring elements

% Now find the drag on each element assuming first a vertical mooring.
if ss==0, % for surface float moorings...
   Bo=-sum(Bi(2:N-1)) + sum(BwCO) + sum(Cdi(2:N-1));% sum the weight of all elements except the surface float and anchor
   Zi=Zi*Zw/S; % force elements to be in water for drag, etc....
   Boo=Bo;
   gamma=Bo/Bmax;
   if gamma> 1, gamma=0.9; end
end
for j=1:N,  % from bottom-to-top for this first go through
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
      	if HiCO(3,icoc)==0, % then this is a cylinder device
         	Axco=HiCO(1,icoc)*HiCO(2,icoc); % area of cylinder/wire/chain
		   	Ayco=HiCO(1,icoc)*HiCO(2,icoc); % area of cylinder/wire/chain
	 	   	Cdjxco=CdiCO(icoc);
	  	   	Cdjyco=CdiCO(icoc);
	  		else % this is a sphere device
	  		   Axco=pi*(HiCO(3,icoc)/2)^2;
	  		   Ayco=Axco;
	  		   Cdjxco=CdiCO(icoc);
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
	   	if HiCO(3,icoc)==0, % then this is a cylinder/wire/chain section
	   	   Azco=pi*(HiCO(2,icoc)/2)^2; % area of cylinder looking up
	   	   Cdjzco=CdiCO(icoc);
	   	else % then this is a sphere
	   	   Azco=pi*(HiCO(3,icoc)/2)^2;
	   	   Cdjzco=CdiCO(icoc);
         end
      Qzco=Qzco + 0.5*rhoi(i)*Azco*Umag(i)*Cdjzco*Wi(i); 
      end
   end
   Qz(j)=Qz(j)+Qzco;
end
% Flip mooring right side up, indecies now start at top.
Qx=fliplr(Qx);Qy=fliplr(Qy);Qz=fliplr(Qz); 
Hi=fliplr(Hi);Bi=fliplr(Bi);Cdi=fliplr(Cdi);MEi=fliplr(MEi);
Iobj=J+1-Iobj(end:-1:1); % now they are top - to - bottom, like everything else
PIobj=1-PIobj(end:-1:1); % distance (%) along interpolated segments.
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
clear HiCo ZiCO CdiCO
Ti=[];theta=[];psi=[];
Ti(1)=0;
theta(1)=0;
psi(1)=0;
b=gamma*(Bi(1)+Qz(1));
theta(2)=atan2(Qy(1),Qx(1));
Ti(2)=sqrt(Qx(1)^2 + Qy(1)^2 + b^2);
psi(2)=acos(b/Ti(2));
% Now Solve from top to bottom.
for i=2:N-1,
  	ico=[];if ~isempty(Iobj),ico=find(Iobj==i);end % If ~isempty(ico), then there is a clamp on device here
   ip1=i+1;
   xx=Qx(i)+Ti(i)*cos(theta(i))*sin(psi(i));
   yy=Qy(i)+Ti(i)*sin(theta(i))*sin(psi(i));
   zz=Bi(i)+Qz(i)+Ti(i)*cos(psi(i));
   if ~isempty(ico), zz=zz + sum(BwCO(ico)); end % add buoyancy of clamp-on devices
   theta(ip1)=atan2(yy,xx);
   Ti(ip1)=sqrt(xx^2 + yy^2 + zz^2);
   if Ti(ip1) ~= 0,
      psi(ip1)=acos(zz/Ti(ip1));
   else % this is unlikely
      psi(ip1)=psi(i);
   end
end
%
% Now integrate from the bottom to the top to get the first order [x,y,z]
% Allow wire/rope sections to stretch under tension
%
for ii=1:2,
X(N)=0;Y(N)=0;Z(N)=Hi(1,N);  % reference things to top of anchor.
dx0=0;dy0=0;dz0=0;
for i=N-1:-1:1,
   if Hi(2,i)~=0,
      dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i)));
   else
      dL=1;
   end
   LpdL=Hi(1,i)*dL;
   X(i)=X(i+1) + LpdL*cos(theta(i))*sin(psi(i))/2 + dx0;
   Y(i)=Y(i+1) + LpdL*sin(theta(i))*sin(psi(i))/2 + dy0;
   Z(i)=Z(i+1) + LpdL*cos(psi(i))/2 + dz0;
   dx0=LpdL*cos(theta(i))*sin(psi(i))/2;
   dy0=LpdL*sin(theta(i))*sin(psi(i))/2;
   dz0=LpdL*cos(psi(i))/2;
   if Z(i) > Zw & Hi(4,i) == 1 & Bi(i) >0, Z(i)=Zw; psi(i)=pi/2; end % surface line
   if Z(i) <= Z(N), Z(i)= Z(N); psi(i)=pi/2; end % bottom chain
end
end
if max(Z)>Zw & ss==1, ss=0; gamma=sqrt(gamma); end % this may be a surface mooring after all
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
dg=0.1;gf=2;dgf=0;
dgc=0;
if izloop==1,
	  deltaz=0.1; % first zero current case, not as accurate 10 cm
   else
      deltaz=0.01;  % how close to you want the convergence! 0.01=1cm
end
gamma0=Ti(2)*cos(psi(2))/Bi(1); % estimate required lift
gammas=-1; % assume we're too high and start by decreasing gamma
if gamma < gamma0, gammas=1;end % otherwise start by increasing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                    % 
% Main iteration/convergence loop    %
%                                    % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ilines=1;ico=[];iiprt=0;dgci=10;
while breaknow==0,  % loop through a few times to converge solution.
   %
	isave=isave+1;
	Zf=Z(1)-Hi(1,1)/2;  % height to bottom of surface float 
	if ss==0, % working on surface float solution (harder problem). 
	   if isave>iprt, % hey, it's not converging, check out what's happening.
	      if isave==(iprt+1),
             disp('  ');
	         disp(' Take a closer look at the convergence...');
	         disp('Depth       Top      Bottom      % of float used  delta-converge');
             disp(num2str([Zw (Zf+Hi(1,1)) Zf gamma*100 gammas*dg])); % display to test convergence problems
          end
          iiprt=iiprt+1;
          if mod(iiprt,100)==0, disp(num2str([Zw (Zf+Hi(1,1)) Zf gamma*100 gammas*dg])); end % display to test convergence problems
       end
	   izm=find(Z<0); % just in case any elements are below the bottom, oops.
	   Z(izm)=0;      % dig them up.
       gamma0=Ti(2)*cos(psi(2))/Bi(1); % estimate required lift to support the mooring
	   if (1+gf)*dg >= gamma & gammas==-1, dg=dg/10; end % be careful if gamma is very small
	   if gamma+((1+gf)*gammas*dg) >=1 & gammas==-1, dg=dg/10; end % or if gamma is very large (1)
	   if (Zf+Hi(1,1)) <= Zw,  % then we're completely submerged! Increase % buoyancy.
	      dgc=dgc+1;
          dgf=0;
         if gammas == -1, % was decreasing, now increase 
            gammas=1; 
            dg=dg/10; 
            if dg < 1e-10, dg = 1e-5; end % shake things up a bit.
            dgc=0; 
         end
         gamma=gamma + gammas*dg*(gf * rand);
	      if dgc > dgci, 
	         dg=dg*10; 
	         dgc=0; 
	      end
	      %if (gamma+dg>1, gamma=1; ss=1; end % this is now a subsurface mooring.
       elseif Zw > Zf & Zw < (Zf+Hi(1,1)),  % then we're partially floating (we're close)
	      dgc=dgc+1;
          dgf=0;
	      if ((Zw-Zf)/Hi(1,1)) < gamma, % then decrease gamma
            if gammas == 1, 
               gammas=-1; 
               dg=dg/10;
               dgc=0; 
            end
	        gamma=gamma + gammas*dg*(gf * rand);
	        if dgc > dgci, 
	           dg=dg*10;
		       dgc=0; 
            end
   	       else % then increase gamma
            if gammas == -1, 
               gammas=1; 
               dg=dg/10; 
               dgc=0; 
            end
	         gamma=gamma + gammas*dg*(gf * rand);
	         if dgc > dgci, 
	            dg=dg*10; 
	            dgc=0; 
	         end
	      end
	      izz=find(Hi(4,:)==0);
	      if gamma<1e-10 & dg < 1e-09 & max(Z(izz))>(Zf+Hi(1,1)) & iavg > 200, % then there is still part of this mooring above water!
	         NN=length(B);
	         inext=find(B>1); % look for positive (floation device)
	         if length(inext)>1,
	            H=H(:,inext(2):NN);
	            B=B(:,inext(2):NN);
	            Cd=Cd(inext(2):NN);
	            ME=ME(inext(2):NN);
	            moorele=moorele(inext(2):NN,:);
	            U=Utmp;V=Vtmp;W=Wtmp;z=ztmp;rho=rhotmp;
	            disp('!! Top link(s) in mooring removed !!');
	            Z=[];iss=1;
	            dismoor;
	            moordyn;
	            return;
	         else
	            error('This mooring''s not working! Please examine. Strong currents or shears? Try reducing them.');
	         end
	      end
	   elseif Zf >= Zw,  % we're in trouble, the float is flying! Decrease % of float used.
	     dgc=dgc+1;
         dgf=dgf+1;
         if gammas == 1, % was increasing gamma, need to decrease it
            gammas=-1; 
            %dg=dg/10;
            if dg < 1e-10, dg = 1e-5; end % shake things up a bit.
            dgc=0; 
         end
         if dgf > 5, dg=1e-3; dgf=0; end % we gotta get back into the water
	     gamma=gamma + gammas*dg*(gf * rand);
	      if dgc > dgci, 
	         dg=dg*10; 
	         dgc=0; 
	      end
	      if gamma>=1, gamma=1; ss=1; end
	      if gamma < 1e-5, % then this float is not required. Less than 0.01% of float used.
	         NN=length(B);
	         inext=find(B>1);
	         if length(inext)>1,
	            H=H(:,inext(2):NN);
	            B=B(inext(2):NN);
	            Cd=Cd(inext(2):NN);
	            ME=ME(inext(2):NN);
	            moorele=moorele(inext(2):NN,:);
	            U=Utmp;V=Vtmp;W=Wtmp;z=ztmp;rho=rhotmp;
	            disp('!! Top link(s) in mooring removed !!');
	            Z=[];iss=1;
	            dismoor;
	            moordyn;
	            return
	         else
	            error('This mooring''s not working! Solution isn''t converging. Please reduce shear and max speeds');
	         end
	      end
	   end
	end % end loop looking for gamma, fraction of top buoyancy needed in surface solution
   
	if gamma<0, gamma=abs(gamma); end
    if gamma>=1, gamma=1; ss=1; end
   
	if isave >= 20 & (abs(Zf-Zw) < 1), % if it's having problems converging, start a running average when it's close
	   iavg=iavg+1;
	   if iavg==1,
	      Tiavg=Ti;
	      psiavg=psi;
          Zavg=Z;
          Z1(1)=Z(1);
	      Xavg=X;
	      Yavg=Y;
	      gammavg=gamma;
          Uio=Ui;
	   else
	      Tiavg=Tiavg+Ti;
	      psiavg=psiavg+psi;
          Zavg=Zavg+Z;
          Z1(isave)=Z(1);
	      Xavg=Xavg+X;
	      Yavg=Yavg+Y;
          gammavg=gammavg+gamma;
          Z1std=std(Z1);
	   end
   end
   %if iavg > 20 & ss==0 & Z1std > 1, gamma=1; ss=1; end % This is bouncing around, its probably a subsurface solution.
   if iavg > 20, % after 20 avg iterations, start using the average height to assist convergence
      Z=Zavg/iavg; % if solution is "bouncing", then converge faster to average.
      psi=psiavg/iavg;
      % Ui=Ui+(rand(size(Ui))-0.5)/100; % further shake things up by varying the currents ever so slightly
	end
   %
   Zf=Z(1)-Hi(1,1)/2;
   if ss==0&(Zf+gamma*Hi(1,1))>Zw, Z=Z*(Zw/(Zf+gamma*Hi(1,1))); end % force mooring elements to be in water
    icnt=icnt+1;
    if iiprt==0,
       if mod(icnt,ilines)==0,fprintf(1,'.');end
       if icnt>=60*ilines, icnt=0; ilines=ilines+1; fprintf(1,'%8i',isave); disp(' ');end
    end
   if iavg>iprt & ss==1, disp([Z(1) (Z(1)-Z1(isave-1))]); end
	% Note drag on tilted cylinders/wire is Cd(psi)=Cd(0)*sin^3(phi), 
	phix=atan2((Ti.*cos(theta).*sin(psi)),(Ti.*cos(psi)));
	phiy=atan2((Ti.*sin(theta).*sin(psi)),(Ti.*cos(psi)));
    Umag=sqrt(Ui.^2 + Vi.^2 + Wi.^2);
   for j=1:N,      % loop through the interpolated in-line segments and any clamp=on devices
       ico=[];if ~isempty(Iobj),ico=find(Iobj==j); end % If ~isempty(ico), then there is a clamp on device here
	   i=find(zi>(Z(j)-1.0)&zi<(Z(j)+1.0));
       if j==1, 
           i=find(zi>(Z(j)-Hi(1,1)) & zi<(Z(j)+Hi(1,1)));
           if isempty(i), i=1; end % take the top velocity value
       end
	   if isempty(i), 
	      disp([' Check this configuration: ',num2str([j Z(1) Z(j)])]);
	      error(' Can''t find the velocity at this element! Near line 572 of moordyn.m');
	   end
	   i=i(1); % just in case it got more than one value/index
	   if Hi(3,j)==0, % then this is a cylinder/wire/chain section
	      Ax=Hi(1,j)*Hi(2,j)*abs(cos(phix(j))); % area of tilted cylinder/wire/chain
	      Ay=Hi(1,j)*Hi(2,j)*abs(cos(phiy(j))); % area of tilted cylinder/wire/chain
	      Cdjx=Cdi(j)*abs(sin(pi/2-phix(j))^3) + pi*0.01*(1-((pi/2)-phix(j))/(pi/2));
	      Cdjy=Cdi(j)*abs(sin(pi/2-phiy(j))^3) + pi*0.01*(1-((pi/2)-phiy(j))/(pi/2));
	   else % this is a sphere
	      Ax=pi*(Hi(3,j)/2)^2;
	      Ay=Ax;
	      Cdjx=Cdi(j);
	      Cdjy=Cdjx;
      end
      Qxco=0;Qyco=0;
      if ~isempty(ico),
         for icoc=ico,  % loop through if there is more than one clamp-on device here 
         if HCO(3,icoc)==0, % then this is a cylinder device
           Axco=HCO(1,icoc)*HCO(2,icoc)*abs(cos(phix(j))); % area of tilted cylinder/wire/chain
	   	   Ayco=HCO(1,icoc)*HCO(2,icoc)*abs(cos(phiy(j))); % area of tilted cylinder/wire/chain
	   	   Cdjxco=CdCO(icoc)*abs(sin(pi/2-phix(j))^3) + pi*0.01*(1-((pi/2)-phix(j))/(pi/2));
	   	   Cdjyco=CdCO(icoc)*abs(sin(pi/2-phiy(j))^3) + pi*0.01*(1-((pi/2)-phiy(j))/(pi/2));
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
	   Qx(j)=0.5*rhoi(i)*Cdjx*Ax*Umag(i)*Ui(i) + Qxco;
	   Qy(j)=0.5*rhoi(i)*Cdjy*Ay*Umag(i)*Vi(i) + Qyco;
	   if Hi(3,j)==0, % then this is a tilted cylinder device
	      Az=Hi(1,j)*abs(sin(psi(j)))*Hi(2,j) + abs(cos(psi(j)))*pi*(Hi(2,j)/2)^2; % area of tilted cylinder looking up
	      Cdjz=Cdi(j) + pi*0.01*(1-(psi(j)/(pi/2)));
	      Cdjx=(-sign(phix(j)))*(Cdi(j)*sign(cos(phix(j)))*abs(sin(pi/2-phix(j))^3) + pi*0.01*(1-phix(j)/(pi/2))); % these provide lift
	      Cdjy=(-sign(phiy(j)))*(Cdi(j)*sign(cos(phiy(j)))*abs(sin(pi/2-phiy(j))^3) + pi*0.01*(1-phiy(j)/(pi/2))); % lift
	   else % then this is a sphere device
	      Az=pi*(Hi(3,j)/2)^2;
	      Cdjz=Cdi(j);
	      Cdjx=0;Cdjy=0;
      end
      Qzco=0;
      if ~isempty(ico),
        for icoc=ico,
	   	if HCO(3,icoc)==0, % then this is a tilted cylinder/wire/chain section
	   	   Azco=HCO(1,icoc)*abs(sin(psi(j)))*HCO(2,icoc) + abs(cos(psi(j)))*pi*(HCO(2,icoc)/2)^2; % area of tilted cylinder looking up
	   	   Cdjzco=CdCO(icoc) + pi*0.01*(1-(psi(j)/(pi/2)));
	   	   Cdjxco=(-sign(phix(j)))*(CdCO(icoc)*sign(cos(phix(j)))*abs(sin(pi/2-phix(j))^3) + pi*0.01*(1-phix(j)/(pi/2))); % these provide lift
	   	   Cdjyco=(-sign(phiy(j)))*(CdCO(icoc)*sign(cos(phiy(j)))*abs(sin(pi/2-phiy(j))^3) + pi*0.01*(1-phiy(j)/(pi/2))); % lift
	   	else % then this is a sphere
	   	   Azco=pi*(HCO(3,icoc)/2)^2;
	   	   Cdjzco=CdCO(icoc);
	   	   Cdjxco=0;Cdjyco=0;
        end
        Qzco=Qzco + 0.5*rhoi(i)*Azco*Umag(i)*(Cdjzco*Wi(i) + Cdjxco*sin(abs(phix(j)*2))*Ui(i) + Cdjyco*sin(abs(phiy(j)*2))*Vi(i)); 
        end
      end
	   Qz(j)=0.5*rhoi(i)*Az*Umag(i)*(Cdjz*Wi(i) + Cdjx*sin(abs(phix(j)*2))*Ui(i) + Cdjy*sin(abs(phiy(j)*2))*Vi(i)) + Qzco; 
	end
   % Now re-solve for displacements with new positions/drags.
    Ti=[];theta=[];psi=[];
	Ti(1)=0; % no tension above top element.
	b=gamma*(Bi(1)+Qz(1));
	theta(2)=atan2(Qy(1),Qx(1));
	Ti(2)=sqrt(Qx(1)^2 + Qy(1)^2 + b^2);
	if gamma < 1, % for surface float, just use submerged drag and buoysncy.
	   Ti(2)=sqrt((gamma*Qx(1))^2 + (gamma*Qy(1))^2 + b^2);
	end
   %
	psi(2)=acos(b/Ti(2));  % tilt at the top of the second element (wire)
	psi(1)=psi(2);         % is equal to the tilt of the entire top object. 
	theta(1)=theta(2);     % For sphere floatation objects, this changes nothing.
   % Now Solve from top (just under float) to bottom (top of anchor).
   for Zii0=1:2,
		for i=2:N-1,
      	ico=[];if ~isempty(Iobj),ico=find(Iobj==i);end % If ~isempty(ico), then there is a clamp on device here
	   	ip1=i+1;
	   	xx=Qx(i)+Ti(i)*cos(theta(i))*sin(psi(i));
	   	yy=Qy(i)+Ti(i)*sin(theta(i))*sin(psi(i));
        zz=Bi(i)+Qz(i)+Ti(i)*cos(psi(i));
        if ~isempty(ico), zz=zz+sum(BwCO(ico)); end % add buoyancy of clamp-on devices
	   	theta(ip1)=atan2(yy,xx);
	   	Ti(ip1)=sqrt(xx^2 + yy^2 + zz^2);
	   	if Ti(ip1) ~= 0,
	   	   psi(ip1)=acos(zz/Ti(ip1));
	   	else
	   	   psi(ip1)=psi(i);  % this is unlikely , but just in case
	   	end
      end
	%
	% Now integrate from the bottom to the top to get the second order [x,y,z]
	% Allow wire/rope to stretch under tension
    %
   	  X=[];Y=[];Z=[]; % re-initialize
	  X(N)=0;Y(N)=0;Z(N)=Hi(1,N);  % reference things to top of anchor.
      Zii=1;iint=0;
      while Zii, % can't have any of the mooring above water or below bottom
         Zii=0;  % just integrate once, unless there is slack line, then repeat to lay it out.
         S=0;SS=0;
         dx0=0;dy0=0;dz0=0;
         iint=iint+1;
		 for i=N-1:-1:1,  % i decreases from N (anchor) to 1, float.
			   if Hi(2,i)~=0 & MEi(i)<Inf,
			      dL=1+(Ti(i)*4/(pi*Hi(2,i)^2*MEi(i)));  % allow for stretching of wire/rope
			   else
			      dL=1;
               end
               LpdL=Hi(1,i)*dL;
               S=S+LpdL;  % sum the length of the mooring as check
			   dX = LpdL*cos(theta(i))*sin(psi(i));
			   dY = LpdL*sin(theta(i))*sin(psi(i));
               dZ = LpdL*cos(psi(i));
               SS = SS+sqrt(dX^2+dY^2+dZ^2);
			   X(i)=X(i+1) + dX/2 + dx0/2;
			   Y(i)=Y(i+1) + dY/2 + dy0/2;
			   Z(i)=Z(i+1) + dZ/2 + dz0/2;
			   if Z(i) > Zw & Hi(4,i) == 1 & Bi(i) >= 0,  % force line to lie on surface
                  Zii=1;Z(i)=Zw;
			      psi(i)=pi/2; 
               end
		       if Z(i) <= 0, % force line to lie on anchor/bottom
			      Zii=1;
			      psi(i)=pi/2; 
			   end
			   dx0=dX;dy0=dY;dz0=dZ;
         end
         if iint>4, Zii=0; end % after three interations, exit loop
         % The last position is to the center of the float (thus don't add dx0, dy0 and dz0)
      end
      psi(N)=psi(N-1);
   end
   Zf=Z(1)-Hi(1,1)/2;
   if max(Z)>Zw & ss==1, ss=0; gamma=sqrt(gamma); end % this may be a surface mooring after all 
	%
	%
	if isave > 2, % must do at least three iterations to check convergence
      if abs(Zsave(isave-1)-Z(1)) < deltaz & abs(Zsave(isave-2)-Zsave(isave-1)) < deltaz, % 2 close calls...
	      if ss==1 & Zw>(Zf+Hi(1,1)) & gamma==1, % this is a sub-surface (ss) solution
	         breaknow=1; % then the solution has converged.
	      else % this may be a surface solution
	         if ss==0 & Zw>Zf & Zw<(Zf+Hi(1,1)) & abs(((Zw-Zf)/Hi(1,1))-gamma) < 0.01, % we're within 1%.
	            breaknow=1; % then the surface solution has converged
	         end
	      end
	   end
	   if iavg == 120 | (iavg > 100 & dg < 1e-10), % after many iterations, assume converged!
	      X=Xavg/iavg;
	      Y=Yavg/iavg;
	      Z=Zavg/iavg;
	      Ti=Tiavg/iavg;
	      psi=psiavg/iavg;
         breaknow=1;
         iconv=1;
	   end
	end
   Zsave(isave)=Z(1);
   %
   if rem(isave,100), deltaz=2*deltaz; end % if it still doesn't converge, slacken the threshold
   %
end % end convergence/while loop
if izloop==1; % this is just the first time thro, to get the un-forced vertical case
   Zoo=Z;
   if ~isempty(ZCO), % then we've got clamp-on devices, and we need to find the initial height for them
      mmco=length(ZCO);
      for jco=1:mmco, % Iobj is interpolated index for clamp-ons, PIobj is percentage UP segment
         Z0co(jco)=Z(Iobj(jco)) + (cos(psi(Iobj(jco)))*(0.5-PIobj(jco))*Hi(1,Iobj(jco)));
      end
   end
end
end % end the izloop to get vertical displacements for zero and desired current cases
% if there are clamp-on device, figure out there position.
if ~isempty(ZCO), % then we've got clamp-on devices, and we need to find the positions of them
      for jco=1:length(ZCO),  % Iobj now from top to bottom, shifted from center of segment
         Xfco(jco)=X(Iobj(jco)) + cos(theta(Iobj(jco)))*sin(psi(Iobj(jco)))*(0.5-PIobj(jco))*Hi(1,Iobj(jco));
         Yfco(jco)=Y(Iobj(jco)) + sin(theta(Iobj(jco)))*sin(psi(Iobj(jco)))*(0.5-PIobj(jco))*Hi(1,Iobj(jco));
         Zfco(jco)=Z(Iobj(jco)) + cos(psi(Iobj(jco)))*(0.5-PIobj(jco))*Hi(1,Iobj(jco));
         psifco(jco)=psi(Iobj(jco));
      end
end
%
if iconv & ss==0, % adjust heights slightly
   zcorr=(Zw - Hi(1,1)*gamma + (Hi(1,1)/2)) - Z(1);
   if abs(zcorr)>0.01, % need to be a little closer then 10 cm!
   	Z10=Z(1);
   	for ico=1:length(Z),
      	Z(ico)=Z(ico) + abs(Z(ico)/Z10)*zcorr; % make depth correction if assumed convergence
      end
   end
end
I=(2:N-1);
%
iobj0=find(H(4,:) ~=1); % save the original element names for these non-wire/rope components
nnum1=num2str([1:length(iobj0)]','%4.0f');
nnum1(:,end+1)=' ';
nnum2=num2str(iobj0','%4.0f');
nnum2(:,end+1)=' ';
iEle=[nnum1,nnum2,moorele(iobj0,:)];
if ~isempty(ZCO),
	Iobj0=find(HCO(4,:) ~=1); % save the original element names for these non-wire/rope components
	nnum1=num2str([1:length(Iobj0)]','%4.0f');
	nnum1(:,end+1)=' ';
	nnum2=num2str(Iobj0','%4.0f');
	nnum2(:,end+1)=' ';
   IEle=[nnum1,nnum2,mooreleCO(Iobj0,:)]; % make a list of the clamp-on deivces
end

%
iobj=find(Hi(4,:) ~=1); % indices of the non-wire/rope elements
jobj=1+find(Hi(4,I) == 1 & (Hi(4,I-1) ~= 1|Hi(4,I+1) ~= 1)); % indices of wire/rope/chain elements
ba=psi(N-1);
Wa=Ti(N)/9.81;
VWa=Wa*cos(ba);
HWa=Wa*sin(ba);
WoB=(Bi(N)+Qz(N)+Ti(N))/9.81; % weight under anchor
disp('  ');
if gamma >= 0.99 | ss==1, 
   disp('This is a sub-surface solution.');
else
   disp(['This is a surface solution, using ',num2str(gamma*100,2),'% of the surface buoyancy.']);
end % NOTE: The calculation of % of surface float used assumes a cylinder float.
%           In otherwords, the % submerged = the percent buoyancy (not so for a shpere).  
%
disp(['Total Tension on Anchor [kg] = ',num2str(Wa,'%8.1f')]);
disp(['Vertical load [kg] = ',num2str(VWa,'%8.1f'),'  Horizontal load [kg] = ',num2str(HWa,'%8.1f')]);
% disp(['After applying a WHOI saftey factor:']);
TWa=1.5*(VWa + HWa/0.6);
disp(['Safe wet anchor mass = ',num2str(TWa,'%8.1f'),' [kg] = ',num2str((TWa*2.2),'%8.1f'),' [lb]']);
disp(['Safe dry steel anchor mass = ',num2str((TWa/0.87),'%8.1f'),' [kg] = ',num2str((TWa*2.2/0.87),'%8.1f'),' [lb]']);
disp(['Safe dry concrete anchor mass = ',num2str((TWa/0.65),'%8.1f'),' [kg] = ',num2str((TWa*2.2/0.65),'%8.1f'),' [lb]']);
disp(['Weight under anchor = ',num2str(WoB,'%8.1f'),' [kg]  (negative is down)']);
%
if abs(B(end)) < TWa,
   disp('*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*');
   disp('*!*!*!*  Warning. Anchor is likely TOO light!   *!*!*!*')
   disp('*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*');
end
%disp([S SS]); % display the summed length of mooring as a check...
% reset original current profile.
z=ztmp;U=Utmp;V=Vtmp;W=Wtmp;rho=rhotmp;
% fini
