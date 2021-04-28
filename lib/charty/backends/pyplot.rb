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
          Array(context.data).each_with_index do |group_data, i|
            next if group_data.empty?

            box_data = group_data.compact
            next if box_data.empty?

            color = colors.next
            draw_box_plot(box_data, vert: "v", position: i, color: color,
                          gray: gray, width: 0.8, whisker: 1.5, flier_size: 5)
          end
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

      # ==== NEW PLOTTING API ====

      def begin_figure
        @legend_keys = []
        @legend_labels = []
      end

      def bar(bar_pos, _group_names, values, colors, orient, label: nil, width: 0.8r,
              align: :center, conf_int: nil, error_colors: nil, error_width: nil, cap_size: nil)
        bar_pos = Array(bar_pos)
        values = Array(values)
        colors = Array(colors).map(&:to_hex_string)
        width = Float(width)

        ax = @pyplot.gca
        kw = {color: colors, align: align}
        kw[:label] = label unless label.nil?

        if orient == :v
          ax.bar(bar_pos, values, width, **kw)
        else
          ax.barh(bar_pos, values, width, **kw)
        end

        if conf_int
          error_colors = Array(error_colors).map(&:to_hex_string)
          confidence_intervals(ax, bar_pos, conf_int, orient, error_colors, error_width, cap_size)
        end
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

      def box_plot(plot_data, group_names,
                   orient:, colors:, gray:, dodge:, width: 0.8r,
                   flier_size: 5, whisker: 1.5, notch: false)
        colors = Array(colors).map(&:to_hex_string)
        gray = gray.to_hex_string
        width = Float(width)
        flier_size = Float(flier_size)
        whisker = Float(whisker)

        plot_data.each_with_index do |group_data, i|
          unless group_data.nil?
            draw_box_plot(group_data,
                          vert: (orient == :v),
                          position: i,
                          color: colors[i],
                          gray: gray,
                          width: width,
                          whisker: whisker,
                          flier_size: flier_size)
          end
        end
      end

      def grouped_box_plot(plot_data, group_names, color_names,
                           orient:, colors:, gray:, dodge:, width: 0.8r,
                           flier_size: 5, whisker: 1.5, notch: false)
        colors = Array(colors).map(&:to_hex_string)
        gray = gray.to_hex_string
        width = Float(width)
        flier_size = Float(flier_size)
        whisker = Float(whisker)

        offsets = color_offsets(color_names, dodge, width)
        orig_width = width
        width = Float(nested_width(color_names, dodge, width))

        color_names.each_with_index do |color_name, i|
          add_box_plot_legend(gray, colors[i], color_names[i])

          plot_data[i].each_with_index do |group_data, j|
            next if group_data.empty?

            position = j + offsets[i]
            draw_box_plot(group_data,
                          vert: (orient == :v),
                          position: position,
                          color: colors[i],
                          gray: gray,
                          width: width,
                          whisker: whisker,
                          flier_size: flier_size)
          end
        end
      end

      private def add_box_plot_legend(gray, color, name)
        patch = @pyplot.Rectangle.new([0, 0], 0, 0, edgecolor: gray, facecolor: color, label: name)
        @pyplot.gca.add_patch(patch)
      end

      private def draw_box_plot(group_data, vert:, position:, color:, gray:, width:, whisker:, flier_size:)
        # TODO: Do not convert to Array when group_data is Pandas::Series or Numpy::NDArray,
        # and use MemoryView if available when group_data is Numo::NArray
        artist_dict = @pyplot.boxplot(Array(group_data),
                                      vert: vert,
                                      patch_artist: true,
                                      positions: [position],
                                      widths: width,
                                      whis: whisker)

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
            markersize: flier_size
          }, {})
        end
      end

      private def color_offsets(color_names, dodge, width)
        n_names = color_names.length
        if dodge
          each_width = width / n_names
          offsets = Charty::Linspace.new(0 .. (width - each_width), n_names).to_a
          mean = Statistics.mean(offsets)
          offsets.map {|x| x - mean }
        else
          Array.new(n_names, 0)
        end
      end

      private def nested_width(color_names, dodge, width)
        if dodge
          width.to_r / color_names.length * 0.98r
        else
          width
        end
      end

      def scatter(x, y, color=nil, marker=nil, size=nil)
        kwd = {}
        kwd[:edgecolor] = "w"

        ax = @pyplot.gca
        points = ax.scatter(x.to_a, y.to_a, **kwd)

        unless color.nil?
          color = color.map(&:to_hex_string)
          points.set_facecolors(color)
        end

        unless size.nil?
          points.set_sizes(size)
        end

        unless marker.nil?
          paths = marker.map(&method(:marker_to_path))
          points.set_paths(paths)
        end

        sizes = points.get_sizes
        points.set_linewidths(0.08 * Numpy.sqrt(Numpy.percentile(sizes, 10)))
      end

      PYPLOT_MARKERS = {
               circle: "o",
                    x: "X",
                cross: "P",
          triangle_up: "^",
        triangle_down: "v",
               square: [4, 0, 45].freeze,
              diamond: [4, 0, 0].freeze,
                 star: [5, 1, 0].freeze,
         star_diamond: [4, 1, 0].freeze,
          star_square: [4, 1, 45].freeze,
             pentagon: [5, 0, 0].freeze,
              hexagon: [6, 0, 0].freeze
      }.freeze

      private def marker_to_path(marker)
        @path_cache ||= {}
        if @path_cache.key?(marker)
          @path_cache[marker]
        elsif PYPLOT_MARKERS.key?(marker)
          val = PYPLOT_MARKERS[marker]
          ms = Matplotlib.markers.MarkerStyle.new(val)
          @path_cache[marker] = ms.get_path().transformed(ms.get_transform())
        else
          raise ArgumentError, "Unknown marker name: %p" % marker
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

      def invert_yaxis
        @pyplot.gca.invert_yaxis
      end

      def legend(loc:, title:)
        @pyplot.gca.legend(loc: loc, title: title)
      end

      def show
        @pyplot.show
      end
    end
  end
end
