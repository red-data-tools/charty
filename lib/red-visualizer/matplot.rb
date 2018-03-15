require 'matplotlib/pyplot'
require 'matplotlib/iruby'

module RedVisualizer
  class Matplot
    def initialize
      @plot = Matplotlib::Pyplot
    end

    def self.notebook
      Matplotlib::IRuby.activate

      self.new
    end

    def label(x, y)

    end

    def series=(series)
      @series = series
    end

    def render_layout(layout)
      (fig, axes) = *@plot.subplots(nrows: layout.num_rows, ncols: layout.num_cols)
      layout.rows.each_with_index do |row, y|
        row.each_with_index {|cel, x| plot(axes[x + y * layout.num_cols], cel) }
      end
      @plot.show
    end

    def render(context)
      plot(@plot, context)
      @plot.show
    end

    def plot(plot, context)
      case
      when plot.respond_to?(:xlim)
        plot.xlim(context.range_x.begin, context.range_x.end)
        plot.ylim(context.range_y.begin, context.range_y.end)
      when plot.respond_to?(:set_xlim)
        plot.set_xlim(context.range_x.begin, context.range_x.end)
        plot.set_ylim(context.range_y.begin, context.range_y.end)
      end

      case context.method
      when :curve
        plot.plot(context.series.xs, context.series.ys)
      when :scatter
        plot.plot(context.series.xs, context.series.ys, ".")
      end
    end
  end
end
