function[deltad,flag_lr]=AdjustAngle_z35_5(d,psi,flag_lr)
    %35-5��Z�Σ���Ǳ仯15.8��/s
    d=d*180/pi; psi=-psi*180/pi;

    %d��psi�����෴
    if flag_lr ==1    %��
        if d<35
            flag_lr =1;deltad = 15.8;
        elseif (abs(d-35)<20) && psi<5
            flag_lr =1;deltad = 0;
        elseif psi>5
            flag_lr =-1;deltad= -15.8;    
        end
    end
        
    if flag_lr ==-1    %��
        if d>-35
            flag_lr =-1;deltad=-15.8;
        elseif (abs(d+35)<20) && psi > -5
            flag_lr =-1;deltad = 0;
        elseif   psi<-5
            flag_lr=1;deltad=15.8;
        end
    end
    
    deltad = deltad*pi/180;

end