%> @file Mapping.m
%> @brief General class used for mapping on world map. Ideas is to extend
%> it so it can easily export to ArcGIS
%>
%> Some details on method here 
%>
%> @section matlabComments Details
%> @authors Eoin O Keeffe (eoin.okeeffe.09@ucl.ac.uk)
%> @date initiated: UNknown
%> <br /><i>Version 2.1</i>: 4/11/2013
%>
%> @version 
%> 1.0:  
%> <br />Version 2.0: Extending DrawRoutes so it integrates with Route
%> class
%> <br /><i>Version 2.1</i>: Include function to output to gephi
%>
%> @section intro Method
%>
%> @subsection InputData
%> 
%> @subsection Output
%>  map figures, shapefiles
%> @subsection keywords
%> mapping, GIS, ROutes
%> @attention 
%> @todo 
classdef Mapping <handle
    
    properties
        fig1
        mapData
    end
    
    methods
        function ShowWorld(obj)
            figure;
            worldmap world;
            geoshow('landareas.shp', 'FaceColor', [0.5 1.0 0.5]);
        end %function ShowWorld
        function ShowPoints(obj,long,lat)
            for i=1:size(long,1)
                geoshow(lat(i),long(i),...
                    'DisplayType', 'point',...
                    'Marker', 'o',...
                    'MarkerEdgeColor', 'r',...
                    'MarkerFaceColor', 'r',...
                    'MarkerSize', 3)
            end 
            
        end %function ShowPoint
        % ======================================================================
    %> @brief Draws route based on input from routes class
    %>
     %> @param obj instance of mapping class
    %> @param points list of points to map as route
    %> @param clearExisting [1] or empty for clear all, 0 otherwise
    
    % =====================================================================
        function DrawRoutes(obj,points,clearExisting) 
            if nargin == 2
               clearExisting = 1; 
            end
            %points = [origin_long(1) origing_lat(2) dest_long(3) dest_lat(4) origin_point_type(5) dest_point_type(6) ]
            %point types are 1 for origin point, 2 for way point, 3 for
            %dest point
            obj.getBackgroundMap;
            if ~isempty(obj.mapData) && clearExisting==1
                %clear existing map objects
                clmo(obj.mapData);
            else
                obj.mapData = [];
            end
            %First show the lines
            for i=1:size(points,1)
               obj.mapData = [obj.mapData;...
                   geoshow([points(i,2) points(i,4)],[points(i,1) points(i,3)],'DisplayType','line')];
            end %for i
            
            %Now show the points
            tmp_points = [points(:,1:2) points(:,5);points(:,3:4) points(:,6)];
            clr = 'r';
            for i=1:size(tmp_points,1)
                switch tmp_points(i,3)
                    case {1}
                    clr ='r';
                    case {2}
                        clr ='g';
                    otherwise
                        clr = 'b';
                end %switch
    obj.mapData = [obj.mapData;geoshow(tmp_points(i,2),tmp_points(i,1),...
                    'DisplayType', 'point',...
                    'Marker', 'o',...
                    'MarkerEdgeColor', 'w',...
                    'MarkerFaceColor', clr,...
                    'MarkerSize', 3)];
            end %for i
        end %function DrawRoutes
        function DisplayCommoditySources(obj,t,countries)
            %show the map first
            figure;
            worldmap world;
            geoshow('landareas.shp', 'FaceColor', [0.5 1.0 0.5]);
            %Now get the commodities and their port sources and the
            %associated long,lat
            geoshow(extractfield(countries.items,'Long'),extractfield(countries.items,'Lat'),...
                    'DisplayType', 'point',...
                    'Marker', 'o',...
                    'MarkerEdgeColor', 'r',...
                    'MarkerFaceColor', 'r',...
                    'MarkerSize', 3)
            text(-2.8,-1.8,'Goods exporters')
        end %function DisplayCOmmoditySources
        
        function getRouteMap(obj,routes,vertices)
            %show the map first
            obj.getBackgroundMap
            %Loop through and show each route
            for i=1:size(routes.items,1)
                %line(XData2,YData2,ZData2,'Parent',axes1,'Tag','Parallel','LineStyle',':',...
                 %   'Color',[0.75 0.75 0.75]);
                 originIndex = cell2mat(vertices.items(cell2mat(vertices.items(:,1))==cell2mat(routes.items(i,2)),1));
                 destIndex = cell2mat(vertices.items(cell2mat(vertices.items(:,1))==cell2mat(routes.items(i,3)),1));
                 if isnan(cell2mat(routes.items(i,4))) 
                     %Show each point
                     geoshow([cell2mat(vertices.items(originIndex,4));cell2mat(vertices.items(destIndex,4))],...
                         [cell2mat(vertices.items(originIndex,3));cell2mat(vertices.items(destIndex,3))],...
                        'DisplayType', 'point','Marker', 'o', 'MarkerEdgeColor', 'r',...
                        'MarkerFaceColor', 'r','MarkerSize', 3);
                    %Draw the line
                     geoshow([cell2mat(vertices.items(originIndex,4));cell2mat(vertices.items(destIndex,4))],[cell2mat(vertices.items(originIndex,3));cell2mat(vertices.items(destIndex,3))],'DisplayType','line');
                 else
                     viaIndex = vertices.items(cell2mat(vertices.items(:,1))==cell2mat(routes.items(i,4)));
                     %show the points first
                     geoshow([vertices.items(viaIndex,4);vertices.items(originIndex,4);vertices.items(destIndex,4)],...
                         [vertices.items(viaIndex,3);vertices.items(originIndex,3);vertices.items(destIndex,3)],...
                        'DisplayType', 'point','Marker', 'o', 'MarkerEdgeColor', 'r',...
                        'MarkerFaceColor', 'r','MarkerSize', 3);
                     %Now draw the lines
                    geoshow([vertices.items(originIndex,4);vertices.items(viaIndex,4)],[vertices.items(originIndex,3);vertices.items(viaIndex,3)],'DisplayType','line');
                    geoshow([vertices.items(viaIndex,4);vertices.items(destIndex,4)],[vertices.items(viaIndex,3);vertices.items(destIndex,3)],'DisplayType','line');
                 end %if
                 
            end %for i
        end %function getRouteMap
        
        %--------------------------------------------------------------
        %> @brief Outputs an adjacency matrix to a postgres database for
        %> importing into Gephi
        %> 
        %> @requires DataBasePG.m
        %> 
        %> @param edgesTable the name of the edges table
        %> @param nodesTable the name of the nodes table
        %> @param createNew [1|0] whether ot create a new table
        %> @param adjMatrix the adjacency matrix (it can be sparse) with the value representing the weighting 
        %> @param nodes dataset with fields id,label and size
        %-------------------------------------------------------------
        function outputToGephiDB(edgesTable,nodesTable,createNew,...
                adjMatrix,nodes,dbName)
%         edgesTable = sprintf('gephi_edges_%d_lsci_%d_%s_%s',year,...
%         vesselMapping.lsciThreshold,mfilename,datestr(now,'yyyymmdd'));
%     nodesTable = sprintf('gephi_nodes_%d_lsci_%d_%s_%s',year,...
%         vesselMapping.lsciThreshold,mfilename,datestr(now,'yyyymmdd'));
            db = DataBasePG;
            db.db = dbName;
            if createNew==1
                % Build the tables first
                sql = sprintf(['CREATE TABLE %s ('...
                    'id integer NOT NULL,'...
                      'label character varying(255),'...
                      'lon double precision,'...
                      'lat double precision,'...
                      'size double precision,'...
                      'CONSTRAINT primkey_%s PRIMARY KEY (id))',...
                    'WITH ( OIDS=FALSE);'...
                    'ALTER TABLE %s'...
                ' OWNER TO %s;'],nodesTable,nodesTable,nodesTable,Useful.getConfigProperty('dbuser'));

                

                db.executeQuery(sql);

                sql = sprintf(['CREATE SEQUENCE %s_seq_id'...
                    ' INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807'...
                    ' START 18920764 CACHE 1;'...
                    'ALTER TABLE %s_seq_id OWNER TO %s;'],edgesTable,edgesTable,...
                    Useful.getConfigProperty('dbuser'));

                db.executeQuery(sql);

                sql = sprintf(['CREATE TABLE %s ('...
                    'id integer NOT NULL DEFAULT nextval(''%s_seq_id''::regclass),'...
                      'source integer,'...
                      'target integer,'...
                      'weight double precision,'...
                      'distance double precision,'...
                      'CONSTRAINT primkey_%s PRIMARY KEY (id))',...
                    'WITH ( OIDS=FALSE);'...
                    'ALTER TABLE %s'...
                ' OWNER TO %s;'],edgesTable,edgesTable,edgesTable,edgesTable,Useful.getConfigProperty('dbuser'));
                      %'label character varying(255),'...
                db. executeQuery(sql);
            end %if
            
            %
            % Add the nodes 
            %

            fields = [{'id'};{'label'};{'size'}];
            db.runBlockInserts(fields,nodesTable,...
                [num2cell(nodes.id) nodes.label num2cell(nodes.size)],1000);
            
            % 
            % Add the edges
            %
    
            fields = [{'source'};{'target'};{'weight'};{'distance'}];
            [ii,jj,ss] = find(adjMatrix);
            db.runBlockInserts(fields,edgesTable,...
                [num2cell(nodes.id(ii)) num2cell(nodes.id(jj)) num2cell(ss)]...
                ,1000);
            
            disp('Insert complete');
    end %outputToGephiDB
    end
    
    methods (Hidden)
        function [fig,graphObj] = getBackgroundMap(obj)
                if isempty(obj.fig1)
                    obj.fig1 = figure;
                    worldmap world;
                    geoshow('landareas.shp', 'FaceColor', [0.5 1.0 0.5]);
                else 
                    set(0,'CurrentFigure',obj.fig1);
                end
        end %function getBackgroundMap
    end %methods hidden
    
end

