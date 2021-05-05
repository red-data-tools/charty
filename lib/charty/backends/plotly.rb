require "json"
require "securerandom"

module Charty
  module Backends
    class Plotly
      Backends.register(:plotly, self)

      attr_reader :context

      class << self
        attr_writer :chart_id, :with_api_load_tag, :plotly_src

        def chart_id
          @chart_id ||= 0
        end

        def with_api_load_tag
          return @with_api_load_tag unless @with_api_load_tag.nil?

          @with_api_load_tag = true
        end

        def plotly_src
          @plotly_src ||= 'https://cdn.plot.ly/plotly-latest.min.js'
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
        context = context
        self.class.chart_id += 1

        case context.method
        when :bar
          render_graph(context, :bar)
        when :curve
          render_graph(context, :scatter)
        when :scatter
          render_graph(context, nil, options: {data: {mode: "markers"}})
        else
          raise NotImplementedError
        end
      end

      private def plotly_load_tag
        if self.class.with_api_load_tag
          "<script type='text/javascript' src='#{self.class.plotly_src}'></script>"
        else
        end
      end

      private def div_id
        "charty-plotly-#{self.class.chart_id}"
      end

      private def div_style
        "width: 100%;height: 100%;"
      end

      private def render_graph(context, type, options: {})
        data = context.series.map do |series|
          {
            type: type,
            x: series.xs.to_a,
            y: series.ys.to_a,
            name: series.label
          }.merge(options[:data] || {})
        end
        layout = {
          title: { text: context.title },
          xaxis: {
            title: context.xlabel,
            range: [context.range[:x].first, context.range[:x].last]
          },
          yaxis: {
            title: context.ylabel,
            range: [context.range[:y].first, context.range[:y].last]
          }
        }
        render_html(data, layout)
      end

      private def render_html(data, layout)
        <<~FRAGMENT
          #{plotly_load_tag unless self.class.chart_id > 1}
          <div id="#{div_id}" style="#{div_style}"></div>
          <script>
            Plotly.plot('#{div_id}', #{JSON.dump(data)}, #{JSON.dump(layout)} );
          </script>
        FRAGMENT
      end

      # ==== NEW PLOTTING API ====

      class HTML
        def initialize(html)
          @html = html
        end

        def to_iruby
          ["text/html", @html]
        end
      end

      def begin_figure
        @traces = []
        @layout = {showlegend: false}
      end

      def bar(bar_pos, values, colors, orient, label: nil, width: 0.8r, align: :center,
              conf_int: nil, error_colors: nil, error_width: nil, cap_size: nil)
        bar_pos = Array(bar_pos)
        values = Array(values)
        colors = Array(colors).map(&:to_hex_string)
        errors_low = conf_int.map.with_index {|(low, _), i| values[i] - low }
        errors_high = conf_int.map.with_index {|(_, high), i| high - values[i] }
        error_colors = Array(error_colors).map(&:to_hex_string)

        if orient == :v
          x, y = bar_pos, values
        else
          x, y = values, bar_pos
        end

        error_bar = {
          type: :data,
          visible: true,
          symmetric: false,
          array: errors_high,
          arrayminus: errors_low,
          color: error_colors[0]
        }
        error_bar[:thickness] = error_width unless error_width.nil?
        error_bar[:width] = cap_size unless cap_size.nil?
        error_bar_key = orient == :v ? :error_y : :error_x

        trace = {
          type: :bar,
          orientation: orient,
          x: x,
          y: y,
          width: width,
          marker: {color: colors},
          "#{error_bar_key}": error_bar
        }
        trace[:name] = label unless label.nil?

        @traces << trace
      end

      def box_plot(plot_data, positions, color, orient, gray:,
                   width: 0.8r, flier_size: 5, whisker: 1.5, notch: false)
        color = Array(color).map(&:to_hex_string)
        plot_data.each_with_index do |group_data, i|
          var_name = orient == :v ? :y : :x
          data = if group_data.empty?
                   {type: :box, "#{var_name}": [] }
                 else
                   {type: :box, "#{var_name}": Array(group_data), marker: {color: color[i]}}
                 end
          data[:orientation] = orient
          @traces << data
        end
      end

      def set_xlabel(label)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:title] = label
      end

      def set_ylabel(label)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:title] = label
      end

      def set_xticks(values)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:tickmode] = "array"
        @layout[:xaxis][:tickvals] = values
      end

      def set_yticks(values)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:tickmode] = "array"
        @layout[:yaxis][:tickvals] = values
      end

      def set_xtick_labels(labels)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:tickmode] = "array"
        @layout[:xaxis][:ticktext] = labels
      end

      def set_ytick_labels(labels)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:tickmode] = "array"
        @layout[:yaxis][:ticktext] = labels
      end

      def set_xlim(min, max)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:range] = [min, max]
      end

      def set_ylim(min, max)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:range] = [min, max]
      end

      def disable_xaxis_grid
        # do nothing
      end

      def disable_yaxis_grid
        # do nothing
      end

      def legend(loc:, title:)
        @layout[:showlegend] = true
        @layout[:legend] = {
          title: {
            text: title
          }
        }
        # TODO: Handle loc
      end

      def save(filename, title: nil)
        html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
          <meta charset="utf-8">
          <title>%{title}</title>
          <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
          </head>
          <body>
          <div id="%{id}" style="width: 100%%; height:100%%;"></div>
          <script type="text/javascript">
          Plotly.newPlot("%{id}", %{data}, %{layout});
          </script>
          </body>
          </html>
        HTML
        html %= {
          title: title || default_html_title,
          id: SecureRandom.uuid,
          data: JSON.dump(@traces),
          layout: JSON.dump(@layout)
        }
        File.write(filename, html)
        nil
      end

      private def default_html_title
        "Charty plot"
      end

      def show
        unless defined?(IRuby)
          raise NotImplementedError,
                "Plotly backend outside of IRuby is not supported"
        end

        IRubyOutput.prepare

        html = <<~HTML
          <div id="%{id}" style="width: 100%%; height:100%%;"></div>
          <script type="text/javascript">
            requirejs(["plotly"], function (Plotly) {
              Plotly.newPlot("%{id}", %{data}, %{layout});
            });
          </script>
        HTML

        html %= {
          id: SecureRandom.uuid,
          data: JSON.dump(@traces),
          layout: JSON.dump(@layout)
        }
        IRuby.display(html, mime: "text/html")
        nil
      end

      module IRubyOutput
        @prepared = false

        def self.prepare
          return if @prepared

          html = <<~HTML
            <script type="text/javascript">
              %{win_config}
              %{mathjax_config}
              require.config({
                paths: {
                  plotly: "https://cdn.plot.ly/plotly-latest.min"
                }
              });
            </script>
          HTML

          html %= {
            win_config: window_plotly_config,
            mathjax_config: mathjax_config
          }

          IRuby.display(html, mime: "text/html")
          @prepared = true
        end

        def self.window_plotly_config
          <<~END
            window.PlotlyConfig = {MathJaxConfig: 'local'};
          END
        end


        def self.mathjax_config
          <<~END
            if (window.MathJax) {MathJax.Hub.Config({SVG: {font: "STIX-Web"}});}
          END
        end
      end
    end
  end
end
