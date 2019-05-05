require 'gruff'

module Charty
  class Gruff
    def initialize
      @plot = ::Gruff
    end

    def label(x, y)
    end

    def series=(series)
      @series = series
    end

    def render_layout(layout)
      raise NotImplementedError
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

      case context.method
      when :bar
        p = plot::Bar.new
        p.title = context.title if context.title
        p.x_axis_label = context.xlabel if context.xlabel
        p.y_axis_label = context.ylabel if context.ylabel
        context.series.each do |data|
          p.data(data.label, data.xs.to_a)
        end
        p
      when :barh
        p = plot::SideBar.new
        p.title = context.title if context.title
        p.x_axis_label = context.xlabel if context.xlabel
        p.y_axis_label = context.ylabel if context.ylabel
        context.series.each do |data|
          p.data(data.label, data.xs.to_a)
        end
        p.labels = {nil=>nil}
        p
      when :box_plot
        # refs. https://github.com/topfunky/gruff/issues/155
        raise NotImplementedError
      when :bubble
        raise NotImplementedError
      when :curve
        p = plot::Line.new
        p.title = context.title if context.title
        p.x_axis_label = context.xlabel if context.xlabel
        p.y_axis_label = context.ylabel if context.ylabel
        context.series.each do |data|
          p.data(data.label, data.xs.to_a)
        end
        p
      when :scatter
        p = plot::Scatter.new
        p.title = context.title if context.title
        p.x_axis_label = context.xlabel if context.xlabel
        p.y_axis_label = context.ylabel if context.ylabel
        context.series.each do |data|
          p.data(data.label, data.xs.to_a, data.ys.to_a)
        end
        p
      when :error_bar
        # refs. https://github.com/topfunky/gruff/issues/163
        raise NotImplementedError
      when :hist
        raise NotImplementedError
      end
    end
  end
end
