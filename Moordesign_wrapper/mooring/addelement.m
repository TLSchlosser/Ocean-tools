function addelement(command);
% Program to make a GUI for modifying a mooring element in the database

global U V W z rho
global H B Cd ME moorele
global floats wires chains acrels cms anchors miscs format
global typelist type list addel mat
global h_menu_type h_menu_list h_menu_addel h_menu_material
global h_push_add h_edit_elename h_edit_elebuoy h_edit_eledim h_edit_elecd
global fs
%
if nargin < 1, command=0; end
if isempty(addel), addel=1; end
if command == 0,  % then initialize the menus/number
   if isempty(floats),
      [ifile,ipath]=uigetfile('*.mat','Load MDCODES.MAT (cancel loads default)');
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
   end
   list=floats;
   type=1;
   typelist='*';
   [me,ne]=size(list);
   for ii=1:me,
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   figure(4);clf;
   set(gcf,'Units', 'Normalized',...
      'Position',[.05 .02 .35 .4],...
      'Name','Add/Delete Elements',...
      'Color',[.8 .8 .8],...
      'tag','modmoor');
   h_menu_type=uicontrol('Style','popupmenu',...
      'Callback','addelement(1)','FontSize',fs,...
      'String',['Floatation|Wire|Chain+Shackles|Current Meter|Acoustic Release|Anchor|Misc Instrument'],...
      'Units','Normalized',...
      'Position',[.1 .875 .8 .1]);
   h_menu_list=uicontrol('Style','popupmenu',...
      'Callback','addelement(2)','FontSize',fs,...
      'String',typelist,...
      'Units','Normalized',...
      'Position',[.1 .785 .8 .1]);
   h_menu_addel=uicontrol('Style','popupmenu',...
      'Callback','addelement(2)','FontSize',fs,...
      'String','Examine|Add Element|Delete Element|Modify Element',...
      'Units','Normalized',...
      'Position',[.3 .695 .4 .1]);
   h_text_ele=uicontrol('Style','text',...
      'String','Element Name(16):','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.05 .6 .3 .08]);
   h_edit_elename=uicontrol('Style','edit',...
      'String',' ','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.45 .6 .5 .08]);
   h_text_elebuoy=uicontrol('Style','text',...
      'String','Buoyancy [kg]','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.05 .51 .3 .08]);
   h_edit_elebuoy=uicontrol('Style','edit',...
      'String',' ','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.45 .51 .5 .08]);
   h_text_eledim=uicontrol('Style','text',...
      'String','Dimensions [cm]','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.05 .42 .3 .08]);
   h_edit_eledim=uicontrol('Style','edit',...
      'String',' ','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.45 .42 .5 .08]);
   h_text_elecd=uicontrol('Style','text',...
      'String','Drag Coeff:','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.05 .33 .3 .08]);
   h_edit_elecd=uicontrol('Style','edit',...
      'String',' ','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.45 .33 .5 .08]);
   h_text_material=uicontrol('Style','text',...
      'String','Material','FontSize',fs,...
      'Units','Normalized',...
      'Position',[.05 .22 .3 .08]);
   h_menu_material=uicontrol('Style','popupmenu',...
      'Callback','addelement(3)','FontSize',fs,...
      'String',['Steel|Nylon|Dacron|Polypropylene|Polyethylene|Kevlar|Aluminum|Dyneema'],...
      'Units','Normalized',...
      'Position',[.45 .22 .4 .08]);
   h_push_help=uicontrol('Style','Pushbutton',...
      'String','Help','FontSize',fs,...
      'Units','normalized',...
      'Position',[.4 .1 .2 .08],...
      'Callback','addelement(7)');
   h_push_save=uicontrol('Style','Pushbutton',...
      'String','Save','FontSize',fs,...
      'Units','normalized',...
      'Position',[.75 .1 .2 .08],...
      'Callback','addelement(6)');   
   hmaincls=uicontrol('Style','Pushbutton',...
      'String','Close','FontSize',fs,...
      'Units','normalized',...
      'Position',[.3 .01 .4 .08],...
      'Callback','close');
end
if command == 2,
   addel=get(h_menu_addel,'Value'); % either 1 (add), 2 (delete) or 3 (modify)
end
if command==1 | command==2,
   if addel == 1,
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','No Action','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(1)'); 
   elseif addel == 2,
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','Add','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(4)');
   elseif addel == 3,
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','Delete','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(5)');
   elseif addel == 4,
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','Modify','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(8)');
   end
end
if command == 1, % Update the type of element
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
   for ii=1:me,
       typelist(((ii-1)*17+1):((ii-1)*17+17))=[list(ii,1:16),'|'];
   end
   typelist=typelist(1:length(typelist)-1);
   set(h_menu_list,'Value',1);
   set(h_menu_list,'String',typelist);
elseif command == 3,
   mat=get(h_menu_material,'Value');
elseif command == 4,
   if addel == 2, % just an additional check/confirmation
   name=get(h_edit_elename,'String');
   buoy=str2num(get(h_edit_elebuoy,'String'));
   dim=str2num(get(h_edit_eledim,'String'));
   cd=str2num(get(h_edit_elecd,'String'));
   mat=get(h_menu_material,'Value');
   if ~strcmp(name,' ') & ~isempty(buoy) & length(dim)== 3 & ~isempty(cd), % OK to add
      if (buoy >= -9999.99 & buoy <= 9999.99 ) & ... % check range of enteries
         (dim(1) <= 9999 & dim(1) >= 0) & ...
         (dim(2) <= 1000 & dim(2) >= 0) & ...
         (dim(3) <= 1000 & dim(3) >= 0) & ...
         (cd >= 0 & cd <= 100),
         text='*                '; % initialize empty array 17 char
              %12345678901234567
         lname=min([length(name) 16]); % just incase name is too long
         if length(name)>16, disp('Warning: Element Name has too many characters! Limited to 16.'); end
            text(1:lname)=name(1:lname);
            tbuoy='        ';
            if abs(buoy) < 999, 
                buoy=num2str(buoy,'%8.3f');
            else
               buoy=num2str(buoy,'%8.2f');
            end
            tbuoy((9-length(buoy)):8)=buoy;  % must pad front with blanks
            tdim='                  ';
            if dim(1) < 1000,
                dim1=num2str(dim(1),'%5.1f');
            else
                dim1=num2str(dim(1),'%5.0f');
            end
            tdim((7-length(dim1)):6)=dim1;
            dim2=num2str(dim(2),'%5.1f');
            tdim((13-length(dim2)):12)=dim2;
            dim3=num2str(dim(3),'%5.1f');
            tdim((19-length(dim3)):18)=dim3;
            tcd='     ';
            cd=num2str(cd,'%4.2f');
            tcd((6-length(cd)):5)=cd;
            tmat='  ';
            mat=num2str(mat,'%1.0f');
            tmat(2)=mat;
            newele=[text tbuoy tdim tcd tmat];
            type=get(h_menu_type,'Value');
            already=0;
            if type == 1,
                [m,n]=size(floats);
                for ii=1:m,
                    if sum(strcmp(text,floats(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    floats(m+1,:)=newele;
                    floats
                else
                    disp('That element name is in use already.');
                end
            elseif type == 2,
                [m,n]=size(wires);
                for ii=1:m,
                    if sum(strcmp(text,wires(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    wires(m+1,:)=newele;
                    wires
                else
                    disp('That element name is in use already.');
                end
            elseif type == 3,
                [m,n]=size(chains);
                for ii=1:m,
                    if sum(strcmp(text,chains(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    chains(m+1,:)=newele;
                    chains
                else
                    disp('That element name is in use already.');
                end
            elseif type == 4,
                [m,n]=size(cms);
                for ii=1:m,
                    if sum(strcmp(text,cms(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    cms(m+1,:)=newele;
                    cms
                else
                    disp('That element name is in use already.');
                end
            elseif type == 5,
                [m,n]=size(acrels);
                for ii=1:m,
                    if sum(strcmp(text,acrels(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    acrels(m+1,:)=newele;
                    acrels
                else
                    disp('That element name is in use already.');
                end
            elseif type == 6,
                [m,n]=size(anchors);
                for ii=1:m,
                    if sum(strcmp(text,anchors(ii,1:17))) ~= 0,
                        already=1;
                    end
                end
                if already ==0,
                    anchors(m+1,:)=newele;
                    anchors
                else
                    disp('That element name is in use already.');
                end
            elseif type == 7
                [m,n]=size(miscs);
                for ii=1:m,
                    if sum(strcmp(text,miscs(ii,1:17))) ~= 0,
                       already=1;
                    end
                end
               if already ==0,
                    newele
                    miscs(m+1,:)=newele;
                    miscs
               else
                    disp('That element name is in use already.');
               end
            end
            addelement(1);
         else
            disp('Check format and range of allowable values (moordyn.txt)');
            name,buoy,dim,cd
         end
      else
        disp('Didn''t get all the necessary information/within bounds...');
        name,buoy,dim,cd
      end
   end
   addel=1;
   set(h_menu_addel,'Value',1);
   h_push_add=uicontrol('Style','Pushbutton',...
      'String','No Action','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(1)'); 
elseif command == 5, % delete an element
   if addel == 3, % just an additional check before deleting an element
        val=get(h_menu_list,'Value');
        type=get(h_menu_type,'Value');
        if type == 1,
            [m,n]=size(floats);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',floats(val,:)]);
            floats=floats(id,:);
        elseif type == 2,
            [m,n]=size(wires);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',wires(val,:)]);
            wires=wires(id,:);
        elseif type == 3,
            [m,n]=size(chains);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',chains(val,:)]);
            chains=chains(id,:);
        elseif type == 4,
            [m,n]=size(cms);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',cms(val,:)]);
            cms=cms(id,:);
        elseif type == 5,
            [m,n]=size(acrels);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',acrels(val,:)]);
            acrels=acrels(id,:);
        elseif type == 6,
            [m,n]=size(anchors);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',anchors(val,:)]);
            anchors=anchors(id,:);
        elseif type == 7
            [m,n]=size(miscs);
            if val == 1,
                id=(2:m);
            elseif val >1 & val < m,
                id=[(1:val-1) (val+1:m)];
            elseif val == m,
                id=(1:m-1);
            end
            disp(['!! I am deleting: ',miscs(val,:)]);
            miscs=miscs(id,:);
        end
        disp('!! Don''t SAVE unless you''re sure of this deletion !!');
        addelement(1);
    end
	addel=1;
    set(h_menu_addel,'Value',1);
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','No Action','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(1)'); 
elseif command == 6,
   disp('Saving a new MDCODES.MAT File! Should go into mooring directory.');
   [ofile,opath]=uiputfile('mdcodes.mat','Save A New MDCODES.MAT');
   if ~isempty(ofile),
      save([opath ofile],'acrels','cms','format','miscs','anchors','chains','floats','wires');
   else
      disp('No Database file saved. Check file name.');
   end
   clear ofile opath
   addelement(1);
elseif command == 7,
   load addelehelp
   h_help=msgbox(addhelp);
   set(h_help,'Units','Normalized','Position',[0.35 0.01 0.6 0.95]);
   clear addhelp
elseif command == 8,
   if addel == 4, % just an additional check/confirmation to MODIFY
        name=get(h_edit_elename,'String');
        buoy=str2num(get(h_edit_elebuoy,'String'));
        dim=str2num(get(h_edit_eledim,'String'));
        cd=str2num(get(h_edit_elecd,'String'));
        mat=get(h_menu_material,'Value');
        if ~strcmp(name,' ') & ~isempty(buoy) & length(dim)== 3 & ~isempty(cd), % OK to modify
           if (buoy > -10000 & buoy < 10000 ) & ... % check range of enteries
             (dim(1) <= 9999 & dim(1) >= 0) & ...
             (dim(2) <= 9999 & dim(2) >= 0) & ...
             (dim(3) <= 9999 & dim(3) >= 0) & ...
             (cd >= 0 & cd <= 10),
             text='*                '; % initialize empty array
                  %12345678901234567
             text(1:length(name))=name;
             tbuoy='        ';
             if abs(buoy) < 999, 
                buoy=num2str(buoy,'%8.3f');
             else
                buoy=num2str(buoy,'%8.2f');
             end
             tbuoy((9-length(buoy)):8)=buoy;  % must pad front with blanks
             tdim='                  ';
             if dim(1) < 1000,
                dim1=num2str(dim(1),'%5.1f');
             else
                dim1=num2str(dim(1),'%5.0f');
             end
             tdim((7-length(dim1)):6)=dim1;
             dim2=num2str(dim(2),'%5.1f');
             tdim((13-length(dim2)):12)=dim2;
             dim3=num2str(dim(3),'%5.1f');
             tdim((19-length(dim3)):18)=dim3;
             tcd='     ';
             cd=num2str(cd,'%4.2f');
             tcd((6-length(cd)):5)=cd;
             tmat='  ';
             mat=num2str(mat,'%1.0f');
             tmat(2)=mat;
             newele=[text tbuoy tdim tcd tmat];
             type=get(h_menu_type,'Value');
             already=0;
             if type == 1,
                [m,n]=size(floats);
                for ii=1:m,
                   if sum(strcmp(text,floats(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying float element characteristics ! ');
                   floats(imod,:)=newele;
                   floats
                end
             elseif type == 2,
                [m,n]=size(wires);
                for ii=1:m,
                   if sum(strcmp(text,wires(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii
                   end
                end
                if already ==1,
                   disp('Modifying wire/rope element characteristics ! ');
                   wires(imod,:)=newele;
                   wires
                end
             elseif type == 3,
                [m,n]=size(chains);
                for ii=1:m,
                   if sum(strcmp(text,chains(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying chain/shackle element characteristics ! ');
                   chains(imod,:)=newele;
                   chains
                end
             elseif type == 4,
                [m,n]=size(cms);
                for ii=1:m,
                   if sum(strcmp(text,cms(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying current meter element characteristics ! ');
                   cms(imod,:)=newele;
                   cms
                end
             elseif type == 5,
                [m,n]=size(acrels);
                for ii=1:m,
                   if sum(strcmp(text,acrels(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying acoustic release element characteristics ! ');
                   acrels(imod,:)=newele;
                   acrels
                end
             elseif type == 6,
                [m,n]=size(anchors);
                for ii=1:m,
                   if sum(strcmp(text,anchors(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying anchor element characteristics ! ');
                   anchors(imod,:)=newele;
                   anchors
                end
             elseif type == 7
                [m,n]=size(miscs);
                for ii=1:m,
                   if sum(strcmp(text,miscs(ii,1:17))) ~= 0,
                      already=1;
                      imod=ii;
                   end
                end
                if already ==1,
                   disp('Modifying miscellaneous element characteristics ! ');
                   miscs(imod,:)=newele;
                   miscs
                end
             end
             addelement(1);
          else
            disp('Check format and range of allowable values.');
            name,buoy,dim,cd
           end
        else
            disp('Didn''t get all the necessary information...');
            name,buoy,dim,cd
        end
    end
	addel=1;
    set(h_menu_addel,'Value',1);
    h_push_add=uicontrol('Style','Pushbutton',...
      'String','No Action','FontSize',fs,...
      'Units','normalized',...
      'Position',[.05 .1 .2 .08],...
      'Callback','addelement(1)'); 
end

if command == 1 | command == 2,
   val=get(h_menu_list,'Value');
   ele=list(val,format(1,1):format(1,2));
   buoy=list(val,format(2,1):format(2,2));
   dim=list(val,format(3,1):format(5,2));
   cd=list(val,format(6,1):format(6,2));
   mat=str2num(list(val,format(7,1):format(7,2)));
   set(h_edit_elename,'String',ele);
   set(h_edit_elebuoy,'String',buoy);
   set(h_edit_eledim,'String',dim);
   set(h_edit_elecd,'String',cd);
   set(h_menu_material,'Value',mat);
end
% fini