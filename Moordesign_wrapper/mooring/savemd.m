function savemd
% function savemd.m
% save a new/modified mooring design mat file

global U V W z rho time
global H B Cd ME moorele
global Ht Bt Cdt MEt moorelet Usp Vsp afh
global HCO BCO CdCO ZCO mooreleCO Iobj Jobj Pobj

if (~isempty(H) & ~isempty(B) & ~isempty(Cd))|(~isempty(Ht) & ~isempty(Bt) & ~isempty(Cdt)),
[ofile,opath]=uiputfile('*.mat','Save An MD&D Mooring File');
if ~isempty(ofile) & ~strcmp(ofile,'*.mat'),
   if ~isempty(H) & isempty(BCO), % normal mooring, no clamp-on devices
      save([opath ofile],'U','V','W','z','rho','time','H','B','Cd','ME','moorele');
   elseif ~isempty(H) & ~isempty(BCO) % then we've got clamp-on devices as well
      save([opath ofile],'U','V','W','z','rho','time','H','B','Cd','ME','moorele'...
         ,'HCO','BCO','CdCO','ZCO','mooreleCO','Pobj','Jobj','Iobj');
   elseif ~isempty(Ht) & isempty(BCO), % towed body
      save([opath ofile],'U','V','W','z','rho','time','Ht','Bt','Cdt','MEt','moorelet','Usp','Vsp','afh');      
   elseif ~isempty(Ht) & ~isempty(BCO), % towed body
      save([opath ofile],'U','V','W','z','rho','time','Ht','Bt','Cdt','MEt','moorelet','Usp','Vsp','afh'...      
         ,'HCO','BCO','CdCO','ZCO','mooreleCO','Pobj','Jobj','Iobj');
   end
end
clear ofile opath
else
   disp(' Must load or enter a mooring before it can be saved. ');
end

% fini