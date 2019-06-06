classdef OpenList < MinHeap
    %OPENLIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x = [];
        y = [];
        hCost = [];
    end
    
    methods
        
        %
        % Constructor
        %
        function this = OpenList(rows,columns)
            %----------------------- Constructor --------------------------
            % Syntax:       openList = OpenList(rows,columns);
            %               
            %               
            % Inputs:       rows the number of rows in the search area
            %               columns is the number of columns in the search
            %               area
         
            %               
            % Description:  Creates an open list for use in A* algorithm
            %               with maximum capacity = rows*columns/2
            %--------------------------------------------------------------
            
            % Call base class constructor
            this = this@MinHeap(round(rows*columns/2));

        end

        function add(this,node,fCost,hCost)
            % insert a new node
            %fprintf('Inserting node (%d,%d) to openList with id %d\n',node.x,node.y,this.nextId);
            this.InsertKey(fCost);
            this.x = [this.x, node.x];
            this.y = [this.y, node.y];
            this.hCost = [this.hCost, hCost];
            %fprintf('Size of open list increased from %d to %d.\n',this.size-1,this.size);
        end
        
        function node = getFirstAndRemove(this)
            % Get the node from the open list at the start of the open list and
            % then remove it from the open list
            node = struct('x',0,'y',0);
            [~,id] = this.ExtractMin();
            node.x = this.x(id);
            node.y = this.y(id);
        end
        
        function updateByCoordinates(this,node,gCost)
            % find by coordinates
            id = this.findFromCoordinates(node);
            i = find(this.ids==id);
            if (numel(i)>1)
                ii = i<=this.size;
                i = i(ii);
            end
            this.DecreaseKey(i,gCost + this.hCost(id));
        end
    end
    
    methods (Access = private)
        function id = findFromCoordinates(this,node)
            % find by coordinates
            id = find(this.x==node.x & this.y==node.y);
        end    
    end
    
end

