% script to launch the Mooring Design and Dynamics
% HTML Users Guide in the systems default Web Browser
cp=which('mdd');
cp=cp(1:end-2);
system([cp,'\mdd.html']);
% fini