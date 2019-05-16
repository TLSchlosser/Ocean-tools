function globalchange(command,parameter)
% Program for modifying all of one type of mooring component

global U V W z rho
global H B Cd ME moorele Z
global floats wires chains acrels cms anchors miscs format 
global handle_list2 typelist2 type2 list2 elenum2 complist2
global change comp moortally components
global fs

if isempty(moorele),
   disp('You must have a mooring loaded to modify.')
   return
end

if command~=0, 
      h_menu_elenum2 = handle_list2(1);
      h_menu_type2 = handle_list2(2);
      h_menu_list2 = handle_list2(3);
end 

if command==0,
[mm,mn]=size(moorele);
if mm>1,
   icnt=1;
   moortally(icnt,1:2)=[1 1];
   components='1234567890123456';
   comp=components;
   typelist2=comp;
   list2=comp;
   for el=2:mm,
      icnt0=icnt;
      ifound=0;
      for j=1:icnt0,
         if strcmp(moorele(moortally(j,1),:),moorele(el,:))==1,
            moortally(j,2)=moortally(j,2)+1; % sum the # of these
            ifound=1;
         end
      end
      if ifound==0,
            icnt=icnt+1;
            moortally(icnt,1:2)=[el,1]; % this the first of this type
		end
   end
   moortally=moortally(1:icnt,:);
   [mt,nt]=size(moortally);
   for i=1:mt,
      components(i,:)=moorele(moortally(i,1),:);
   end
   [me,ne]=size(components);
   for ii=1:me
       complist(((ii-1)*17+1):((ii-1)*17+17))=[components(ii,1:16),'|'];
   end
   complist=complist(1:length(complist)-1);
else
   disp('There is only one element. Use the Modify Mooring routine.');
   return
end
end

%
if command == 0,  % then initialize the menus/numbers
   if ~exist('elen'),
      elenum2=1;
      change=0;
   end
   comp=components(elenum2,:);
   list2=floats;
   type2=1;
   [me,ne]=size(list2);
   for ii=1:me
       typelist2(((ii-1)*17+1):((ii-1)*17+17))=[list2(ii,1:16),'|'];
   end
   typelist2=typelist2(1:length(typelist2)-1);
   figure(3);clf;
   set(gcf,'Units', 'Normalized',...
      'Position',[.325 .05 .3 .2],...
      'Name','Global Change of Component',...
      'Color',[.8 .8 .8],...
      'tag','globalchange');
   title1=uicontrol('Style','text',...
      'String','Change All','FontSize',fs,...
      'Units','normalized',...
      'Position',[.1 .8 .35 .125]);
   h_menu_elenum2=uicontrol('Style','popupmenu',...
      'Callback','globalchange(1)',...
      'String',complist,'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.5 .8 .45 .125]);
   titleto=uicontrol('Style','text',...
      'String','To','FontSize',fs,...
      'Units','normalized',...
      'Position',[.425 .625 .1 .125]);
   title2=uicontrol('Style','text',...
      'String','Type','FontSize',fs,...
      'Units','normalized',...
      'Position',[.2 .5 .2 .125]);
   h_menu_type2=uicontrol('Style','popupmenu',...
      'Callback','globalchange(2)','FontSize',fs,...
      'String',['Floatation|Wire|Chain+Shackles|Current Meter|Acoustic Release|Anchor|Misc Instrument'],...
      'Units','Normalized',...
      'Position',[.1 .3 .35 .125]);
   title3=uicontrol('Style','text',...
      'String','Component','FontSize',fs,...
      'Units','normalized',...
      'Position',[.55 .5 .3 .125]);
   h_menu_list2=uicontrol('Style','popupmenu',...
      'Callback','globalchange(3)',...
      'String',typelist2,'FontSize',fs,...
      'Units','Normalized',...
      'Position',[.5 .3 .45 .125]);
   h_push_change=uicontrol('Style','pushbutton',...
      'Callback','globalchange(4)',...
      'String','Change','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.1 .1 .2 .125]);
   h_push_disp=uicontrol('Style','pushbutton',...
      'Callback','dismoor',...
      'String','Display Elements','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.325 .1 .35 .125]);
   h_close_change=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.7 .1 .2 .125],...
      'Callback','globalchange(6)');
    set(gcf,'userdata',handle_list2); % just another place to store stuff
elseif command == 1, % select a component to globally replace
   elenum2=get(h_menu_elenum2,'Value');
   complist2='1234567890123456'; % initialize as string
   complist2=components(elenum2,:);
elseif command == 2, % select a new type of mooring element and list
   clear typelist2
   type2=get(h_menu_type2,'Value');
   if type2 == 1,
      list2=floats;
   elseif type2 == 2,
      list2=wires;
   elseif type2 == 3,
      list2=chains;
   elseif type2 == 4,
      list2=cms;
   elseif type2 == 5,
      list2=acrels;
   elseif type2 == 6,
      list2=anchors;
   elseif type2 == 7
      list2=miscs;
   end
   [me,ne]=size(list2);
   for ii=1:me
       typelist2(((ii-1)*17+1):((ii-1)*17+17))=[list2(ii,1:16),'|'];
   end
   typelist2=typelist2(1:length(typelist2));
   set(h_menu_list2,'Value',1);
   set(h_menu_list2,'String',typelist2);
elseif command == 3, % select an element from the list and get ready to globally replace
   change=get(h_menu_list2,'Value');
elseif command == 4, % select an element from the list and add or insert it
   if change < 1 | strcmp('12345',complist2(1:5)), 
      disp('You must select an item, even it is the default value displayed.'); 
      break;
   end
   %
   % Need to find all element componets to replace, replace them
   %
   [mm,mn]=size(moorele);
   icnt=0;
   for iele=1:mm
      if strcmp(complist2,moorele(iele,:)),
         icnt=icnt+1;
         ele(icnt)=iele;
      end
   end
   disp([' I will be replaceing ',num2str(icnt),' occurances of ',complist2]);      
   disp([' with ',num2str(icnt),' occurances of ',list2(change,format(1,1):format(1,2))]);      
   for elen=ele,
   moorele(elen,:)=list2(change,format(1,1):format(1,2));
   B(elen)=str2num(list2(change,format(2,1):format(2,2)));
   Hsave=H;
   H(1,elen)=str2num(list2(change,format(3,1):format(3,2)))/100; % convert to metres
   H(2,elen)=str2num(list2(change,format(4,1):format(4,2)))/100;
   H(3,elen)=str2num(list2(change,format(5,1):format(5,2)))/100;
   H(4,elen)=0;
   ME(elen)=inf;  % by default set modulus of elasticity to infinity (no stretch)
   if type2 == 2 | type2 == 3, % then a wire/chain element, get length
      if H(1,elen)==1,
         H(1,elen)=Hsave(1,elen); % use oold wire/rope length
         H(4,elen)=1; % flag for wire/chain elements, sub-divide later
         mat=str2num(list2(change,format(7,1):format(7,2)));
         if mat==1, % steel
            ME(elen)=1.38e11;
         elseif mat==2, % Nylon
            ME(elen)=3.45e8;
         elseif mat==3, % Dacron
            ME(elen)=6.9e8;
         elseif mat==4, % Polyprop
            ME(elen)=3.45e8;
         elseif mat==5, % Polyethy
            ME(elen)=6.9e8;
         elseif mat==6, % Kevlar
            ME(elen)=6.9e10;
         elseif mat==7, % Aluminum
            ME(elen)=7.6e10;
         elseif mat==8, % Dyneema
            ME(elen)=1.0e11;
         end
      else
         H(4,elen)=2; % flag for shackles and joiners
      end
   end
   Cd(elen)=str2num(list2(change,format(6,1):format(6,2)));
   end % for loop elenum=ele,
   disp('Done.');
   dismoor;
   close(3);
   modmoor(0);
elseif command ==5, % display and plot current affected mooring.
   dismoor;
elseif command==6,
   close(3);
   modmoor(0);
end
handle_list2 = [ h_menu_elenum2 ... 
				     h_menu_type2 ...
    				  h_menu_list2 ]; 
% fini
