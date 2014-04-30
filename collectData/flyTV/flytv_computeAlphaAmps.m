function [amps,alpha]=flytv_computeAlphaAmps(contrast)
% function [amps,alpha]=flytv_computeAlphaAmps(contrast)
% When we superimpose two gratings, the final amplitude of each element is
% controlled by a combination of alpha blending and amplitude setting
% This function computes those two numbers

if sum(contrast(:))>1
    error ('Can''t have sum contrast greater than 1');
end

if (contrast(1)>.5)
    alpha=1-contrast(1);
else
    alpha=.5;
end

amps(1)=contrast(1)/(2*(1-alpha));
amps(2)=contrast(2)/(2*alpha);

if (sum(amps>.5001) | sum(amps<0))
    disp(amps);
    disp(alpha);
    error('Amps out of bounds');
end

    