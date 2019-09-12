function [roi,h]=roifreeselection(action,figh)

if isempty(action)
    d.oldud=get(figh,'userdata');
    set(figh,'userdata',d);
    set(figh,'windowbuttondownfcn','roifreeselection(''down'',gcbo)');
    hold on;
    drawnow;
    uiwait;
    d=get(figh,'userdata');
    roi=d.selection;
    if ~isempty(roi)
        d.selection(:,end+1)=d.selection(:,1);
        set(d.hl,'xdata',d.selection(1,:));
        set(d.hl,'ydata',d.selection(2,:));
        set(d.hl,'linewidth',1,'linestyle','-.');
        h=d.hl;
    else
        h=[];
        delete(d.hl);
    end;
    set(figh,'userdata',d.oldud);
    set(figh,'windowbuttondownfcn','');
    set(figh,'windowbuttonmotionfcn','');
    set(figh,'windowbuttonupfcn','');
    
elseif strcmp(action,'down');    
    if strcmp(get(gcf,'selectionType'),'normal')
        cp = get(gca,'currentpoint');
        xlim=get(gca,'xlim');
        ylim=get(gca,'ylim');
        if cp(1,1)>xlim(2) || cp(1,1)<xlim(1) || cp(1,2)>ylim(2) || cp(1,2)<ylim(1)
            return;
        end;
        roidata=get(figh,'userdata');
        roidata.down=1;
        roidata.selection=[];
        roidata.hl=[];
        set(figh,'userdata',roidata);
        set(figh,'windowbuttonmotionfcn','roifreeselection(''move'',gcbo)');
        set(figh,'windowbuttonupfcn','roifreeselection(''up'',gcbo)');
    end;

elseif strcmp('move',action)
    d=get(figh,'userdata');
    if d.down==1
        cp = get(gca,'currentpoint');
        xlim=get(gca,'xlim');
        ylim=get(gca,'ylim');
        cpx=cp(1,1);
        if cpx<xlim(1) 
            cpx=xlim(1)+1; 
        elseif cpx>xlim(2) 
            cpx=xlim(2)-1;
        end;
        cpy=cp(1,2);
        if cpy<ylim(1) cpy=ylim(1)+1; 
        elseif cpy>ylim(2) cpy=ylim(2)-1;
        end;
        d.selection=[d.selection [cpx;cpy]];
        if isempty(d.hl)
            d.hl=plot(d.selection(1,1),d.selection(2,1),'g-','linewidth',2);
        else
            set(d.hl,'xdata',d.selection(1,:));
            set(d.hl,'ydata',d.selection(2,:));
        end;
        set(figh,'userdata',d);
    end;
    
elseif strcmp('up',action)
    d=get(figh,'userdata');
    if d.down==1
        d.down=0;
        set(figh,'userdata',d);
        uiresume;
    end;
%     d=get(figh,'userdata');
%     if d.down==1
%         d.down=0;
%         set(figh,'userdata',d);
%         uiresume;
%     end;
end;

