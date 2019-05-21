module Charty
  class GoogleChart < PlotterAdapter
    Name = "google_chart"
    attr_reader :context

    def self.chart_id=(chart_id)
      @chart_id = chart_id
    end

    def self.chart_id
      @chart_id ||= 0
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
        generate_render_js("BarChart")
      when :scatter
        generate_render_js("ScatterChart")
      when :bubble
        generate_render_js("BubbleChart")
      else
        raise NotImplementedError
      end
    end

    private

      def google_chart_load_tag
        "<script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>"
      end

      def headers
        [].tap do |header|
          header << context.xlabel
          context.series.to_a.each_with_index do |series_data, index|
            header << series_data.label || index
          end
        end
      end

      def x_labels
        [].tap do |label|
          context.series.each do |series|
            series.xs.each do |xs_data|
              label << xs_data unless label.any? { |label| label == xs_data }
            end
          end
        end
      end

      def data_hash
        {}.tap do |hash|
          context.series.to_a.each_with_index do |series_data, series_index|
            x_labels.sort.each do |x_label|
              unless hash[x_label]
                hash[x_label] = []
              end

              if data_index = series_data.xs.to_a.index(x_label)
                hash[x_label] << series_data.ys.to_a[data_index]
              else
                hash[x_label] << "null"
              end
            end
          end
        end
      end

      def formatted_data_array
        case context.method
        when :bubble
          [["ID", "X", "Y", "GROUP", "SIZE"]].tap do |data_array|
            context.series.to_a.each_with_index do |series_data, series_index|
              series_data.xs.to_a.each_with_index do |data, data_index|
                data_array << [
                  "",
                  series_data.xs.to_a[data_index] || "null",
                  series_data.ys.to_a[data_index] || "null",
                  series_data[:label] || series_index,
                  series_data.zs.to_a[data_index] || "null",
                ]
              end
            end
          end
        else
          [headers.map(&:to_s)].tap do |data_array|
            data_hash.each do |k, v|
              data_array << [k.to_s, v].flatten
            end
          end
        end
      end

      def x_range_option
        x_range = context&.range&.fetch(:x, nil)
        {
          max: x_range&.max,
          min: x_range&.min,
        }.reject { |_k, v| v.nil? }
      end

      def y_range_option
        y_range = context&.range&.fetch(:y, nil)
        {
          max: y_range&.max,
          min: y_range&.min,
        }.reject { |_k, v| v.nil? }
      end

      def generate_render_js(chart_type)
        js = <<-JS
          #{google_chart_load_tag}
          <script type="text/javascript">
            google.charts.load("current", {packages:["corechart"]});
            google.charts.setOnLoadCallback(drawChart);
            function drawChart() {
              const data = google.visualization.arrayToDataTable(
                #{formatted_data_array}
              );

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
      end
  end
end
