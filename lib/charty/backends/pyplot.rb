require 'matplotlib/pyplot'

module Charty
  class PyPlot < PlotterAdapter
    Name = "pyplot"

    def initialize
      @plot = Matplotlib::Pyplot
    end

    def self.activate_iruby_integration
      require 'matplotlib/iruby'
      Matplotlib::IRuby.activate
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
          plot(plot, cel, subplot: true)
        end
      end
      @plot.show
    end

    def render(context, filename)
      plot(@plot, context)
      if filename
        FileUtils.mkdir_p(File.dirname(filename))
        @plot.savefig(filename)
      end
      @plot.show
    end

    def save(context, filename)
      plot(@plot, context)
      if filename
        FileUtils.mkdir_p(File.dirname(filename))
        @plot.savefig(filename)
      end
    end

    def plot(plot, context, subplot: false)
      # TODO: Since it is not required, research and change conditions.
      # case
      # when plot.respond_to?(:xlim)
      #   plot.xlim(context.range_x.begin, context.range_x.end)
      #   plot.ylim(context.range_y.begin, context.range_y.end)
      # when plot.respond_to?(:set_xlim)
      #   plot.set_xlim(context.range_x.begin, context.range_x.end)
      #   plot.set_ylim(context.range_y.begin, context.range_y.end)
      # end

      plot.title(context.title) if context.title
      if !subplot
        plot.xlabel(context.xlabel) if context.xlabel
        plot.ylabel(context.ylabel) if context.ylabel
      end

      case context.method
      when :bar
        context.series.each do |data|
          plot.bar(data.xs.to_a.map(&:to_s), data.ys.to_a, label: data.label)
        end
        plot.legend()
      when :barh
        context.series.each do |data|
          plot.barh(data.xs.to_a.map(&:to_s), data.ys.to_a)
        end
      when :box_plot
        plot.boxplot(context.data.to_a, labels: context.labels)
      when :bubble
        context.series.each do |data|
          plot.scatter(data.xs.to_a, data.ys.to_a, s: data.zs.to_a, alpha: 0.5, label: data.label)
        end
        plot.legend()
      when :curve
        context.series.each do |data|
          plot.plot(data.xs.to_a, data.ys.to_a)
        end
      when :scatter
        context.series.each do |data|
          plot.scatter(data.xs.to_a, data.ys.to_a, label: data.label)
        end
        plot.legend()
      when :error_bar
        context.series.each do |data|
          plot.errorbar(
            data.xs.to_a,
            data.ys.to_a,
            data.xerr,
            data.yerr,
            label: data.label,
          )
        end
        plot.legend()
      when :hist
        plot.hist(context.data.to_a)
      end
    end
  end
end
