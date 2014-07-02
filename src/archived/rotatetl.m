%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rotatetl.m
%
% Function to rotate the Tick Labels and alternate their position on an Xaxis (top or bottom)   
% Input: axes handle, rotation in degree, position of the X axis (top or
%       bottom)
% Output: two textboxes containing the new Tick Labels
% 
% Warning: 1) rotation between 0 and 180 degrees advised
%          2) if long strings, change values u and l
%          
% Acknowledge: Inspired by Andrew Bliss
%
% Fanny Besem
% July 1st, 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[tl1,tl2]=rotatetl(h,rot,tb)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Spacing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
u=0.03;
l=0.04;

%%%%%%%%%%%%%%%%%%%% Get current graph properties %%%%%%%%%%%%%%%%%%%%%%%
a=get(h,'XTickLabel');
b=get(h,'XTick');
c=get(h,'YLim');
if strcmpi(tb,'t') || strcmpi(tb,'top'),
    tb=2;
elseif strcmpi(tb,'b') || strcmpi(tb,'bottom'),
    tb=1;
else
    disp('The third argument is not recognized, try top or bottom');
end

%%%%%%%%%%%%%%%% Erase current tick labels from figure %%%%%%%%%%%%%%%%%%
set(h,'XTickLabel',[]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Routine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if rot>=0 || rot<=360,
flag=1;
    while flag
        rot=mod(rot,360);
        if rot>=0 && rot<=360,
            flag=0;
        end
    end
end

k=1;
while k<=size(a,1),
    a1(k/2+0.5,:)=a(k,:);
    a2(k/2+.5,:)=a(k+1,:);
    b1(k/2+.5)=b(k);
    b2(k/2+.5)=b(k+1);
    k=k+2;
end

c1=(c(1,tb)+(c(1,2)-c(1,1))*u).*ones(1,length(b1)); % upper ticks
c2=(c(1,tb)-(c(1,2)-c(1,1))*l).*ones(1,length(b1)); % lower ticks

tl1=text(b1,c1,a1,'HorizontalAlignment','center','rotation',rot,'VerticalAlignment','cap');
tl2=text(b2,c2,a2,'HorizontalAlignment','center','rotation',rot,'VerticalAlignment','cap');
    
end


