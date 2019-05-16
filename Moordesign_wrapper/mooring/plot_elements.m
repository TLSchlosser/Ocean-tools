function plot_elements(command)
% function plot_elements(command)
% Plot the mooring and label the components
% command = 0 to plot to screen
% command = 1 to send plot to printer
% RKD 5/98 as part of Mooring Design and Dynamics 

global moorele H
global HCO mooreleCO BCO ZCO Jobj Pobj elco hghtt
global th el chainf

if nargin==0,
   command=0;
end
[mh,nh]=size(H);

figure(5);close(5);figure(5);
set(5,'Units','Normalized','Position',[0.525 0.1 .45 .8],'Visible','on');
dates=num2str(fix(clock),'%3.0f');dates(8)='/';dates([14 17])=':';
tit=['Mooring Design and Dynamics  ',dates];
fs=10;
%
[ifile,ipath]=uigetfile('*.mat','Load Database file MDCODES.MAT (cancel loads default)');
if ischar(ifile) & ischar(ipath),
   load ([ipath ifile]);
  elseif ifile == 0 & ipath == 0,
   load mdcodes.mat
end
%
th=0;
tht=0;
realhgt=sum(H(1,:));
ich=find(H(4,:)==1 | H(4,:)==2);  % indecise of wire/rope and shackles
lengthch=sum(H(1,ich));
chainf=20; % plot chain/wire at 10% of real length,
if realhgt < 20 & lengthch>(0.1*realhgt), chainf=1; end % if shallow mooring, don't reduce
if realhgt > 100, chainf=10; end % reduce to 5% for deep moorings
if realhgt > 500, chainf=50; end % reduce to 5% for deep moorings
if realhgt > 1000, chainf=100; end % reduce to 5% for deep moorings
if realhgt > 2000, chainf=200; end % reduce to 5% for deep moorings

for i=nh:-1:1,
   if H(4,i)~=1,
      th=th+H(1,i);  % sum mooring height
      h(i)=th-H(1,i)/2;	% height to middle of this element
   else
      th=th+H(1,i)/chainf; % but use only fraction of wire/rope lengths
      h(i)=th-(H(1,i)/chainf)/2;  % height to middle of this wire
   end
   tht=tht+H(1,i);
   ha(i)=tht;
end
axis([-th/8 th/1.6 0 th]);
axis off
orient tall
htx=title(tit);
pos=get(htx,'Position');
set(htx,'Position',[pos(1) pos(2)*1.02 pos(3)],'Fontname','Courier','FontSize',fs*1.2);
hdr1='Mooring Element Length[m] Height[m]';
htx=text(th/6,th,hdr1);
set(htx,'FontName','Courier','FontSize',fs);
hold on
%      123456789112345678921234567893';
line0='0                            ';
%
for el=1:nh,
   line=line0;
   line(1:16)=moorele(el,1:16);
   tmp=num2str(H(1,el),'%8.2f');
   line(25-length(tmp):24)=tmp;
   tmp=num2str(ha(el),'%8.2f');
   line(33-length(tmp):32)=tmp;
   id=0;
   [ne,le]=size(acrels);
   for ie=1:ne,
      if strcmp(line(1:16),acrels(ie,1:16)), % check acoustic releases
         id=ie;
      end
   end
   if id==0,
      [ne,le]=size(anchors);
      for ie=1:ne,
         if strcmp(line(1:16),anchors(ie,1:16)), % check anchors
            id=ie;
         end
      end
   else % then the element is an acoustic release
      pltrelease;
      id=0;
   end
   if id==0,
      [ne,le]=size(chains);
      for ie=1:ne,
         if strcmp(line(1:16),chains(ie,1:16)), % check chains/shackles
            id=ie;
         end
      end
   else % then the element is an anchor
      pltanchor;
      id=0;
   end
   if id==0,
      [ne,le]=size(cms);
      for ie=1:ne,
         if strcmp(line(1:16),cms(ie,1:16)), % check current meters
            id=ie;
         end
      end
   else % then the element is a section of chain
      pltchain;
      id=0;
   end
   if id==0,
      [ne,le]=size(floats);
      for ie=1:ne,
         if strcmp(line(1:16),floats(ie,1:16)), % check floatation
            id=ie;
         end
      end
   else % then the element is a current meter
      pltcm;
      id=0;
   end
   if id==0,
      [ne,le]=size(miscs);
      for ie=1:ne,
         if strcmp(line(1:16),miscs(ie,1:16)), % check miscs
            id=ie;
         end
      end
   else % then the element is a float
      pltfloat;
      id=0;
   end
   if id==0,
      [ne,le]=size(wires);
      for ie=1:ne,
         if strcmp(line(1:16),wires(ie,1:16)),  % check wires/ropes
            id=ie;
         end
      end
      if id~=0, pltwire; id=0; end % if it found it, it's a section of wire
   else % then the element is a misc instrument
      pltmisc;
      id=0;
   end
   % now plot the name/type of element
   if H(4,el)~=1 & H(4,el)~=2, % don't lable wire/rope or chain/shackles
      htx=text(th/6,h(el),line);
      set(htx,'FontName','Courier','FontSize',fs);
   end
end
if ~isempty(BCO), % then we've got some clamp-on devices to plot
   for elco=1:length(BCO),
	   line=line0;
      line(1:16)=mooreleCO(elco,1:16);
   	tmp=num2str(HCO(1,elco),'%8.2f');
   	line(25-length(tmp):24)=tmp;
   	tmp=num2str(ZCO(elco),'%8.2f');
      line(33-length(tmp):32)=tmp;
      if H(4,Jobj(elco))~=1, 
         hghtt=h(Jobj(elco)) - H(1,Jobj(elco))/2 + Pobj(elco)*H(1,Jobj(elco));
      else
         hghtt=h(Jobj(elco)) - H(1,Jobj(elco))/(2*chainf) + Pobj(elco)*(H(1,Jobj(elco))/chainf);
      end
      htx=text(th/6,hghtt,line);
      set(htx,'FontName','Courier','FontSize',fs);
      pltco
   end
end
%
if command==1,
   figure(5);
   unis = get(gcf,'units');
   ppos = get(gcf,'paperposition');
   set(gcf,'units',get(gcf,'paperunits'));
   pos  = get(gcf,'position');
   pos(3:4) = ppos(3:4);
   set(gcf,'position',pos);
   set(gcf,'units',unis);
   print -f5;
   close(5);
end

% fini
