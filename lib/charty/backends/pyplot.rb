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
            ax = layout.num_rows > 1 ? axes[y][x] : axes[x]
            plot(ax, cel, subplot: true)
          end
        end
        @pyplot.show
      end

      def render(context, filename)
        plot(@pyplot, context)
        if filename
          FileUtils.mkdir_p(File.dirname(filename))
          @pyplot.savefig(filename)
        end
        @pyplot.show
      end

      def save(context, filename, finish: true)
        plot(context)
        if filename
          FileUtils.mkdir_p(File.dirname(filename))
          @pyplot.savefig(filename)
        end
        @pyplot.clf if finish
      end

      def plot(ax, context, subplot: false)
        # TODO: Since it is not required, research and change conditions.
        # case
        # when @pyplot.respond_to?(:xlim)
        #   @pyplot.xlim(context.range_x.begin, context.range_x.end)
        #   @pyplot.ylim(context.range_y.begin, context.range_y.end)
        # when @pyplot.respond_to?(:set_xlim)
        #   @pyplot.set_xlim(context.range_x.begin, context.range_x.end)
        #   @pyplot.set_ylim(context.range_y.begin, context.range_y.end)
        # end

        ax.title(context.title) if context.title
        if !subplot
          ax.xlabel(context.xlabel) if context.xlabel
          ax.ylabel(context.ylabel) if context.ylabel
        end

        palette = Palette.default
        colors = palette.colors.map {|c| c.to_rgb.to_hex_string }.cycle
        case context.method
        when :bar
          context.series.each do |data|
            ax.bar(data.xs.to_a.map(&:to_s), data.ys.to_a, label: data.label,
                   color: colors.next)
          end
          ax.legend()
        when :barh
          context.series.each do |data|
            ax.barh(data.xs.to_a.map(&:to_s), data.ys.to_a, color: colors.next)
          end
        when :box_plot
          min_l = palette.colors.map {|c| c.to_rgb.to_hsl.l }.min
          lum = min_l*0.6
          gray = Colors::RGB.new(lum, lum, lum).to_hex_string
          draw_box_plot(context, subplot, colors, gray)
        when :bubble
          context.series.each do |data|
            ax.scatter(data.xs.to_a, data.ys.to_a, s: data.zs.to_a, alpha: 0.5,
                       color: colors.next, label: data.label)
          end
          ax.legend()
        when :curve
          context.series.each do |data|
            ax.plot(data.xs.to_a, data.ys.to_a, color: colors.next)
          end
        when :scatter
          context.series.each do |data|
            ax.scatter(data.xs.to_a, data.ys.to_a, label: data.label,
                       color: colors.next)
          end
          ax.legend()
        when :error_bar
          context.series.each do |data|
            ax.errorbar(
              data.xs.to_a,
              data.ys.to_a,
              data.xerr,
              data.yerr,
              label: data.label,
              color: colors.next
            )
          end
          ax.legend()
        when :hist
          data = Array(context.data)
          ax.hist(data, color: colors.take(data.length), alpha: 0.4)
        end
      end

      private def draw_box_plot(context, subplot, colors, gray)
        Array(context.data).each_with_index do |group_data, i|
          next if group_data.empty?

          box_data = group_data.compact
          next if box_data.empty?

          artist_dict = @pyplot.boxplot(box_data, vert: "v", patch_artist: true,
                                        positions: [i], widths: 0.8)

          color = colors.next
          artist_dict["boxes"].each do |box|
            box.update({facecolor: color, zorder: 0.9, edgecolor: gray}, {})
          end
          artist_dict["whiskers"].each do |whisker|
            whisker.update({color: gray, linestyle: "-"}, {})
          end
          artist_dict["caps"].each do |cap|
            cap.update({color: gray}, {})
          end
          artist_dict["medians"].each do |median|
            median.update({color: gray}, {})
          end
          artist_dict["fliers"].each do |flier|
            flier.update({
              markerfacecolor: gray,
              marker: "d",
              markeredgecolor: gray,
              markersize: 5
            }, {})
          end
        end
      end

      # ==== NEW PLOTTING API ====

      def begin_figure
        # do nothing
      end

      def bar(bar_pos, values, colors, orient, width: 0.8r, align: :center,
              conf_int: nil, error_colors: nil, error_width: nil, cap_size: nil)
        bar_pos = Array(bar_pos)
        values = Array(values)
        colors = Array(colors).map(&:to_hex_string)
        width = Float(width)
        error_colors = Array(error_colors).map(&:to_hex_string)

        ax = @pyplot.gca
        if orient == :v
          ax.bar(bar_pos, values, width, color: colors, align: align)
        else
          ax.barh(bar_pos, values, width, color: colors, align: align)
        end

        confidence_intervals(ax, bar_pos, conf_int, orient, error_colors, error_width, cap_size)
      end

      private def confidence_intervals(ax, at_group, conf_int, orient, colors, error_width=nil, cap_size=nil, **options)
        options[:lw] = error_width || Matplotlib.rcParams["lines.linewidth"] * 1.8

        at_group.each_index do |i|
          at = at_group[i]
          ci_low, ci_high = conf_int[i]
          color = colors[i]

          if orient == :v
            ax.plot([at, at], [ci_low, ci_high], color: color, **options)
            unless cap_size.nil?
              ax.plot([at - cap_size / 2.0, at + cap_size / 2.0], [ci_low,  ci_low],  color: color, **options)
              ax.plot([at - cap_size / 2.0, at + cap_size / 2.0], [ci_high, ci_high], color: color, **options)
            end
          else
            ax.plot([ci_low, ci_high], [at, at], color: color, **options)
            unless cap_size.nil?
              ax.plot([ci_low,  ci_low],  [at - cap_size / 2.0, at + cap_size / 2.0], color: color, **options)
              ax.plot([ci_high, ci_high], [at - cap_size / 2.0, at + cap_size / 2.0], color: color, **options)
            end
          end
        end
      end

      def box_plot(plot_data, positions, color:, gray:,
                   width: 0.8r, flier_size: 5, whisker: 1.5, notch: false)
        color = Array(color).map(&:to_hex_string)
        gray = gray.to_hex_string
        width = Float(width)
        flier_size = Float(flier_size)
        whisker = Float(whisker)
        plot_data.each_with_index do |group_data, i|
          next if group_data.nil? || group_data.empty?

          # TODO: Do not convert to Array when group_data is Pandas::Series or Numpy::NDArray,
          # and use MemoryView if available when group_data is Numo::NArray
          artist_dict = @pyplot.boxplot(Array(group_data),
                                        vert: :v,
                                        patch_artist: true,
                                        positions: [i],
                                        widths: width,
                                        whis: whisker, )

          artist_dict["boxes"].each do |box|
            box.update({facecolor: color[i], zorder: 0.9, edgecolor: gray}, {})
          end
          artist_dict["whiskers"].each do |whisker|
            whisker.update({color: gray, linestyle: "-"}, {})
          end
          artist_dict["caps"].each do |cap|
            cap.update({color: gray}, {})
          end
          artist_dict["medians"].each do |median|
            median.update({color: gray}, {})
          end
          artist_dict["fliers"].each do |flier|
            flier.update({
              markerfacecolor: gray,
              marker: "d",
              markeredgecolor: gray,
              markersize: flier_size
            }, {})
          end
        end
      end

      def set_xlabel(label)
        @pyplot.gca.set_xlabel(String(label))
      end

      def set_ylabel(label)
        @pyplot.gca.set_ylabel(String(label))
      end

      def set_xticks(values)
        @pyplot.gca.set_xticks(Array(values))
      end

      def set_yticks(values)
        @pyplot.gca.set_yticks(Array(values))
      end

      def set_xtick_labels(labels)
        @pyplot.gca.set_xticklabels(Array(labels).map(&method(:String)))
      end

      def set_ytick_labels(labels)
        @pyplot.gca.set_yticklabels(Array(labels).map(&method(:String)))
      end

      def set_xlim(min, max)
        @pyplot.gca.set_xlim(Float(min), Float(max))
      end

      def set_ylim(min, max)
        @pyplot.gca.set_ylim(Float(min), Float(max))
      end

      def disable_xaxis_grid
        @pyplot.gca.xaxis.grid(false)
      end

      def disable_yaxis_grid
        @pyplot.gca.xaxis.grid(false)
      end

      def show
        @pyplot.show
      end
    end
  end
end
