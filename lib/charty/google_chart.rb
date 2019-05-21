module Charty
  class GoogleChart < PlotterAdapter
    Name = "google_chart"
    attr_reader :context

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

      case context.method
      when :bar
        generate_render_js("BarChart")
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
          context.series.each_with_index do |_series_data, index|
            header << index
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
          context.series.each_with_index do |series_data, series_index|
            x_labels.sort.each do |x_label|
              unless hash[x_label]
                hash[x_label] = []
              end

              if data_index = series_data.xs.index(x_label)
                hash[x_label] << series_data.ys[data_index]
              else
                hash[x_label] << 0
              end
            end
          end
        end
      end

      def formatted_data_array
        [headers.map(&:to_s)].tap do |data_array|
          data_hash.each do |k, v|
            data_array << [k.to_s, v].flatten
          end
        end
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
                  title: "#{context.xlabel}"
                },
                hAxis: {
                  title: "#{context.ylabel}"
                },
                legend: { position: "none" },
              };
              const chart = new google.visualization.#{chart_type}(document.getElementById("barchart_values"));
              chart.draw(view, options);
            }
          </script>
          <div id="barchart_values" style="width: 900px; height: 300px;"></div>
        JS
      end
  end
end
