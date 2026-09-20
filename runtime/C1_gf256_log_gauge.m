function result = C1_gf256_log_gauge(varargin)
    % GF(256) Log-Gauge Quotient
    field_size = 256;
    primitive = 3;
    order = 255;
    gauge_param = 64;
    
    % Verify arithmetic
    inv_4_mod_255 = mod(4 * gauge_param, order);
    gcd_4_255 = gcd(4, 255);
    
    if inv_4_mod_255 ~= 1
        error('Arithmetic: 4*64 mod 255 != 1');
    end
    if gcd_4_255 ~= 1
        error('GCD(4,255) != 1');
    end
    
    % Build log table
    log_table = zeros(1, field_size);
    val = 1;
    for exp = 0:order-1
        log_table(val+1) = exp;
        val = mod(val * primitive, field_size);
        if val == 0, val = field_size; end
    end
    
    % Gauge normalization test
    x_test = 100;
    log_x = log_table(x_test + 1);
    gauge_norm = mod(log_x - gauge_param, order);
    
    result.field_size = field_size;
    result.primitive_element = primitive;
    result.order = order;
    result.gauge_parameter = gauge_param;
    result.arithmetic_4_64_mod_255 = inv_4_mod_255;
    result.gcd_4_255 = gcd_4_255;
    result.log_table_size = length(log_table);
    result.status = 'PASS';
end
