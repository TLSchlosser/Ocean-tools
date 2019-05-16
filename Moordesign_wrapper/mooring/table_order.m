clear
Matfiles=cellstr(ls('*_1.0xVel.mat'));

shackle_16mmDS=0;
shackle_16mmBS=0;
link_16mm=0;
shackle_13mmBS=0;
shackle_13mmDS=0;
link_13mm=0;
Swivel=0;
chainDB=0;
GalvChain_16mm=0;
GalvChain_10mm=0;
LoadRing=0;
Wire95=0;
Wire5=0;
Amsteel6=0;

for ii=1:length(Matfiles)
    load(Matfiles{ii})
    
    for jj=1:size(moorele,1)
        switch strtrim(moorele(jj,:))
            case '16mmDS-L-16mmDS'        
                shackle_16mmDS=shackle_16mmDS+2;
                link_16mm=link_16mm+1;
            
            case '16mmDS-L'        
                shackle_16mmDS=shackle_16mmDS+1;
                link_16mm=link_16mm+1;
                
            case '13mmBS-L-16mmDS'        
                shackle_13mmBS=shackle_13mmBS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                link_13mm=link_13mm+1;
                
            case '13mmBS'        
                shackle_13mmBS=shackle_13mmBS+1;                
        
            case '13mmDS-L-16mmDS'
                shackle_13mmDS=shackle_13mmDS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                link_13mm=link_13mm+1;
        
            case '16mmBS-L-13mmDS'
                shackle_13mmDS=shackle_13mmDS+1;
                shackle_16mmBS=shackle_16mmBS+1;
                link_13mm=link_13mm+1;
            
            case '16mmDS-L-13mmDS'        
                shackle_13mmDS=shackle_13mmDS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                link_13mm=link_13mm+1;
                
            case '16mmDS-L-13mmBS'        
                shackle_13mmBS=shackle_13mmBS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                link_13mm=link_13mm+1;
                
            case '16mmDS-Swvl-13mmBS'        
                shackle_13mmBS=shackle_13mmBS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                Swivel=Swivel+1;
        
            case '16mmDS-Swvl-16mmDS'        
                shackle_13mmBS=shackle_13mmBS+1;
                shackle_16mmDS=shackle_16mmDS+1;
                Swivel=Swivel+1;
            case '16mmBS'        
                shackle_16mmBS=shackle_16mmBS+1;
                
            case 'Dbld 3/8" chain'        
            chainDB=chainDB+1;
            %13mm galvanised dee shackle
            
            case '3/8 chain SL'        
                GalvChain_10mm=GalvChain_10mm+1;
                
            case '1/2 chain SL'        
                GalvChain_16mm=GalvChain_16mm+1;
        
            case '150mm Load Ring'        
                LoadRing=LoadRing+1;        
        %% wire
            case '3/8 wire rope'        
                Wire95=Wire95+H(1,jj);    
            case '3/16 wire rope'        
                Wire5=Wire5+H(1,jj);    
            case '6mm AmSteel'        
                Amsteel6=Amsteel6+H(1,jj);        
                
            otherwise
                fprintf('No match for %s\n',moorele(jj,:))
        end
    end
end

table{1,1}='shackle_16mmDS';
table{1,2}=shackle_16mmDS;
table{2,1}='shackle_16mmBS';
table{2,2}=shackle_16mmBS;
table{3,1}='shackle_13mmDS';
table{3,2}=shackle_13mmDS;
table{4,1}='shackle_13mmBS';
table{4,2}=shackle_13mmBS;
table{5,1}='link_13mm';
table{5,2}=link_13mm;
table{6,1}='link_16mm';
table{6,2}=link_16mm;
table{7,1}='Swivel';
table{7,2}=Swivel;
table{8,1}='LoadRing';
table{8,2}=LoadRing;
table{9,1}='chainDB';
table{9,2}=chainDB;
table{10,1}='GalvChain_16mm';
table{10,2}=GalvChain_16mm;
table{11,1}='GalvChain_10mm';
table{11,2}=GalvChain_10mm;
table{12,1}='Wire95';
table{12,2}=Wire95;
table{13,1}='Wire5';
table{13,2}=Wire5;
table{14,1}='Amsteel6';
table{14,2}=Amsteel6;