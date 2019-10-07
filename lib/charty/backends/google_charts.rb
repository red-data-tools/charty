module Charty
  module Backends
    class GoogleCharts
      Backends.register(:google_charts, self)

      attr_reader :context

      class << self
        attr_writer :chart_id, :google_charts_src, :with_api_load_tag

        def chart_id
          @chart_id ||= 0
        end

        def with_api_load_tag
          return @with_api_load_tag unless @with_api_load_tag.nil?

          @with_api_load_tag = true
        end

        def google_charts_src
          @google_charts_src ||= 'https://www.gstatic.com/charts/loader.js'
        end
      end

      def initilize
      end

      def label(x, y)
      end

      def series=(series)
        @series = series
      end

      def render(context, filename)
        plot(nil, context)
      end

      def plot(plot, context)
        @context = context
        self.class.chart_id = self.class.chart_id + 1

        case context.method
        when :bar
          generate_render_js("ColumnChart")
        when :barh
          generate_render_js("BarChart")
        when :scatter
          generate_render_js("ScatterChart")
        when :bubble
          generate_render_js("BubbleChart")
        when :curve
          generate_render_js("LineChart")
        else
          raise NotImplementedError
        end
      end

      private

        def google_charts_load_tag
          if self.class.with_api_load_tag
            "<script type='text/javascript' src='#{self.class.google_charts_src}'></script>"
          else
            nil
          end
        end

        def data_column_js
          case context.method
          when :bubble
            schema = [
              ["string", "ID"],
              ["number", "X"],
              ["number", "Y"],
              ["string", "GROUP"],
              ["number", "SIZE"],
            ]
          when :curve
            schema = []
            schema << [detect_type(context.series.first.xs), context.xlabel]
            context.series.to_a.each_with_index do |series_data, index|
              schema << ["number", series_data.label || index]
            end
          else
            schema = ["string", context.xlabel]
            context.series.to_a.each_with_index do |series_data, index|
              schema << ["number", series_data.label || index]
            end
          end

          columns = schema.collect do |type, label|
            "data.addColumn(#{type.to_json}, #{label.to_s.to_json});"
          end
          columns.join
        end

        def detect_type(values)
          case values.first
          when Time
            "date"
          when String
            "string"
          else
            "number"
          end
        end

        def x_labels
          labels = {}
          have_string = false
          context.series.each do |series|
            series.xs.each do |x|
              next if labels.key?(x)
              have_string = true if x.is_a?(String)
              labels[x] = true
            end
          end
          if have_string
            labels.keys.sort_by {|label| "%10s" % x.to_s}
          else
            labels.keys.sort
          end
        end

        def data_hash
          {}.tap do |hash|
            _x_labels = x_labels
            context.series.to_a.each_with_index do |series_data, series_index|
              _x_labels.each do |x_label|
                unless hash[x_label]
                  hash[x_label] = []
                end

                if data_index = series_data.xs.to_a.index(x_label)
                  hash[x_label] << series_data.ys.to_a[data_index]
                else
                  hash[x_label] << nil
                end
              end
            end
          end
        end

        def rows
          case context.method
          when :bubble
            [].tap do |data_array|
              context.series.to_a.each_with_index do |series_data, series_index|
                series_data.xs.to_a.each_with_index do |data, data_index|
                  data_array << [
                    "",
                    series_data.xs.to_a[data_index],
                    series_data.ys.to_a[data_index],
                    series_data[:label] || series_index.to_s,
                    series_data.zs.to_a[data_index],
                  ]
                end
              end
            end
          when :curve
            [].tap do |data_array|
              data_hash.each do |k, v|
                data_array << [k, v].flatten
              end
            end
          else
            [].tap do |data_array|
              data_hash.each do |k, v|
                data_array << [k, v].flatten
              end
            end
          end
        end

        def convert_to_javascript(data)
          case data
          when Array
            converted_data = data.collect do |element|
              convert_to_javascript(element)
            end
            "[#{converted_data.join(", ")}]"
          when Time
            time = data.dup.utc
            args = [
              time.year,
              time.month - 1,
              time.day,
              time.hour,
              time.min,
              time.sec,
              time.nsec / 1000 / 1000,
            ]
            "new Date(Date.UTC(#{args.join(", ")}))"
          else
            data.to_json
          end
        end

        def x_range_option
          x_range = if context.method != :barh
                      context&.range&.fetch(:x, nil)
                    else
                      context&.range&.fetch(:y, nil)
                    end
          {
            max: x_range&.max,
            min: x_range&.min,
          }.reject { |_k, v| v.nil? }
        end

        def y_range_option
          y_range = if context.method != :barh
                      context&.range&.fetch(:y, nil)
                    else
                      context&.range&.fetch(:x, nil)
                    end
          {
            max: y_range&.max,
            min: y_range&.min,
          }.reject { |_k, v| v.nil? }
        end

        def generate_render_js(chart_type)
          js = <<-JS
            #{google_charts_load_tag unless self.class.chart_id > 1}
            <script type="text/javascript">
              google.charts.load("current", {packages:["corechart"]});
              google.charts.setOnLoadCallback(drawChart);
              function drawChart() {
                const data = new google.visualization.DataTable();
                #{data_column_js}
                data.addRows(#{convert_to_javascript(rows)})

                const view = new google.visualization.DataView(data);

                const options = {
                  title: "#{context.title}",
                  vAxis: {
                    title: "#{context.ylabel}",
                    viewWindow: {
                      max: #{y_range_option[:max] || "null"},
                      min: #{y_range_option[:min] || "null"},
                    },
                  },
                  hAxis: {
                    title: "#{context.xlabel}",
                    viewWindow: {
                      max: #{x_range_option[:max] || "null"},
                      min: #{x_range_option[:min] || "null"},
                    }
                  },
                  legend: { position: "none" },
                };
                const chart = new google.visualization.#{chart_type}(document.getElementById("#{chart_type}-#{self.class.chart_id}"));
                chart.draw(view, options);
              }
            </script>
            <div id="#{chart_type}-#{self.class.chart_id}" style="width: 900px; height: 300px;"></div>
          JS
          js.gsub!(/\"null\"/, 'null')
          js
        end
    end
  end
end
