function mdplot(command)
% function to (update) the mooring plot
global H B Cd moorele
global Ht Bt Cdt MEt moorelet Usp Vsp DD
global U V W z rho uw vw time
global X Y Z iobj figs
global psi theta im1
global ZCO BCO HCO Jobj Pobj Z0co Zfco Xfco Yfco psifco
global h_edit_angle h_edit_elevation h_edit_plttitle h_edit_timemd
global its itplt Us Vs Ws rhos iss
global Iobj
global fs
global HWa ba ha wpm xair yair lgth

im1=[];iss=[];
if isempty(U),
   U=[0 0 0]';V=U;W=U;
   if isempty(Ht), % then a mooring
      z=fix(sum(H(1,:))*[1.2 0.2 0]'); % height
   else
      z=fix(sum(Ht(1,:))*[0 0.2 1.2]'); % depth
   end
   if isempty(rho), rho=[1024 1025 1026]'; end
else
   [mu,nu]=size(U);
   if mu==1 & nu>1,
      U=U';V=V';W=W';z=z';rho=rho';
   end
end
if ~isempty(Ht),
   if max(z)<= sum(Ht(1,:)), % then we need to extend (deepen) the velocity profile
      z(end)=sum(Ht(1,:))*1.2;
   end
end
if isempty(its), its=1; end
if nargin == 0, command=0; end
if command == 0,
	load('splash.mat'); % let's have a bit of fun. "Ok Cap'n, moorings away!"
	sound(wavedata/8000,samplingrate,16);
	clear wavedata samplingrate
end
if (~isempty(H) & ~isempty(B) & ~isempty(Cd))|(~isempty(Ht) & ~isempty(Bt) & ~isempty(Cdt)),
if command == 0 | command>=20,
   if command==0, clear X Y Z iobj; end
   [mu,nu]=size(U);
   if nu>1, % then ask for time
      if its==1 & command~=21,
         if isempty(h_edit_timemd),
         	tmin=min(time);tmax=max(time);
  				figure(4);close(4);figure(4);clf
  				set(gcf,'Units', 'Normalized',...
  				    'Position',[.05 .2 .3 .15],...
  				    'Name','Select Time',...
  				    'Color',[.8 .8 .8],...
         	    'tag','mdtplt');
         	tplot1=uicontrol('Style','text',...
  				    'String','Start:End Times','FontSize',fs,...
  				    'Units','normalized',...
   			   'Position',[.1 .7 .4 .25]);
   			h_str_time=uicontrol('Style','text',...
      			'String',num2str([tmin tmax]),'FontSize',fs,...
      			'Units','Normalized',...
      			'Position',[.6 .7 .35 .25]);
         	tplot2=uicontrol('Style','text',...
  				    'String','Edit Time:','FontSize',fs,...
  				    'Units','normalized',...
   			   'Position',[.1 .35 .4 .25]);
         	h_edit_timemd=uicontrol('Style','edit',...
         	   'Callback','mdplot(20)','FontSize',fs,...
      			'String',num2str(tmin),...
      			'Units','Normalized',...
      			'Position',[.6 .35 .35 .25]);
   			h_push_ok=uicontrol('Style','Pushbutton',...
      			'String','OK','FontSize',fs,...
      			'Units','normalized',...
      			'Position',[.35 .02 .3 .2],...
               'Callback','mdplot(20)');
            return
         else
            timemd=str2num(get(h_edit_timemd,'String'));
            dt=time-timemd;
            its=find(min(abs(dt))==abs(dt));
            figure(4);close(4);
            h_edit_timemd=[];
            mdplot(21);
         end
      else
         if isempty(Ht), % then this is a regular mooring
         	Us=U;Vs=V;Ws=W;%rhos=rho;
         	if its>nu | its<1, its=1; end % just in case its got screwed up
         	U=Us(:,its);V=Vs(:,its);W=Ws(:,its);%rho=rhos(:,its);
         	itplt=its;
            [X,Y,Z,iobj]=moordyn;
         	U=Us;V=Vs;W=Ws;%rho=rhos; %Reset things after a requested time
         	clear Us Vs Ws
            its=1;
         else % then this is a towed body
         	Us=U;Vs=V;Ws=W;%rhos=rho;
         	if its>nu | its<1, its=1; end % just in case its got screwed up
         	U=Us(:,its);V=Vs(:,its);W=Ws(:,its);%rho=rhos(:,its);
            itplt=its;
         	[X,Y,Z,iobj]=towdyn;
         	U=Us;V=Vs;W=Ws;%rho=rhos; %Reset things after a requested time
         	clear Us Vs Ws
            its=1;
         end
         
      end
   else
      if isempty(Ht), % then this is a regular mooring
         [X,Y Z,iobj]=moordyn;
      else % then it's a towed body
			%
         if DD>0, % then we've set the desired depth, adjust wire length
            ish=0;idp=0;Htavg=0; % after a few, start using the average wire length
			   iwl=find(Ht(4,:)==1); % find index to first wire piece, that will be adjusted
			   iwl=iwl(end); % index of the first wire piece. Lengthen/shorten this to get desired depth (DD)
            [X,Y,Z,iobj]=towdyn; % first pass with short section (hanging)
            ibreakDD=1;icnt=0;
            while ibreakDD,
               if ~isempty(im1),
                  iend=im1-1;
               else
                  iend=length(Z);
               end
               %
               icnt=icnt+1;
               if abs(Z(1)-DD) > Ht(1,1)/2, % keep looking until with half body height
                  if Z(1) < DD, % then the towed body is too shallow, lengthen wire
                     Ht(1,iwl)=Ht(1,iwl) + abs(abs(Z(1)-DD)/cos(psi(iend)));
                     if icnt > 2,
	                     ish=ish+1;
   	                  Htavg=Htavg + Ht(1,iwl);
                        if ish>2 & idp>2, Ht(1,iwl)=Htavg/(ish+idp); end
                     end
                  else % the top is above the surface, shorten wire length
                     Ht(1,iwl)=Ht(1,iwl) - abs(abs(Z(1)-DD)/cos(psi(iend)));
                     if icnt > 2,
                     	idp=idp+1;
                     	Htavg=Htavg + Ht(1,iwl);
                        if ish>2 & idp>2, Ht(1,iwl)=Htavg/(ish+idp); end
                     end
                  end
                  %
		            [X,Y,Z,iobj]=towdyn;
               	%figure(9);plot3(X,Y,-Z);hold on
               else
                  ibreakDD=0;
               end
            end % while
         else
	         [X,Y,Z,iobj]=towdyn;
			end
			%
      end
   end
   figure(3);clf;hold on
   if isempty(Ht),
   	set(gcf,'Units', 'Normalized',...
   	   'Position',[.4 .3 .5 .6],...
   	   'Name','The Mooring',...
   	   'tag','mdplot');
   	plot3(X,Y,Z,'b');hold on;
   	li=length(iobj);
   	plot3(X(iobj(2:li-1)),Y(iobj(2:li-1)),Z(iobj(2:li-1)),'or',...
   	   'Markersize',5,'Clipping','off');
   	plot3(X(iobj(1)),Y(iobj(1)),Z(iobj(1)),'or',...
   	   'Markersize',10,'MarkerFaceColor','r','Clipping','off');
   	plot3(X(iobj(li)),Y(iobj(li)),Z(iobj(li)),'^b',...
   	   'Markersize',8,'MarkerFaceColor','b','Clipping','off');
   	if ~isempty(BCO), % then there are clamp-on devices
   	   plot3(Xfco,Yfco,Zfco,'om',...
   	      'Markersize',5,'Clipping','off');
   	end
   	grid;box on;axis equal;
   	xlabel('X [m]');
   	ylabel('Y [m]');
   	zlabel('Z [m]');
   	if isempty(time) | isempty(itplt),
   	   title('Mooring Design and Dynamics');
   	   else
   	   title(['Mooring Forced by Currents at ',num2str(time(itplt))])
   	end
   	zm=get(gca,'ZLim');
      xm=get(gca,'XLim')*1.2;
   	set(gca,'XLim',xm);
   	ym=get(gca,'YLim')*1.2;
   	set(gca,'YLim',ym);
   	if min(xm)>-10, xm(1)=-10; end
   	if max(xm)< 10, xm(2)=10; end
   	set(gca,'XLim',xm);
   	if min(ym)>-10, ym(1)=-10; end
   	if max(ym)< 10, ym(2)=10; end
   	set(gca,'YLim',ym);
   	if abs(max(Z)-max(z)) < 50, % then plot the ocean surface/waves
   	   zm=max(z);
   	   xm=get(gca,'XLim');ym=get(gca,'YLim');
   	   swx=[min(xm):diff(xm)/10:max(xm)];
   	   swzx=(zm+0.75)-sqrt(1+sin(swx));
   	   swy=[min(ym):diff(xm)/10:max(ym)];
   	   swzy=(zm+0.75)-sqrt(1+sin(swy));
   	   box off;
   	   plot3(max(xm)*ones(size(swy)),swy,swzy,'b','Clipping','off');
   	   plot3(min(xm)*ones(size(swy)),swy,swzy,'b','Clipping','off');
   	   plot3(swx,max(ym)*ones(size(swx)),swzx,'b','Clipping','off');
   	   plot3(swx,min(ym)*ones(size(swx)),swzx,'b','Clipping','off');
   	   axis([xm(1) xm(2) ym(1) ym(2) 0 zm]);
      end
      ha=pi;
   else
   	set(gcf,'Units', 'Normalized',...
   	   'Position',[.4 .3 .5 .6],...
   	   'Name','The Towed Body',...
         'tag','mdplot');
      boat; % draw a ship
      tlgth=lgth+sum(Ht(1,2:end));
      disp([' Length of wire from Water surface to A-frame: ',num2str(lgth,'%7.2f'),'[m]']);
      disp([' Total length of wire from A-frame to towed body: ',num2str(tlgth,'%7.2f'),'[m]']);
      X=X+xair;Y=Y+yair;Xfco=Xfco+xair;Yfco=Yfco+yair;
   	plot3(X,Y,-Z,'b');hold on;
   	li=length(iobj);
   	plot3(X(iobj(2:li-1)),Y(iobj(2:li-1)),-Z(iobj(2:li-1)),'or',...
   	   'Markersize',5,'Clipping','off');
   	plot3(X(iobj(1)),Y(iobj(1)),-Z(iobj(1)),'or',...
   	   'Markersize',10,'MarkerFaceColor','r','Clipping','off');
   	if ~isempty(BCO), % then there are clamp-on devices
   	   plot3(Xfco,Yfco,-Zfco,'om',...
   	      'Markersize',5,'Clipping','off');
   	end
      grid on;
      axis equal;
   	xlabel('X [m]');
   	ylabel('Y [m]');
   	zlabel('Z [m]');
   	if isempty(time)&isempty(itplt),
   	   title('Mooring Design and Dynamics Towed Body');
   	   else
   	   title(['Towed Body at ',num2str(time(itplt))])
   	end
   	xm=get(gca,'XLim')*1.2;
   	set(gca,'XLim',xm);
   	ym=get(gca,'YLim')*1.2;
   	set(gca,'YLim',ym);
   	if min(xm)>-10, xm(1)=-10; end
   	if max(xm)< 10, xm(2)=10; end
   	set(gca,'XLim',xm);
   	if min(ym)>-10, ym(1)=-10; end
   	if max(ym)< 10, ym(2)=10; end
      set(gca,'YLim',ym);
      % plot ocean waves
   	zm=0;
   	xm=get(gca,'XLim');ym=get(gca,'YLim');
   	swx=[min(xm):0.2:max(xm)];
   	swzx=(zm+0.75)-sqrt(1+sin(swx));
   	swy=[min(ym):0.2:max(ym)];
   	swzy=(zm+0.75)-sqrt(1+sin(swy));
   	box off;
   	plot3(max(xm)*ones(size(swy)),swy,swzy,'b','Clipping','off');
   	plot3(min(xm)*ones(size(swy)),swy,swzy,'b','Clipping','off');
   	plot3(swx,max(ym)*ones(size(swx)),swzx,'b','Clipping','off');
   	plot3(swx,min(ym)*ones(size(swx)),swzx,'b','Clipping','off');
      %axis([xm(1) xm(2) ym(1) ym(2) 30 max(Z)*(-1.2)]);
   end
   view(fix((ha-pi)*180/pi+20),10);
   drawnow;
   [az,el]=view;
   
   figure(4);clf
   set(gcf,'Units', 'Normalized',...
      'Position',[.05 .02 .325 .275],...
      'Name','Modify Plot',...
      'Color',[.8 .8 .8],...
      'tag','mdmodplt');
   tplot1=uicontrol('Style','text',...
      'String','3D View Angle: AZ','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .8 .55 .125]);
   h_edit_angle=uicontrol('Style','edit',...
      'Callback','mdplot(1)',...
      'String',num2str(az),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .8 .2 .125]);
   tplot2=uicontrol('Style','text',...
      'String','3D View Elevation: EL','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .6 .55 .125]);
   h_edit_elevation=uicontrol('Style','edit',...
      'Callback','mdplot(2)',...
      'String',num2str(el),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .6 .2 .125]);
   tplot3=uicontrol('Style','text',...
      'String','Plot Title','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .4 .2 .125]);
   h_edit_plttitle=uicontrol('Style','edit',...
      'Callback','mdplot(3)',...
      'String','Mooring Design and Dynamics','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.35 .4 .6 .125]);
   if isempty(Ht),
   h_push_pltuvw=uicontrol('Style','Pushbutton',...
      'String','Plot Velocity Profiles','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .2 .4 .125],...
      'Callback','mdplot(4)');
   end
   h_push_rotate=uicontrol('Style','Pushbutton',...
      'String','Rotate3D','FontSize',fs,...
      'Units','normalized',...
      'Position',[.6 .2 .3 .125],...
      'Callback','mdplot(6)');
   h_push_print=uicontrol('Style','Pushbutton',...
      'String','Print','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .02 .3 .125],...
      'Callback','mdplot(5)');
   h_push_cls=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.6 .02 .3 .125],...
      'Callback','mdplot(7)');

elseif command == 1 | command == 2,
   figure(3);axis normal
   az=str2num(get(h_edit_angle,'String'));
   el=str2num(get(h_edit_elevation,'String'));
   view(az,el);
   axis equal
elseif command == 3,
   figure(3);axis normal
   title(get(h_edit_plttitle,'String'));
   axis equal
elseif command == 4,
   if isempty(itplt), itplt=1; end;
   % Add 2% of wind speed to top current (10m) value
   ztmp=z;Utmp=U;Vtmp=V;
   if (z(1)-z(2)) > 10.01 & (uw^2+vw^2)>0,
     mu=length(z);
     z(3:mu+1)=z(2:mu);
     z(2)=z(1)-10;
     U(3:mu+1,itplt)=U(2:mu,itplt);
     U(2,its)=U(1,its);
     V(3:mu+1,itplt)=V(2:mu,itplt);
     V(2,itplt)=V(1,itplt);
   end
   U(1,itplt)=U(1,itplt)+uw;
   V(1,itplt)=V(1,itplt)+vw;
%
   figure(3);clf;axis normal
   plot3(X,Y,Z,'b');hold on;
   li=length(iobj);
   plot3(X(iobj(2:li-1)),Y(iobj(2:li-1)),Z(iobj(2:li-1)),'or',...
      'Markersize',5,'Clipping','off');
   plot3(X(iobj(1)),Y(iobj(1)),Z(iobj(1)),'or',...
      'Markersize',10,'MarkerFaceColor','r','Clipping','off');
   plot3(X(iobj(li)),Y(iobj(li)),Z(iobj(li)),'^b',...
      'Markersize',8,'MarkerFaceColor','b','Clipping','off');
   if ~isempty(BCO), % then there are clamp-on devices
      plot3(Xfco,Yfco,Zfco,'om',...
         'Markersize',5,'Clipping','off');
   end
   grid;box on;axis equal;
   xlabel('X [m]');
   ylabel('Y [m]');
   zlabel('Z [m]');
   if isempty(time),
      title('Mooring Forced by Currents');
      else
      title(['Mooring Forced by Currents at ',num2str(time(itplt))])
   end
   xlim=get(gca,'XLim')*1.2;
   ylim=get(gca,'YLim')*1.2;
   if min(xlim)>-10, xlim(1)=-10; end
   if max(xlim)< 10, xlim(2)=10; end
   set(gca,'XLim',xlim);
   if min(ylim)>-10, ylim(1)=-10; end
   if max(ylim)< 10, ylim(2)=10; end
   set(gca,'YLim',ylim);
   zlim=get(gca,'ZLim');
   xmax1=max(xlim);
   ymax1=max(ylim);
   zmax1=max(abs(zlim));
   if max(abs(U(:,itplt)))~=0,
      up=xmax1*U(:,itplt)/(max(abs(U(:,itplt)))); %Normalize the velocittes
   else
      up=zeros(size(z));
   end
   up=up(:);
   if max(abs(V(:,itplt))) ~=0, 
      vp=ymax1*V(:,itplt)/(max(abs(V(:,itplt))));
   else
      vp=zeros(size(z));
   end
   vp=vp(:);
   if ~isempty(up),
      hup=plot3(up,ymax1*ones(size(up)),z,'g');
      set(hup,'Color',[0 0.5 0]);
   end
   if ~isempty(vp),
      hvp=plot3(xmax1*ones(size(vp)),vp,z,'m');
   end
   axis equal
   zlim=get(gca,'ZLim');
   zmax1=max(abs(zlim));
   if ~isempty(up),
      umax=max(abs(U(:,itplt)));
      hut=text(xmax1*1.1,ymax1,zmax1,['|Umax|=',num2str(umax),' m/s']);
      set(hut,'Color',[0 0.5 0],'FontSize',8);
   end
   if ~isempty(vp),
      vmax=max(abs(V(:,itplt)));
      hvt=text(xmax1*1.1,0,zmax1-zmax1*0.05,['|Vmax|=',num2str(vmax),' m/s']);
      set(hvt,'Color','m','FontSize',8);
   end
   if abs(max(Z)-max(z)) < 50, 
      zm=max(z);
      swx=[min(xlim):0.2:max(xlim)];
      swzx=(zm+0.75)-sqrt(1+sin(swx));
      swy=[min(ylim):0.2:max(ylim)];
      swzy=(zm+0.75)-sqrt(1+sin(swy));
      box off;
      plot3(max(xlim)*ones(size(swy)),swy,swzy,'b','Clipping','off');
      plot3(min(xlim)*ones(size(swy)),swy,swzy,'b','Clipping','off');
      plot3(swx,max(ylim)*ones(size(swx)),swzx,'b','Clipping','off');
      plot3(swx,min(ylim)*ones(size(swx)),swzx,'b','Clipping','off');
      axis([xlim(1) xlim(2) ylim(1) ylim(2) 0 zm]);
   end

   drawnow;
   z=ztmp;U=Utmp;V=Vtmp;
elseif command == 5,
   figure(3);
   print -f3 -v
elseif command == 6,
   figure(3);
   rotate3d
   help rotate3d
elseif command ==7,
   close(3);
   close(4);
end
else
   disp(' Must load or enter a mooring before evaluation/plotting. ');
end
moordesign(0);
% fini
