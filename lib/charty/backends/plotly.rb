require 'json'

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
        @layout = {}
      end

      def bar(bar_pos, values, color: nil, width: 0.8r, align: :center, orient: :v)
        color = Array(color).map(&:to_hex_string)
        @traces << {
          type: :bar,
          x: bar_pos,
          y: values,
          marker: {color: color}
        }
        @layout[:showlegend] = false
      end

      def box_plot(plot_data, positions, color:, gray:,
                   width: 0.8r, flier_size: 5, whisker: 1.5, notch: false)
        color = Array(color).map(&:to_hex_string)
        plot_data.each_with_index do |group_data, i|
          data = if group_data.empty?
                   {type: :box, y: [] }
                 else
                   {type: :box, y: group_data, marker: {color: color[i]}}
                 end
          @traces << data
        end
        @layout[:showlegend] = false
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

      def set_xtick_labels(labels)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:tickmode] = "array"
        @layout[:xaxis][:ticktext] = labels
      end

      def set_xlim(min, max)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:range] = [min, max]
      end

      def disable_xaxis_grid
        # do nothing
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
