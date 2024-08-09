function [h, kp, ki, kr] = f_PIR_controller(s0, a, b, c, z)
    % Calculate lambda values
    lam4  = ((s0.^3).*(z^2)) - (3*(s0.^2).*z) + b*z + a;
    lam3  = s0.*(-6.*b.*z.^2 - 6*a*z + 6) + 3*b*z + 3*a;
    lam2  = (((s0.^2).*z)-s0).*(lam4+(3.*s0));
    lam1  = -3.*s0.^4.*z^3 + 12.*s0.^3.*z.^2 - 18.*s0.^2.*z + lam3;
    lam0  = (6*b*(z^2)) + (6*a*z) + 6;

    % Calculate hp and h
    h   = (-lam1 - sqrt(lam1.^2 - 4.*lam2*lam0)) ./ (2.*lam2);

    % Calculate kp, ki, and kr
    kp = (s0 .* (s0 .* z - 1) .* (a + 3 .* s0) .* h .^ 3 + (-6 .* a .* s0 .* z - 15 .* s0 .^ 2 .* z + 3 .* a + 6 .* s0) .* h .^ 2 + (6 .* a .* z + 6 .* s0 .* z + 6) .* h + 6 .* z) ./ c ./ z ./ ((s0 .^ 2 .* z - s0) .* h .^ 2 + (-6 .* s0 .* z + 3) .* h + 6 .* z) ./ h;
    ki = (((-3 .* s0 .^ 2 + b) .* z + a + 3 .* s0) .* (s0 .* z - 1) .* s0 .* h .^ 2 - (6 .* s0 .* z - 3) .* ((-2 .* s0 .^ 2 + b) .* z + a + 2 .* s0) .* h + 6 .* b .* z .^ 2 + 6 .* a .* z + 6) ./ c ./ z .^ 2 ./ ((s0 .^ 2 .* z - s0) .* h .^ 2 + (-6 .* s0 .* z + 3) .* h + 6 .* z);
    kr = 6 .* exp(s0 .* h) ./ c ./ h ./ (h .^ 2 .* s0 .^ 2 .* z - h .^ 2 .* s0 - 6 .* s0 .* h .* z + 3 .* h + 6 .* z);
end
