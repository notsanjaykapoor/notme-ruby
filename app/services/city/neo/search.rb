# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module City
    module Neo

      Struct.new("PathShortest", :code, :dst_name, :path, :path_duration, :path_name, :src_name, keyword_init: true)
      Struct.new("PathsAll", :code, :paths, :paths_dropped, keyword_init: true)

      def self.search(session:, query:)
        if match = query.to_s.match(/^nodes?:([a-zA-z\s]+):(\d+)/)
          # e.g. nodes:chicago:2

          city_src = ::Model::City.find(name: match[1].titleize)
          max_depth = match[2]

          if not city_src
            return Struct::PathsAll.new(
              code: 404,
              paths: [],
              paths_dropped: 0,
            )
          end

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to anywhere depth #{max_depth} query")

          records = ::Service::City::Neo.path_bfs(
            session: session,
            city_src: city_src,
            max_depth: max_depth,
          )

          result = _search_nodes_filter(records: records, city_src: city_src)

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to anywhere depth #{max_depth} result - paths #{result.paths.length}, dropped #{result.paths_dropped}")

          result
        elsif match = query.to_s.match(/^paths?:([a-zA-z\s]+):([a-zA-z\s]+)(:\d+)?/)
          # e.g. path(s):chicago:new york
          # e.g. path(s):chicago:new york:2

          city_src = ::Model::City.find(name: match[1].titleize)
          city_dst = ::Model::City.find(name: match[2].titleize)

          if match[3]
            max_depth = match[3].gsub(":", "")
          else
            max_depth = 5
          end

          if not city_src or not city_dst
            return Struct::PathsAll.new(
              code: 404,
              paths: [],
              paths_dropped: 0,
            )
          end

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to #{city_dst.name} depth #{max_depth} query")

          records = ::Service::City::Neo.paths_all(
            session: session,
            city_src: city_src,
            city_dst: city_dst,
            max_depth: max_depth,
          )
        
          result = _search_paths_filter(records: records, city_src: city_src, city_dst: city_dst)

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to #{city_dst.name} depth #{max_depth} result - paths #{result.paths.length}, dropped #{result.paths_dropped}")

          result
        elsif match = query.to_s.match(/^shortest:([a-zA-z\s]+):([a-zA-z\s]+)/)
          # e.g. shortest:chicago:new york

          city_src = ::Model::City.find(name: match[1].titleize)
          city_dst = ::Model::City.find(name: match[2].titleize)

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to #{city_dst.name} shortest path query")

          result = Struct::PathShortest.new(
            code: 0,
            dst_name: "",
            src_name: "",
            path: nil,
            path_duration: 0,
            path_name: "",
          )

          record = ::Service::City::Neo.path_shortest(
            session: session,
            city_src: city_src,
            city_dst: city_dst,
            max_depth: 5,
          )

          result.dst_name = city_dst.name
          result.src_name = city_src.name
          result.path = record["path"]
          result.path_duration = record["duration"]
          result.path_name = ""

          Console.logger.info(self, "#{Thread.current[:rid]} #{city_src.name} to #{city_dst.name} shortest path result - duration #{result.path_duration}")

          result
        end
      end

      def self._search_nodes_filter(records:, city_src:)
        result = Struct::PathsAll.new(
          code: 0,
          paths: [],
          paths_dropped: 0,
        )

        # filter paths
        path_sigs = Set[]
        records.map do |record|
          path = record["path"]
          path_duration = record["duration"]

          # calculate path signature
          name_dst = ""
          path_sig_list = []

          path_name_list = path.map.with_index do |segment, i|
            name_dst = segment.end_node[:name]
            segment_duration = segment.relationship[:duration]
            path_sig_list.append("#{segment.start_node.id}:#{segment.end_node.id}")

            "#{segment.start_node[:name]}:#{segment.end_node[:name]}:#{segment_duration}"
          end

          path_sig = path_sig_list.join(":")

          if path_sigs.include?(path_sig)
            # duplicate path, drop it
            result.paths_dropped += 1
            next
          end

          result.paths.append({
            dst_name: name_dst,
            path: path,
            path_duration: path_duration,
            path_name: path_name_list.join(" - "),
            src_name: city_src.name,
          })
          path_sigs.add(path_sig)
        end

        result
      end
 
      def self._search_paths_filter(records:, city_src:, city_dst:)
        result = Struct::PathsAll.new(
          code: 0,
          paths: [],
          paths_dropped: 0,
        )

        # filter paths
        path_sigs = Set[]
        records.map do |record|
          path = record["path"]
          path_duration = record["duration"]

          # calculate path signature and end nodes
          path_drop = 0
          path_sig_list = []

          path_name_list = path.map.with_index do |segment, i|
            segment_duration = segment.relationship[:duration]
            path_sig_list.append("#{segment.start_node.id}:#{segment.end_node.id}")

            if (segment.end_node.properties[:name] == city_dst.name) and (i != path.length-1)
              # end node is node we want but there are more segments; skip this path
              path_drop = 1
            end

            if (segment.start_node.properties[:name] == city_src.name) and (i > 0)
              # start node is node is not the first path in this segment; skip this path
              path_drop = 1
            end

            "#{segment.start_node[:name]}:#{segment.end_node[:name]}:#{segment_duration}"
          end

          path_sig = path_sig_list.join(":")

          if path_sigs.include?(path_sig) or path_drop == 1
            # duplicate path, drop it
            result.paths_dropped += 1
            next
          end

          result.paths.append({
            dst_name: city_dst.name,
            path: path,
            path_duration: path_duration,
            path_name: path_name_list.join(" - "),
            src_name: city_src.name,
          })
          path_sigs.add(path_sig)
        end

        result
      end

    end
  end
end