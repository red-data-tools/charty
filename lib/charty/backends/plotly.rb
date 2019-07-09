require 'json'
require 'securerandom'

module Charty
  class Plotly < PlotterAdapter
    Name = "plotly"
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
      context = context

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

    private

    def div_id
      "charty-plotly-#{SecureRandom.uuid}"
    end

    def div_style
      "width: 100%;height: 100%;"
    end

    def render_graph(context, type, options: {})
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

    def render_html(data, layout)
      id = div_id
      <<~FRAGMENT
        <script type='text/javascript' src="https://cdn.plot.ly/plotly-latest.min.js"></script>
        <div id="#{id}" style="#{div_style}"></div>
        <script>
          Plotly.plot('#{id}', #{JSON.dump(data)}, #{JSON.dump(layout)} );
        </script>
      FRAGMENT
    end
  end
end
