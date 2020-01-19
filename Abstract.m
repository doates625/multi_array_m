classdef (Abstract) Abstract < handle
    %ABSTRACT Superclass for multi-array objects
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (Access = protected)
        size_;      % Size array [int]
        numel_;     % Element count [int]
        sub_to_ind; % Sub to Ind array [double]
        ind_to_sub; % Ind to Sub array [double]
    end
    
    methods (Access = public)
        function obj = Abstract(size_)
            %obj = ABSTRACT(size_) Construct abstract of given size
            
            % Format size
            if iscolumn(size_), size_ = size_.'; end
            if length(size_) == 1, size_ = [size_, 1]; end
            
            % Construction
            obj.size_ = size_;
            obj.numel_ = prod(size_);
            obj.sub_to_ind = cumprod([1, size_(1:end-1)]).';
            obj.ind_to_sub = 1 ./ obj.sub_to_ind;
        end
        
        function pos2 = conv(obj, pos1, fmt1, fmt2)
            %pos2 = CONV(obj, pos1, fmt1, fmt2)
            %   Convert between position formats
            %   
            %   Inputs:
            %   - pos1 = Input position
            %   - fmt1 = Format of input [char]
            %   - fmt2 = Format of output [char]
            %   
            %   Outputs:
            %   - pos2 = Output position
            %   
            %   Valid formats: 'Ind', 'Sub'
            
            % Imports
            import('multi_array.PosFmt');
            
            % Format args
            [pos1, fmt1, fmt2] = obj.fmt_conv_args(pos1, fmt1, fmt2);
            
            % Conversions
            if fmt1 == fmt2
                pos2 = pos1;
            elseif fmt1 == PosFmt.Ind && fmt2 == PosFmt.Sub
                pos2 = obj.conv_ind_sub(pos1);
            elseif fmt1 == PosFmt.Sub && fmt2 == PosFmt.Ind
                pos2 = obj.conv_sub_ind(pos1);
            else
                error('Invalid: %s to %s', char(fmt1), char(fmt2));
            end
        end
        
        function n = numel(obj)
            %n = NUMEL(obj) Get element count
            n = obj.numel_;
        end
    end
    
    methods (Access = protected)
        function pos2 = conv_ind_sub(obj, pos1)
            %pos2 = CONV_IND_SUB(obj, pos1) Convert Ind to Sub
            pos2 = mod(ceil(obj.ind_to_sub * pos1 - 1), obj.size_.') + 1;
        end
        
        function pos2 = conv_sub_ind(obj, pos1)
            %pos2 = CONV_SUB_IND(obj, pos1) Convert Sub to Ind
            pos2 = dot(obj.sub_to_ind, pos1 - 1) + 1;
        end
    end
    
    methods (Access = protected, Static)
        function [pos1, fmt1, fmt2] = fmt_conv_args(pos1, fmt1, fmt2)
            %[pos1, fmt1, fmt2] = FMT_CONV_ARGS(pos1, fmt1, fmt2)
            %   Format args of conv methods
            import('multi_array.PosFmt');
            if isrow(pos1), pos1 = pos1.'; end
            if isa(fmt1, 'char'), fmt1 = PosFmt(fmt1); end
            if isa(fmt2, 'char'), fmt2 = PosFmt(fmt2); end
        end
    end
end