%==== format figures


function syn2ann_format_figures(hax)
    
    if nargin==0
        hax=gca;
    end
    
    set(hax,'box','on','xminortick','on','yminortick','on');
    %
    set(hax,'ticklength',[.05,.05]);
    ti = get(hax,'title');
    set(ti,'fontsize',20,'fontweight','bold');%25,30
    xl = get(hax,'xlabel');
    set(xl,'fontsize',15,'fontweight','bold');%20,24
    yl = get(hax,'ylabel');
    set(yl,'fontsize',15,'fontweight','bold');%,20,24
    zl = get(hax,'zlabel');
    set(zl,'fontsize',15);%20,24
    li = get(hax,'children');
    set(li,'markersize',10);%2.5-3
    set(hax,'linewidth',1.6,'fontsize',13);   %2,2-3,20
   
end