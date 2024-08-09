function [h, kr] = f_SDP_controller(s0, a, b, c, z)

    % Calculate h
    h = (-s0 .^ 2 .* z + b .* z + a + 2 .* s0) ./ (s0 .^ 3 .* z + (a .* z - 1) .* s0 .^ 2 + (b .* z - a) .* s0 - b);

    % Calculate kp, and kr
    kr = -(a .* s0 + s0 .^ 2 + b) ./ c ./ exp(-h .* s0) ./ (s0 .* z - 0.1e1);

end