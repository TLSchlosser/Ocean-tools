function pltwire
% function pltwire
% Plot a section of wire/rope
% To be used with Mooring Design and Dynamics
% RKD 5/98

global H th el chainf

figure(5)
[mh,nh]=size(H);
h=H(1,el);
zb=0;
for i=nh:-1:(el+1),
   if H(4,i)~=1,
      zb=zb+H(1,i);  % sum mooring height
   else
      zb=zb+H(1,i)/chainf;
   end
end
zt=zb+h/chainf; % z at the top

plot([0 0],[zb zt],'k','LineWidth',1);

% fini
