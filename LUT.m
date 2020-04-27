classdef LUT < multi_array.Range
    %LUT Lookup table approximation of y = f(x)
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (SetAccess = protected)
        x_dim;  % Input dimension [int]
        y_dim;  % Output dimension [int]
        y_arr;  % Output arrays [multi_array.Array]
    end
    
    methods (Access = public)
        function obj = LUT(x_rng, y_dim, func)
            %obj = LUT(x_rng, y_dim, func)
            %   Construct LUT
            %   
            %   Inputs:
            %   - x_rng = Input range [multi_array.Range, rank_ = m]
            %   - y_dim = Output dimension [int]
            %   - func = Filling function
            %   
            %   See also: SET_FUNC
            
            % Imports
            import('multi_array.Array');
            
            % Construction
            obj@multi_array.Range(x_rng.vals_min, x_rng.vals_max, x_rng.size_);
            obj.x_dim = x_rng.rank_;
            obj.y_dim = y_dim;
            obj.y_arr = Array.empty(0, 1);
            for i = 1 : obj.y_dim
                obj.y_arr(i, 1) = Array(obj.size_);
            end
            
            % Optional function set
            if nargin == 3
                obj.set_func(func);
            end
        end
        
        function set_func(obj, func)
            %SET_FUNC(obj, func) Fill LUT with given function
            %   
            %   Function func must map [m x 1] to [n x 1].
            for ind_x = 1 : obj.numel_
                x = obj.conv(ind_x, 'Ind', 'Val');
                obj.set(ind_x, func(x), 'Ind');
            end
        end
        
        function y = get(obj, pos, interp, extrap, fmt)
            %y = GET(obj, pos, interp, extrap, fmt)
            %   Get value from LUT
            %   
            %   Inputs:
            %   - pos = LUT position
            %   - interp = Interpolation [char]
            %       'Linear' = Linear [default]
            %       'Nearest' = Nearest neighbor
            %   - extrap = Extrapolation [char]
            %       'NaN' = NaN return vector [default]
            %       'Nearest' = Nearest neighbor
            %   - fmt = Position format [char]
            %       'Val' = Continuous value [default]
            %       'Sub' = Subscript array
            %       'Ind' = Single index
            %   
            %   Outputs:
            %   - y = Output vector [n x 1]
            
            % Default args
            if nargin < 3, interp = 'Linear'; end
            if nargin < 4, extrap = 'NaN'; end
            if nargin < 5, fmt = 'Val'; end
            
            % Extrapolation
            x = obj.conv(pos, fmt, 'Val');
            switch extrap
                case 'NaN'
                    if ~obj.has(x)
                        y = NaN(obj.y_dim, 1);
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
                    n_lat = 2^obj.x_dim;
                    y = zeros(obj.y_dim, n_lat);
                    for k = 1 : n_lat
                        sub_x = zeros(obj.x_dim, 1);
                        for i = 1 : obj.x_dim
                            sub_x(i) = sub_x_rng(...
                                i, bitget(k-1, obj.x_dim+1-i) + 1);
                        end
                        for sub_y = 1 : obj.y_dim
                            y(sub_y, k) = obj.y_arr(sub_y).get(sub_x, 'Sub');
                        end
                    end
                    
                    % Interpolate on each dim of x
                    x_del = mod(sub_x_mid, 1);
                    for i = 1 : obj.x_dim
                        y1 = y(:, 1 : end/2);
                        y2 = y(:, end/2 + 1 : end);
                        y = y1*(1 - x_del(i)) + y2*x_del(i);
                    end
                    
                case 'Nearest'
                    % Round subscripts
                    sub_x = round(sub_x);
                    
                    % Get from LUT
                    y = zeros(obj.y_dim, 1);
                    for sub_y = 1 : obj.y_dim
                        y(sub_y) = obj.y_arr(sub_y).get(sub_x, 'Sub');
                    end
                    
                otherwise
                    error('Invalid interpolation: %s', interp)
            end
        end
        
        function set(obj, pos, y, fmt)
            %SET Set value in LUT
            %   
            %   SET(obj, ind, y, 'Ind') Set by single index
            %   SET(obj, sub, y, 'Sub') Set by subscript array
            %   SET(obj, val, y, 'Val') Set by continuous value
            %   SET(obj, val, y) Set by continuous value
            %   
            %   For 'Val', val is rounded to nearest subscript
            if nargin < 4, fmt = 'Val'; end
            sub_x = round(obj.conv(pos, fmt, 'Sub'));
            for sub_y = 1 : obj.y_dim
                obj.y_arr(sub_y).set(sub_x, 'Sub', y(sub_y));
            end
        end
    end
    
    methods (Access = public, Static)
        function lut = load(name)
            %lut = LOAD(name)
            %   Load LUT from binary file
            %   
            %   Inputs:
            %   - name = File name ['*.bin']
            %   
            %   Outputs:
            %   - lut = Lookup table [multi_array.LUT]
            
            % Imports
            import('multi_array.Range');
            import('multi_array.LUT');
            
            % Read range and size
            file = fopen(name, 'r');
            rank_ = LUT.read(file, 4, 'uint32');
            size_ = LUT.read(file, 4*rank_, 'uint32');
            mins_ = LUT.read(file, 4*rank_, 'single');
            maxs_ = LUT.read(file, 4*rank_, 'single');
            y_dim = LUT.read(file, 4, 'uint32');
            
            % Make empty LUT
            range_ = Range(mins_, maxs_, size_);
            lut = LUT(range_, y_dim);
            
            % Read in data
            numel_ = prod(size_);
            for ind = 1 : numel_
                y = LUT.read(file, 4*y_dim, 'single');
                lut.set(ind, y, 'Ind');
            end
        end
    end
    
    methods (Access = protected, Static)
        function data = read(file, n, type_)
            %data = READ(file, n, type_)
            %   Read data from file
            %   
            %   Inputs:
            %   - file = File [fopen(...)]
            %   - n = Number of bytes
            %   - type_ = Data type
            %   
            %   Outputs:
            %   - data = Read data
            data = double(typecast(uint8(fread(file, n)), type_));
        end
    end
end