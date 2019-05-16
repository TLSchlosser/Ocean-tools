function modtow(command,parameter)
% Program to make a GUI for modifying a towed body design
% For a towed body, the Surface is the reference and
% the "mooring" solution is turned up-side-down by setting
% d=-z and B=-B.
% So a sinking body, is made buoyant, towed upside down, then flipped back.
% RKD 3/00

global Ht Bt Cdt MEt moorelet Usp Vsp afh
global H B Cd ME moorele
global floats wires chains acrels cms anchors miscs format typelist type list
global handle_list wire_length h_edit_wirel insert elenum delele val chele
global Z Zoo
global fs

if nargin == 0 | command <= 0, % intialize everything
   if command == -1,
   	handle_list=[];
      Ht=[];Bt=[];Cdt=[];
      moorelet='1234567890123456';
      Ht=[];Bt=[];Cdt=[];MEt=[];moorelet=[];X=[];Y=[];Z=[];Zoo=[];
      H=[];B=[];Cd=[];ME=[];moorele=[];
      Usp=0;Vsp=0;afh=0;
   elseif command == 0,
      if ~isempty(Bt),
         elenum=length(Bt)+1;
         delele=0;
         dismoor;
      end
   end
   typelist=' ';
   list=' ';
   command=0;
end 
Z=[]; % assume we're going to change things, and wipe out any previous solution
Zoo=[];
if ~isempty(handle_list), 
      h_edit_elenum = handle_list(1);
      h_edit_delele = handle_list(2);
      h_menu_type = handle_list(3);
      h_menu_list = handle_list(4);
      h_edit_shsp = handle_list(5);
      h_edit_afh = handle_list(6);
      if length(handle_list)>6, h_edit_chele = handle_list(7); end
end 
%
if isempty(typelist) | strcmp(typelist,' '), load mdcodes; end 
%
if command == 0,  % then initiale the menus/number
   if isempty(elenum),
     elenum=1;
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
      'Position',[.02 .05 .3 .4],...
      'Name','Modify Towed Body Configureation',...
      'Color',[.8 .8 .8],...
      'tag','modtow');
   telenum=uicontrol('Style','text',...
      'String','Element to Add/Insert: Bottom-to-Top','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .9 .65 .07]);
   h_edit_elenum=uicontrol('Style','edit',...
      'Callback','modtow(1)',...
      'String',num2str(elenum),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.8 .9 .1 .07]);
   teleins=uicontrol('Style','text',...
      'String','Delete Element Number','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .8 .65 .07]);
   h_edit_delele=uicontrol('Style','edit',...
      'Callback','modtow(2)',...
      'String',num2str(delele),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.8 .8 .1 .07]);
   h_push_file=uicontrol('Style','pushbutton',...
      'Callback','modtow(88)',...
      'String','Load Different Database','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.25 .7 .5 .07]);
   h_menu_type=uicontrol('Style','popupmenu',...
      'Callback','modtow(3)','FontSize',fs,...
      'String',['Floatation|Wire|Chain+Shackles|Current Meter|Misc Instrument'],...
      'Units','Normalized',...
      'Position',[.1 .575 .8 .1]);
   h_menu_list=uicontrol('Style','popupmenu',...
      'Callback','modtow(4)',...
      'String',typelist,'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.1 .5 .8 .1]);
   if ~isempty(Ht),
   if ~isempty(find(Ht(4,:)==1)),
      indxw=find(Ht(4,:)==1);
      if isempty(chele), chele=indxw(1); end
   	h_push_chlength=uicontrol('Style','pushbutton',...
      	'Callback','modtow(9)',...
      	'String','Change Length of Wire Element #','FontSize',fs,...
      	'Units','Normalized',...
      	'Position',[.05 .435 .7 .07]);
   	h_edit_chele=uicontrol('Style','edit',...
      	'Callback','modtow(8)',...
      	'String',num2str(chele),'FontSize',fs,...
      	'Units','Normalized',...
         'Position',[.8 .435 .1 .07]);
   else
      h_edit_chele=99999; % fake handle number
   end
   end
   tshsp=uicontrol('Style','text',...
      'String','Enter Ship Velocity [U V] (m/s)','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .33 .6 .07]);
   h_edit_shsp=uicontrol('Style','edit',...
      'Callback','modtow(5)',...
      'String',num2str([Usp Vsp]),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .33 .2 .07]);
   tafh=uicontrol('Style','text',...
      'String','Height of A-Frame Block Above Water (m)','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .22 .7 .07]);
   h_edit_afh=uicontrol('Style','edit',...
      'Callback','modtow(6)',...
      'String',num2str(afh),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.8 .22 .1 .07]);
   h_push_update=uicontrol('Style','pushbutton',...
      'Callback','modtow(7)',...
      'String','Execute Add-Insert-Delete Operation','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.1 .11 .8 .07]);
   h_push_disp=uicontrol('Style','pushbutton',...
      'Callback','dismoor',...
      'String','Display Elements','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.075 .02 .4 .07]);
   hmaincls=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.525 .02 .4 .07],...
      'Callback','modtow(90)');  
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
      modtow(0);
elseif command == 1, % insert an element
   insert=str2num(get(h_edit_elenum,'String'));
   elenum=str2num(get(h_edit_elenum,'String'));
   delele=0;
elseif command == 2, % delete an element
   delele=str2num(get(h_edit_delele,'String'));
   insert=0;
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
   elseif type == 5
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
   if type >= 2 & type <= 3, % then get the length of wire/rope/chain
      if str2num(list(val,format(3,1):format(3,2)))/100==1,
      	getwirel;
         waitfor(h_edit_wirel); % wait for this window(4) to close
      end
   end
elseif command==5, % update the ship velocities
   UVsp=str2num(get(h_edit_shsp,'String'));
   Usp=UVsp(1);Vsp=UVsp(2);
elseif command==6, % update the height of the A-frame block above water
   afh=str2num(get(h_edit_afh,'String'));
elseif command==7, % execute the update
   Z=[]; % things are a chaning, so remove any previous solution
   if delele ~= 0 & insert == 0, % then we're deleteing an element
   	mb=length(Bt);
   	if delele <= mb,  % then we'll remove element number delele
   	   if delele == 1,
   	      if mb>1,
   	         Bt=Bt(2:mb);
   	         Ht=Ht(:,2:mb);
   	         Cdt=Cdt(2:mb);
   	         moorelet=moorelet(2:mb,:);
   	      else
   	         Bt=[];Ht=[];Cdt=[];moorelet=[];
   	      end
   	   elseif delele == mb,
   	      Bt=Bt(1:(mb-1));
   	      Ht=Ht(:,1:(mb-1));
   	      Cdt=Cdt(1:(mb-1));
   	      moorelet=moorelet(1:(mb-1),:);
   	   elseif delele>1 & delele<mb,
   	      inew=[1:delele-1 delele+1:mb];
   	      Bt=Bt(inew);
   	      Ht=Ht(:,inew);
   	      Cdt=Cdt(inew);
   	      moorelet=moorelet(inew,:);
   	   end
   	   % re-set the next value to input.
   	   elenum=length(Bt)+1;
   	   if elenum<=0,elenum=1;end
   	   delele=0;
   	   set(h_edit_elenum,'String',num2str(elenum));
   	   set(h_edit_delele,'String',num2str(delele));
         dismoor;
      end
   else % we're inserting or adding to the end
   % add or insert an element
   	if insert ~= 0 & elenum <= length(Bt), % then we're inserting an element, bump rest
   		   mb=length(Bt);
   		   bump=[insert+1:mb+1];
   		   moorelet(bump,:)=moorelet(elenum:mb,:);
   		   Bt(bump)=Bt(elenum:mb);
   		   Ht(:,bump)=Ht(:,elenum:mb);
   		   Cdt(bump)=Cdt(elenum:mb);
   		   MEt(bump)=MEt(elenum:mb);
   	end
   	moorelet(elenum,:)=list(val,format(1,1):format(1,2));
   	Bt(elenum)=str2num(list(val,format(2,1):format(2,2)));
   	Ht(1,elenum)=str2num(list(val,format(3,1):format(3,2)))/100; % convert to metres
   	Ht(2,elenum)=str2num(list(val,format(4,1):format(4,2)))/100;
   	Ht(3,elenum)=str2num(list(val,format(5,1):format(5,2)))/100;
   	Ht(4,elenum)=0;
   	MEt(elenum)=inf;  % by default set modulus of elasticity to infinity (no stretch)
   	if type == 2 | type == 3, % then a wire/chain element, get length
   	   if Ht(1,elenum)==1,
   	      Ht(1,elenum)=wire_length;
   	      Ht(4,elenum)=1; % flag for wire/chain elements, sub-divide later
   	      mat=str2num(list(val,format(7,1):format(7,2)));
   	      if mat==1, % steel
   	         MEt(elenum)=1.38e11;
   	      elseif mat==2, % Nylon
   	         MEt(elenum)=3.45e8;
   	      elseif mat==3, % Dacron
   	         MEt(elenum)=6.9e8;
   	      elseif mat==4, % Polypropylene
   	         MEt(elenum)=3.45e8;
   	      elseif mat==5, % Polyethylene
   	         MEt(elenum)=6.9e8;
   	      elseif mat==6, % Kevlar
    		MEt(elenum)=6.9e10;
    	      elseif mat==7, % Aluminum
    	        MEt(elenum)=7.6e10;
    	      elseif mat==8, % Dyneema
    	        MEt(elenum)=1.0e11;
    	      end
    	   else
    		   Ht(4,elenum)=2; % flag for shackles and joiners
    		end
   	end
   	Cdt(elenum)=str2num(list(val,format(6,1):format(6,2)));
   	elenum=length(Bt)+1;
   	set(h_edit_elenum,'String',num2str(elenum));
   end
   dismoor;
   insert=0;
   delele=0;
elseif command==8, % update the element number of the wire piece to change the length
   chele=str2num(get(h_edit_chele,'String'));
elseif command==9, % get and change the wire length
   if ~isempty(chele),
      if chele <= length(Ht(1,:)),
   		wire_length=Ht(1,chele);
         getwirel;
      	waitfor(h_edit_wirel); % wait for this window(4) to close
         Ht(1,chele)=wire_length;
      end
   end
elseif command ==90, % display and plot current affected mooring.
   close(2);
   if ~isempty(Ht),dismoor;end
   moordesign(3);
end
if exist('h_edit_chele'),
   handle_list=[ h_edit_elenum h_edit_delele h_menu_type h_menu_list h_edit_shsp h_edit_afh h_edit_chele]; 
else
   handle_list=[ h_edit_elenum h_edit_delele h_menu_type h_menu_list h_edit_shsp h_edit_afh]; 
end
% fini
