function modmoor(command,parameter)
% Program to make a GUI for modifying a mooring design

global U V W z rho
global H B Cd ME moorele
global Ht Bt Cdt MEt moorelet
global BCO ZCO Jobj Pobj
global floats wires chains acrels cms anchors miscs format typelist type list
global handle_list wire_length h_edit_wirel insert elenum delele val
global Z Zoo
global fs

if nargin == 0 | command <= 0,
   if command == -1,
      H=[];B=[];Cd=[];ME=[];moorele=[];X=[];Y=[];Z=[];Zoo=[];
      Ht=[];Bt=[];Cdt=[];MEt=[];moorelet=[];
      moorele='1234567890123456';
      handle_list=[];
   elseif command == 0,
      if ~isempty(B),
         elenum=length(B)+1;
         delele=0;
         dismoor;
      end
   end
   elenum=length(B)+1;
   typelist=' ';
   list=' ';
   command=0;
end 
Z=[]; % assume that some change has occurd to the mooring, and re-search for all solutions
Zoo=[]; 
if ~isempty(handle_list), 
      h_edit_elenum = handle_list(1);
      h_edit_delele = handle_list(2);
      h_menu_type = handle_list(3);
      h_menu_list = handle_list(4);
end 
%
if isempty(typelist)|strcmp(typelist,[' ']), load mdcodes; end 
%
if command == 0,  % then initiale the menus/number
   if isempty(elenum),
     elenum=length(B)+1;
     delele=0;
   end
   list=floats;
   type=1;
   [me,ne]=size(list);
   for ii=1:me
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   figure(2);clf;
   set(gcf,'Units', 'Normalized',...
      'Position',[.05 .05 .25 .3],...
      'Name','Modify Mooring Design',...
      'Color',[.8 .8 .8],...
      'tag','modmoor');
   telenum=uicontrol('Style','text',...
      'String','Element to Add/Insert','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .89 .55 .1]);
   h_edit_elenum=uicontrol('Style','edit',...
      'Callback','modmoor(1)',...
      'String',num2str(elenum),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .89 .2 .1]);
   teleins=uicontrol('Style','text',...
      'String','Delete Element','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .77 .55 .1]);
   h_edit_delele=uicontrol('Style','edit',...
      'Callback','modmoor(2)',...
      'String',num2str(delele),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .77 .2 .1]);
   h_push_file=uicontrol('Style','pushbutton',...
      'Callback','modmoor(88)',...
      'String','Load Different Database','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.25 .65 .5 0.1]);
   h_menu_type=uicontrol('Style','popupmenu',...
      'Callback','modmoor(3)','FontSize',fs,...
      'String',['Floatation|Wire|Chain+Shackles|Current Meter|Acoustic Release|Anchor|Misc Instrument'],...
      'Units','Normalized',...
      'Position',[.1 .5 .8 .12]);
   h_menu_list=uicontrol('Style','popupmenu',...
      'Callback','modmoor(4)',...
      'String',typelist,'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.1 .37 .8 .12]);
   h_push_update=uicontrol('Style','pushbutton',...
      'Callback','modmoor(44)',...
      'String','Execute Update','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.3 .275 .4 .1]);
   h_push_disp=uicontrol('Style','pushbutton',...
      'Callback','dismoor',...
      'String','Display Elements','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.075 .15 .4 .1]);
   h_push_change=uicontrol('Style','pushbutton',...
      'Callback','globalchange(0)',...
      'String','Global Replace','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.525 .15 .4 .1]);
   hmaincls=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.3 .02 .4 .1],...
      'Callback','modmoor(6)');
   
handle_list = [ h_edit_elenum ... 
      h_edit_delele ...
      h_menu_type ...
      h_menu_list ]; 

    set(gcf,'userdata',handle_list); % just another place to store i
    insert=0;
elseif command == 88,
      [ifile,ipath]=uigetfile('*.mat','Load Database file MDCODES.MAT (cancel loads default)');
      if ischar(ifile) & ischar(ipath),
         if ~strcmp(ifile,'*.mat'),
            load([ipath ifile]);
         else
            load mdcodes  % load default file (should be in path
         end
      elseif ifile == 0 & ipath == 0,
            load mdcodes
      end
      clear ifile ipath
      modmoor(0);
elseif command == 1, % insert an element
   insert=str2num(get(h_edit_elenum,'String'));
   delele=0;
elseif command == 2, % delete an element
   delele=str2num(get(h_edit_delele,'String'));
elseif command == 3, % select a new type on mooring element and list
   clear typelist
   type=get(h_menu_type,'Value');
   if type == 1,
      list=floats;
   elseif type == 2,
      list=wires;
   elseif type == 3,
      list=chains;
   elseif type == 4,
      list=cms;
   elseif type == 5,
      list=acrels;
   elseif type == 6,
      list=anchors;
   elseif type == 7
      list=miscs;
   end
   [me,ne]=size(list);
   for ii=1:me
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   set(h_menu_list,'Value',1);
   set(h_menu_list,'String',typelist);
elseif command == 4, % select an element from the list and add or insert it
   val=get(h_menu_list,'Value');
   % set B,H,Cd here for new element number elenum
   elenum=str2num(get(h_edit_elenum,'String'));
   delele=0;
elseif command == 44, % execute this update
   if delele > 0, % then the action is to delete an element
      Z=[];
      disp('Hello!');
	   mb=length(B);
	   if delele <= mb,  % then we'll remove element number delele
   	   if delele == 1,
      	   if mb>1,
      	      B=B(2:mb);
      	      H=H(:,2:mb);
      	      Cd=Cd(2:mb);
      	      moorele=moorele(2:mb,:);
              ME=ME(2:mb); %JHJH
      	   else
      	      B=[];H=[];Cd=[];moorele=[];
              ME=[]; %JHJH
      	   end
      	elseif delele == mb,
      	   B=B(1:(mb-1));
      	   H=H(:,1:(mb-1));
      	   Cd=Cd(1:(mb-1));
      	   moorele=moorele(1:(mb-1),:);
           ME=ME(1:(mb-1)); %JHJH
      	elseif delele>1 & delele<mb,
      	   inew=[1:delele-1 delele+1:mb];
      	   B=B(inew);
      	   H=H(:,inew);
      	   Cd=Cd(inew);
      	   moorele=moorele(inew,:);
           ME=ME(inew); %JHJH
      	end
      	% re-set the next value to input.
      	elenum=length(B)+1;
      	if elenum<=0,elenum=1;end
      	delele=0;
      	set(h_edit_elenum,'String',num2str(elenum));
      	set(h_edit_delele,'String',num2str(delele));
   	end
	   insert=0;
   else
	   if insert ~= 0 & elenum <= length(B), % then we're inserting an element, bump rest
	      mb=length(B);
	      bump=[insert+1:mb+1];
	      moorele(bump,:)=moorele(elenum:mb,:);
	      B(bump)=B(elenum:mb);
	      H(:,bump)=H(:,elenum:mb);
	      Cd(bump)=Cd(elenum:mb);
		  ME(bump)=ME(elenum:mb);
   	end
  	moorele(elenum,:)=list(val,format(1,1):format(1,2));
  	B(elenum)=str2num(list(val,format(2,1):format(2,2)));
   	H(1,elenum)=str2num(list(val,format(3,1):format(3,2)))/100; % convert to metres
   	H(2,elenum)=str2num(list(val,format(4,1):format(4,2)))/100;
   	H(3,elenum)=str2num(list(val,format(5,1):format(5,2)))/100;
   	H(4,elenum)=0;
   	ME(elenum)=inf;  % by default set modulus of elasticity to infinity (no stretch)
   	if type == 2 | type == 3, % then a wire/chain element, get length
   	   if H(1,elenum)==1,
   	      getwirel;waitfor(h_edit_wirel); % wait for this window(4) to close
   	      H(1,elenum)=wire_length;
   	      H(4,elenum)=1; % flag for wire/chain elements, sub-divide later
   	      mat=str2num(list(val,format(7,1):format(7,2)));
   	      if mat==1, % steel
   	         ME(elenum)=1.38e11;
   	      elseif mat==2, % Nylon
   	         ME(elenum)=3.45e8;
   	      elseif mat==3, % Dacron
   	         ME(elenum)=8.0e8;
   	      elseif mat==4, % Polyprop
   	         ME(elenum)=3.45e8;
   	      elseif mat==5, % Polyethy
   	         ME(elenum)=6.9e8;
   	      elseif mat==6, % Kevlar
   	         ME(elenum)=6.9e10;
   	      elseif mat==7, % Aluminum
   	         ME(elenum)=7.6e10;
   	      elseif mat==8, % Dyneema
   	         ME(elenum)=1.0e11;
   	      end
   	   else
   	      H(4,elenum)=2; % flag for shackles and joiners
   	   end
   	end
   	Cd(elenum)=str2num(list(val,format(6,1):format(6,2)));
   	elenum0=elenum;
   	elenum=length(B)+1;
   	set(h_edit_elenum,'String',num2str(elenum));
   	insert=0;
   	if H(1,elenum0) == 0,
   	   set(h_edit_delele,'String',num2str(elenum0));
   	   modmoor(2);
      end
      delele=0;
   end
 	dismoor;
elseif command ==6, % display and plot current affected mooring.
% if this mooring has been modified, and there are clamp-on devices, 
% then we must re-determine their location
	mmCO=length(BCO);
	if mmCO>0,
	  	mm=length(B);
	  	for ico=1:mmCO,
	  	   for i=1:mm-1,
	  	      if ZCO(ico)<sum(H(1,i:mm)) & ZCO(ico)>=sum(H(1,(i+1):mm)),
	  	         Jobj(ico)=i; % moorele object onto which we've clamped
	  	         dz=ZCO(ico)-sum(H(1,(i+1):mm));
	  	         Pobj(ico)=dz/H(1,i); % percentage of length along Jobj where we've clamped.
	  	         i=mm-1;
		  	      end
  		   end
  		end
	end
   close(2);
   moordesign(3);
end
% fini
