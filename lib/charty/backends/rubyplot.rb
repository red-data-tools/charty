require 'rubyplot'

module Charty
  class Rubyplot < PlotterAdapter
    Name = "rubyplot"

    def initialize
      @plot = ::Rubyplot
    end

    def label(x, y)
    end

    def series=(series)
      @series = series
    end

    def render_layout(layout)
      (fig, axes) = *@plot.subplots(nrows: layout.num_rows, ncols: layout.num_cols)
      layout.rows.each_with_index do |row, y|
        row.each_with_index do |cel, x|
          plot = layout.num_rows > 1 ? axes[y][x] : axes[x]
          plot(plot, cel)
        end
      end
      @plot.show
    end

    def render(context, filename="")
      FileUtils.mkdir_p(File.dirname(filename))
      plot(@plot, context).write(filename)
    end

    def plot(plot, context)
      # case
      # when plot.respond_to?(:xlim)
      #   plot.xlim(context.range_x.begin, context.range_x.end)
      #   plot.ylim(context.range_y.begin, context.range_y.end)
      # when plot.respond_to?(:set_xlim)
      #   plot.set_xlim(context.range_x.begin, context.range_x.end)
      #   plot.set_ylim(context.range_y.begin, context.range_y.end)
      # end

      figure = ::Rubyplot::Figure.new
      axes = figure.add_subplot 0,0
      axes.title = context.title if context.title
      axes.x_title = context.xlabel if context.xlabel
      axes.y_title = context.ylabel if context.ylabel

      case context.method
      when :bar
        context.series.each do |data|
          axes.bar! do |p|
            p.data(data.xs.to_a)
            p.label = data.label
          end
        end
        figure
      when :barh
        raise NotImplementedError
      when :box_plot
        raise NotImplementedError
      when :bubble
        context.series.each do |data|
          axes.bubble! do |p|
            p.data(data.xs.to_a, data.ys.to_a, data.zs.to_a)
            p.label = data.label if data.label
          end
        end
        figure
      when :curve
        context.series.each do |data|
          axes.line! do |p|
            p.data(data.xs.to_a, data.ys.to_a)
            p.label = data.label if data.label
          end
        end
        figure
      when :scatter
        context.series.each do |data|
          axes.scatter! do |p|
            p.data(data.xs.to_a, data.ys.to_a)
            p.label = data.label if data.label
          end
        end
        figure
      when :error_bar
        # refs. https://github.com/SciRuby/rubyplot/issues/26
        raise NotImplementedError
      when :hist
        raise NotImplementedError
      end
    end
  end
end
