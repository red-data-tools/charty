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
    end
  end
end
