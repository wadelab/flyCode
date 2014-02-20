function [ zz_pred, row, col ] = separate(zz)
% SEPARATE approximate with a separable matrix
% 
% [ zz_pred, row, col ] = separate(zz)
%
% SUPERSEDED BY MAKESEPARABLE
%
% 2005-03 Matteo Carandini

warning('SEPARATE is obsolete.  Use MakeSeparable instead.');

[uu,ss,vv] = svd(zz);
row = uu(:,1)';

[uu,ss,vv] = svd(zz');
col = uu(:,1)';

zz_pred = row' * col;

zz_pred = zz_pred* norm(zz(:))/norm(zz_pred(:));
