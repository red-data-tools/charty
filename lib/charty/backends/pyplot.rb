require 'fileutils'

module Charty
  module Backends
    class Pyplot
      Backends.register(:pyplot, self)

      class << self
        def prepare
          require 'matplotlib/pyplot'
        end
      end

      def initialize
        @pyplot = ::Matplotlib::Pyplot
      end

      def self.activate_iruby_integration
        require 'matplotlib/iruby'
        ::Matplotlib::IRuby.activate
      end

      def label(x, y)
      end

      def series=(series)
        @series = series
      end

      def render_layout(layout)
        _fig, axes = @pyplot.subplots(nrows: layout.num_rows, ncols: layout.num_cols)
        layout.rows.each_with_index do |row, y|
          row.each_with_index do |cel, x|
            plot = layout.num_rows > 1 ? axes[y][x] : axes[x]
            plot(plot, cel, subplot: true)
          end
        end
        @pyplot.show
      end

      def render(context, filename)
        plot(context)
        if filename
          FileUtils.mkdir_p(File.dirname(filename))
          @pyplot.savefig(filename)
        end
        @pyplot.show
      end

      def save(context, filename)
        plot(context)
        if filename
          FileUtils.mkdir_p(File.dirname(filename))
          @plot.savefig(filename)
        end
      end

      def plot(context, subplot: false)
        # TODO: Since it is not required, research and change conditions.
        # case
        # when @pyplot.respond_to?(:xlim)
        #   @pyplot.xlim(context.range_x.begin, context.range_x.end)
        #   @pyplot.ylim(context.range_y.begin, context.range_y.end)
        # when @pyplot.respond_to?(:set_xlim)
        #   @pyplot.set_xlim(context.range_x.begin, context.range_x.end)
        #   @pyplot.set_ylim(context.range_y.begin, context.range_y.end)
        # end

        @pyplot.title(context.title) if context.title
        if !subplot
          @pyplot.xlabel(context.xlabel) if context.xlabel
          @pyplot.ylabel(context.ylabel) if context.ylabel
        end

        case context.method
        when :bar
          context.series.each do |data|
            @pyplot.bar(data.xs.to_a.map(&:to_s), data.ys.to_a, label: data.label)
          end
          @pyplot.legend()
        when :barh
          context.series.each do |data|
            @pyplot.barh(data.xs.to_a.map(&:to_s), data.ys.to_a)
          end
        when :box_plot
          @pyplot.boxplot(context.data.to_a, labels: context.labels)
        when :bubble
          context.series.each do |data|
            @pyplot.scatter(data.xs.to_a, data.ys.to_a, s: data.zs.to_a, alpha: 0.5, label: data.label)
          end
          @pyplot.legend()
        when :curve
          context.series.each do |data|
            @pyplot.plot(data.xs.to_a, data.ys.to_a)
          end
        when :scatter
          context.series.each do |data|
            @pyplot.scatter(data.xs.to_a, data.ys.to_a, label: data.label)
          end
          @pyplot.legend()
        when :error_bar
          context.series.each do |data|
            @pyplot.errorbar(
              data.xs.to_a,
              data.ys.to_a,
              data.xerr,
              data.yerr,
              label: data.label,
            )
          end
          @pyplot.legend()
        when :hist
          @pyplot.hist(context.data.to_a)
        end
      end
    end
  end
end
