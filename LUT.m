classdef LUT < multi_array.Range
    %LUT Lookup table approximation of y = f(x)
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (SetAccess = protected)
        m;      % Input dimension [int]
        n;      % Output dimension [int]
        tables; % Output tables [multi_array.Array]
    end
    
    methods (Access = public)
        function obj = LUT(size_, x_min, x_max, n, func)
            %obj = LUT(size_, x_min, x_max, n, func)
            %   Construct LUT
            %   
            %   Inputs:
            %   - size_ = Array size [int, [m x 1]]
            %   - x_min = Min input values [double, [m x 1]]
            %   - x_max = Max input values [double, [m x 1]]
            %   - n = Output dimension [int]
            %   - func = Populating function
            %   
            %   Function func must map [m x 1 to [n x 1].
            %   If no func is given, the table is zeroed.
            obj@multi_array.Range(size_, x_min, x_max);
            obj.m = length(x_min);
            obj.n = n;
            obj.tables = multi_array.Array.empty(0, 1);
            for i = 1 : obj.n
                obj.tables(i, 1) = multi_array.Array(size_);
            end
            if nargin == 5
                obj.set_func(func);
            end
        end
        
        function set_func(obj, func)
            %SET_FUNC(obj, func) Fill LUT with given function
            %   
            %   Function func must map [m x 1] to [n x 1].
            for ind_x = 1 : numel(obj)
                x = obj.conv(ind_x, 'Ind', 'Val');
                obj.set(ind_x, 'Ind', func(x));
            end
        end
        
        function y = get(obj, pos, fmt, interp, extrap)
            %y = GET(obj, x, fmt, interp, extrap)
            %   Get value from LUT
            %   
            %   Inputs:
            %   - pos = LUT position
            %   - fmt = Position format [char]
            %       'Val' = Continuous value [default]
            %       'Sub' = Subscript array
            %       'Ind' = Single index
            %   - interp = Interpolation [char]
            %       'Linear' = Linear [default]
            %       'Nearest' = Nearest neighbor
            %   - extrap = Extrapolation [char]
            %       'NaN' = NaN return vector [default]
            %       'Nearest' = Nearest neighbor
            %   
            %   Outputs:
            %   - y = Output vector [n x 1]
            
            % Default args
            if nargin < 5, extrap = 'NaN'; end
            if nargin < 4, extrap = 'Linear'; end
            if nargin < 3, fmt = 'Val'; end
            
            % Extrapolation
            x = obj.conv(pos, fmt, 'Val');
            switch extrap
                case 'NaN'
                    if ~obj.has(x)
                        y = NaN(obj.n, 1);
                        return
                    end
                    
                case 'Nearest'
                    x = obj.limit(x);
                    
                otherwise
                    error('Invalid extrapolation: %s', extrap)
            end
            
            % Interpolation
            sub_x = obj.conv(x, 'Val', 'Sub');
            switch interp
                case 'Linear'
                    % Subscript range
                    sub_x_mid = sub_x;
                    sub_x_min = floor(sub_x_mid);
                    sub_x_max = ceil(sub_x_mid);
                    sub_x_rng = [sub_x_min, sub_x_max];
                    
                    % Lattice points of y
                    y = zeros(obj.n, 2^obj.m);
                    for k = 1 : 2^obj.m
                        sub_x = zeros(obj.m, 1);
                        for i = 1 : obj.m
                            sub_x(i) = sub_x_rng(i, bitget(k-1, obj.m+1-i) + 1);
                        end
                        for sub_y = 1 : obj.n
                            y(sub_y, k) = obj.tables(sub_y).get(sub_x, 'Sub');
                        end
                    end
                    
                    % Interpolate on each dim of x
                    x_del = mod(sub_x_mid, 1);
                    for i = 1 : obj.m
                        y1 = y(:, 1 : end/2);
                        y2 = y(:, end/2 + 1 : end);
                        y = y1*(1 - x_del(i)) + y2*x_del(i);
                    end
                    
                case 'Nearest'
                    % Round subscripts
                    sub_x = round(sub_x);
                    
                    % Get from LUT
                    y = zeros(obj.n, 1);
                    for sub_y = 1 : obj.n
                        y(sub_y) = obj.tables(sub_y).get(sub_x, 'Sub');
                    end
                    
                otherwise
                    error('Invalid interpolation: %s', interp)
            end
        end
        
        function set(obj, pos, fmt, y)
            %SET Set value in LUT
            %   
            %   SET(obj, ind, 'Ind', y) Set by single index
            %   SET(obj, sub, 'Sub', y) Set by subscript array
            %   SET(obj, val, 'Val', y) Set by continuous value
            %   
            %   For 'Val', val is rounded to nearest subscript
            sub_x = round(obj.conv(pos, fmt, 'Sub'));
            for sub_y = 1 : obj.n
                obj.tables(sub_y).set(sub_x, 'Sub', y(sub_y));
            end
        end
    end
end