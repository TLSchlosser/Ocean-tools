function modmoorCO(command,parameter)
% Program to make a GUI for add/modifying clamp-on devices

global U V W z rho
global H B Cd ME moorele Z
global HCO BCO CdCO mooreleCO ZCO Iobj Jobj Pobj
global floats wires chains acrels cms anchors miscs format typelist type list 
global handle_listCO insertCO heightCO val elenumCO
global fs
global Zoo

if nargin == 0 | command <= 0,
   if command == -1 | isempty(BCO),  % then initialize arrays
      HCO=[];BCO=[];CdCO=[];
      mooreleCO='1234567890123456';
      handle_listCO=[];
   elseif command == 0,
      if ~isempty(BCO),
         elenumCO=length(BCO)+1;
         deleleCO=0;
         heightCO=0;
      end
   end
   typelist=' ';list=' ';
   command=0;
end 
Z=[]; % assume that some change has occurd to the mooring, and re-search for all solutions
Zoo=[]; 
if ~isempty(handle_listCO), 
      h_edit_elenumCO = handle_listCO(1);
      h_edit_deleleCO = handle_listCO(2);
      h_menu_typeCO = handle_listCO(3);
      h_menu_listCO = handle_listCO(4);
      h_edit_heightCO = handle_listCO(5);
end 
%
if isempty(floats), load mdcodes; end 
%
if command == 0,  % then initialize the menus/number
   elenumCO=length(BCO)+1;
   deleleCO=0;
   heightCO=0;
   list=floats;
   type=1;
   [me,ne]=size(list);
   for ii=1:me
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   figure(2);clf;
   set(gcf,'Units', 'Normalized',...
      'Position',[.05 .05 .25 .275],...
      'Name','Modify Clamp-On Devices',...
      'Color',[.8 .8 .8],...
      'tag','modmoorCO');
   telenum=uicontrol('Style','text',...
      'String','Element to Clamp-On','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .88 .55 .1]);
   h_edit_elenumCO=uicontrol('Style','edit',...
      'Callback','modmoorCO(1)',...
      'String',num2str(elenumCO),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .88 .2 .1]);
   teleins=uicontrol('Style','text',...
      'String','Delete Clamp-On Element','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .76 .55 .1]);
   h_edit_deleleCO=uicontrol('Style','edit',...
      'Callback','modmoorCO(2)',...
      'String',num2str(deleleCO),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .76 .2 .1]);
   h_menu_typeCO=uicontrol('Style','popupmenu',...
      'Callback','modmoorCO(3)','FontSize',fs,...
      'String',['Floatation|Current Meter|Misc Instrument'],...
      'Units','Normalized',...
      'Position',[.1 .64 .8 .1]);
   h_menu_listCO=uicontrol('Style','popupmenu',...
      'Callback','modmoorCO(4)',...
      'String',typelist,'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.1 .52 .8 .1]);
   telehght=uicontrol('Style','text',...
      'String','Height Above Bottom [m]','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .4 .55 .1]);
   h_edit_heightCO=uicontrol('Style','edit',...
      'Callback','modmoorCO(11)',...
      'String',num2str(heightCO),'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.7 .4 .2 .1]);
   h_push_file=uicontrol('Style','pushbutton',...
      'Callback','modmoorCO(88)',...
      'String','Load Different Database','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.25 .27 .5 .1]);
   h_push_disp=uicontrol('Style','pushbutton',...
      'Callback','dismoor',...
      'String','Display Elements','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.075 .15 .4 .1]);
   h_push_update=uicontrol('Style','Pushbutton',...
      'String','Execute Update','FontSize',fs,...
      'Units','normalized',...
      'Position',[.525 .15 .4 .1],...
      'Callback','modmoorCO(5)');
   hmaincls=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.3 .02 .4 .1],...
      'Callback','modmoorCO(6)');
   
	handle_listCO = [ h_edit_elenumCO ... 
      h_edit_deleleCO ...
      h_menu_typeCO ...
      h_menu_listCO ...
   	h_edit_heightCO]; 

	set(gcf,'userdata',handle_listCO); % just another place to store it
   insertCO=0;
elseif command == 88,
      [ifile,ipath]=uigetfile('*.mat','Load Database File MDCODES.MAT (cancel loads default)');
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
      modmoorCO(0);
elseif command == 1, % insert an element
   insertCO=str2num(get(h_edit_elenumCO,'String'));
elseif command == 11, % edit the height above the bottom
   heightCO=str2num(get(h_edit_heightCO,'String'));
elseif command == 2, % delete an element
   deleleCO=str2num(get(h_edit_deleleCO,'String'));
   mb=length(BCO);
   if deleleCO <= mb,  % then we'll remove element number delele
      if deleleCO == 1,
         if mb>1,
            BCO=BCO(2:mb);
            HCO=HCO(:,2:mb);
            CdCO=CdCO(2:mb);
            ZCO=ZCO(2:mb);
            mooreleCO=mooreleCO(2:mb,:);
         else
            BCO=[];HCO=[];CdCO=[];ZCO=[];mooreleCO=[];
         end
      elseif deleleCO == mb,
         BCO=BCO(1:(mb-1));
         HCO=HCO(:,1:(mb-1));
         CdCO=CdCO(1:(mb-1));
         ZCO=ZCO(1:(mb-1));
         mooreleCO=mooreleCO(1:(mb-1),:);
      elseif deleleCO > 1 & deleleCO < mb,
         inew=[1:deleleCO-1 deleleCO+1:mb];
         BCO=BCO(inew);
         HCO=HCO(:,inew);
         CdCO=CdCO(inew);
         ZCO=ZCO(inew);
         mooreleCO=mooreleCO(inew,:);
      end
      Iojb=[];Jobj=[];Pobj=[];
   	mmCO=length(BCO);
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
      % re-set the next value to input.
      elenumCO=length(BCO)+1;
      if elenumCO <= 0, elenumCO=1; end
      deleleCO=0;
      set(h_edit_elenumCO,'String',num2str(elenumCO));
      set(h_edit_deleleCO,'String',num2str(deleleCO));
      dismoor
   end
   insertCO=0;
elseif command == 3, % select a new type on mooring element and list
   clear typelist
   type=get(h_menu_typeCO,'Value');
   if type == 1,
      list=floats;   % for clamp-on devices, I've only allowed three categories
   elseif type == 2,
      list=cms;
   elseif type == 3,
      list=miscs;
   end
   [me,ne]=size(list);
   for ii=1:me
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   set(h_menu_listCO,'Value',1);
   set(h_menu_listCO,'String',typelist);
elseif command == 4, % select an element from the list and add or insert it
   %ZCO=[];
   val=get(h_menu_listCO,'Value');
   % set BCO,HCO,CdCO here for new element number elenum
   elenumCO=str2num(get(h_edit_elenumCO,'String'));
elseif command == 5,
   if heightCO==0 & elenumCO > length(BCO),
      disp('You must set the height of the device (>0).');
      return
   end
   % complete the operation
   if insertCO ~= 0 & elenumCO <= length(BCO), % then we're inserting an element, bump rest
      mb=length(BCO);
      bump=[insertCO+1:mb+1];
      mooreleCO(bump,:)=mooreleCO(elenumCO:mb,:);
      BCO(bump)=BCO(elenumCO:mb);
      HCO(:,bump)=HCO(:,elenumCO:mb);
      CdCO(bump)=CdCO(elenumCO:mb);
      ZCO(bump)=ZCO(elenumCO:mb);
   end
   mooreleCO(elenumCO,:)=list(val,format(1,1):format(1,2));
   BCO(elenumCO)=str2num(list(val,format(2,1):format(2,2)));
   HCO(1,elenumCO)=str2num(list(val,format(3,1):format(3,2)))/100; % convert to metres
   HCO(2,elenumCO)=str2num(list(val,format(4,1):format(4,2)))/100;
   HCO(3,elenumCO)=str2num(list(val,format(5,1):format(5,2)))/100;
   HCO(4,elenumCO)=0;
   CdCO(elenumCO)=str2num(list(val,format(6,1):format(6,2)));
   ZCO(elenumCO)=heightCO;
   elenum0=elenumCO;
   elenumCO=length(BCO)+1;
   set(h_edit_elenumCO,'String',num2str(elenumCO));
   insertCO=0;elenumCO=length(BCO)+1;
   if HCO(1,elenum0) == 0,
      set(h_edit_deleleCO,'String',num2str(elenum0));
      modmoorCO(2);
   end
   mmCO=length(BCO);
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
   dismoor;
elseif command == 6, % Now figure out where on the mooring this is.
   close(2);
   moordesign(3);
end
% fini
