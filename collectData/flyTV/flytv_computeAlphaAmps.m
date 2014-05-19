function [amps,alpha]=flytv_computeAlphaAmps(cont)
% function [amps,alpha]=flytv_computeAlphaAmps(contrast)
% When we superimpose two gratings, the final amplitude of each element is
% controlled by a combination of alpha blending and amplitude setting
% This function computes those two numbers

if (sum(cont(:))>1)
    disp(sum(cont(:)))
    error ('Can''t have sum contrast greater than 1');
end

if (cont(1)>.5)
    alpha=1-cont(1);
else
    alpha=.5;
end

amps(1)=cont(1)/(2*(1-alpha));
amps(2)=cont(2)/(2*alpha);

if (sum(amps>.5001) || sum(amps<0))
    disp(amps);
    disp(alpha);
    error('Amps out of bounds');
end

    