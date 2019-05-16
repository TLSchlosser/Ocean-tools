function plot_mooring(matfile,outPDF)

load(matfile)

xplot=0;
close;figure('position',[3 2 12 25],'PaperSize',[12 25]);
a(1)=axes('position',[.1 .02 .4 .95],'Color','none');hold on;
a(2)=axes('position',[.55 .02 .4 .95],'Color','none');hold on;

for jj=1:2
    %% first in line elements
    axes(a(jj))
    zplot=0;
    zTplot=zeros(size(moorele,1)+2,1);

    for ii=size(moorele,1):-1:1
        if typeM(ii) == 1 % miscs
            xscl=max([H(2,ii) 0.2]);
                fill([xplot-xscl xplot-xscl xplot+xscl xplot+xscl],...
                    [zplot zplot+H(1,ii) zplot+H(1,ii) zplot],'b','EdgeColor','b')

        elseif typeM(ii) == 2 % chains
            plot([xplot xplot],[zplot zplot+H(1,ii)],'LineWidth',1.2,'Color',[.5 0 1])

        elseif typeM(ii) == 3 % cms
            if B(ii)>1
                circle(xplot,zplot+H(1,ii)/2,H(1,ii)/2,'r');
            else
                xscl=max([H(2,ii) 0.2]);
                fill([xplot-xscl xplot-xscl xplot+xscl xplot+xscl],...
                    [zplot zplot+H(1,ii) zplot+H(1,ii) zplot],'r','EdgeColor','r')
            end

        elseif typeM(ii) == 4% floats
            circle(xplot,zplot+H(1,ii)/2,H(1,ii)/2,[1 .5 0]);

        elseif typeM(ii) == 5% wires
            plot([xplot xplot],[zplot zplot+H(1,ii)],'LineWidth',1.2,'Color',[0 0 0])

        elseif typeM(ii) == 6% anchors
            xscl=max([H(2,ii) 0.4]);
            if strcmp(strtrim(moorele(ii,:)),strtrim('lander_prelude  '))
                fill([xplot-xscl 0 xplot+xscl],...
                [zplot zplot+H(1,ii) zplot],'white','FaceColor','none')
            else
            fill([xplot-xscl xplot-xscl xplot+xscl xplot+xscl],...
                [zplot zplot+H(1,ii) zplot+H(1,ii) zplot],'black')
            end

        elseif typeM(ii) == 7% acrels
            xscl=max([H(2,ii) 0.2]);
            fill([xplot-xscl xplot-xscl xplot+xscl xplot+xscl],...
                [zplot zplot+H(1,ii) zplot+H(1,ii) zplot],'g','EdgeColor','g')

        end
        
        % labels
        if jj==1 && round(ii/2)==ii/2
            % even- right 
            if ischar(SerialIL{ii}) || ~isnan(SerialIL{ii})
                % need more spacing
                zTplot(ii)=max([zplot+H(1,ii)/2 zTplot(ii+2)+max(z)/60]);
            else
                zTplot(ii)=max([zplot+H(1,ii)/2 zTplot(ii+2)+max(z)/120]);
            end
            text(xplot+.5,zTplot(ii),['\leftarrow',strtrim(moorele(ii,:)),sprintf(' %4.1f m',zplot+H(1,ii)/2)],...
                'FontSize',6,'VerticalAlignment','middle')
            if ischar(SerialIL{ii})
                text(xplot+.5,zTplot(ii)-max(z)/100,strtrim(SerialIL{ii}),...
                    'FontSize',6,'VerticalAlignment','middle','Color',[.5 .5 .5])
                if typeM(ii)==7 || strcmp(moorele(ii,1:3),'pop')
                    text(0,max(z)*.98,[outPDF(1:4),':',strtrim(SerialIL{ii})],'FontSize',12,...
                        'FontWeight','bold')
                end
            elseif ~isnan(SerialIL{ii})
                text(xplot+.5,zTplot(ii)-max(z)/100,num2str(SerialIL{ii}),...
                    'FontSize',6,'VerticalAlignment','middle','Color',[.5 .5 .5])
            end
        elseif jj==1 && round(ii/2)~=ii/2
            % odd- left            
            if ischar(SerialIL{ii}) || ~isnan(SerialIL{ii})
                % need more spacing
                zTplot(ii)=max([zplot+H(1,ii)/2 zTplot(ii+2)+max(z)/60]);
            else
                zTplot(ii)=max([zplot+H(1,ii)/2 zTplot(ii+2)+max(z)/120]);
            end
            
            text(xplot-.5,zTplot(ii),[strtrim(moorele(ii,:)),sprintf(' %4.1f m',zplot+H(1,ii)/2),'\rightarrow'],...
                'FontSize',6,'HorizontalAlignment','right','VerticalAlignment','middle')
            if ischar(SerialIL{ii})
                text(xplot-.5,zTplot(ii)-max(z)/100,strtrim(SerialIL{ii}),...
                    'FontSize',6,'HorizontalAlignment','right','VerticalAlignment','middle','Color',[.5 .5 .5])
                if typeM(ii)==7 || strcmp(moorele(ii,1:3),'pop')
                    text(0,max(z)*.98,[outPDF(1:4),':',strtrim(SerialIL{ii})],'FontSize',12,...
                        'FontWeight','bold')
                end
            elseif ~isnan(SerialIL{ii})
                text(xplot-.5,zTplot(ii)-max(z)/100,num2str(SerialIL{ii}),...
                    'FontSize',6,'HorizontalAlignment','right','VerticalAlignment','middle','Color',[.5 .5 .5])
            end
        end
        
        zplot=zplot+H(1,ii);
    end
        
    %% next clamped-on elements
    zTplot=zeros(size(mooreleCO,1)+1,1);
    if exist('mooreleCO','var')
    for ii=size(mooreleCO,1):-1:1
        xscl=max([HCO(2,ii) 0.1]);
        fill([xplot-xscl xplot-xscl xplot+xscl xplot+xscl],...
                [ZCO(ii) ZCO(ii)+HCO(1,ii) ZCO(ii)+HCO(1,ii) ZCO(ii)],'m','EdgeColor','m')
        
            % labels
        if jj==2 && round(ii/2)==ii/2
            % even- right            
            zTplot(ii)=max([ZCO(ii)+HCO(1,ii)/2 zTplot(ii+1)+max(z)/100]);
            text(xplot+.5,zTplot(ii),['\leftarrow',strtrim(mooreleCO(ii,:)),sprintf(' %4.1f m',ZCO(ii))],...
                'FontSize',6,'VerticalAlignment','middle')
            if ~isnan(SerialCO{ii})
            text(xplot+1.5,zTplot(ii)-max(z)/100,['',SerialCO(ii)],...
                'FontSize',6,'VerticalAlignment','middle','Color',[.5 .5 .5])
            end
        elseif jj==2 && round(ii/2)~=ii/2
            % odd- left            
            zTplot(ii)=max([ZCO(ii)+HCO(1,ii)/2 zTplot(ii+1)+max(z)/100]);
            text(xplot-.5,zTplot(ii),[strtrim(mooreleCO(ii,:)),sprintf(' %4.1f m',ZCO(ii)),'\rightarrow'],...
                'FontSize',6,'HorizontalAlignment','right')
            if ~isnan(SerialCO{ii})
            text(xplot-1.5,zTplot(ii)-max(z)/100,['',SerialCO(ii)],...
                'FontSize',6,'HorizontalAlignment','right','Color',[.5 .5 .5])
            end
        end
    end
    end
    xlim([-1 1].*zplot./20)
    ylim([0 max(z)])
    
end
set(a(jj),'YTickLabel',[])

print(outPDF,'-dpdf','-r300')
print([outPDF(1:end-4),'.png'],'-dpng','-r600')