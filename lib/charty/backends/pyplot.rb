require 'fileutils'

module Charty
  module Backends
    class Pyplot
      Backends.register(:pyplot, self)

      class << self
        def prepare
          require 'matplotlib/pyplot'
          require 'numpy'
        end
      end

      def initialize
        @pyplot = ::Matplotlib::Pyplot
        @default_edgecolor = Colors["white"].to_rgb
        @default_line_width = ::Matplotlib.rcParams["lines.linewidth"]
        @default_marker_size = ::Matplotlib.rcParams["lines.markersize"]
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

      def old_style_render(context, filename)
        plot(@pyplot, context)
        if filename
          FileUtils.mkdir_p(File.dirname(filename))
          @pyplot.savefig(filename)
        end
        @pyplot.show
      end

      def old_style_save(context, filename, finish: true)
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
        options[:lw] = error_width || @default_line_width * 1.8

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

      def scatter(x, y, variables, color:, color_mapper:,
                  style:, style_mapper:, size:, size_mapper:)
        kwd = {}
        kwd[:edgecolor] = "w"

        ax = @pyplot.gca
        points = ax.scatter(x.to_a, y.to_a, **kwd)

        unless color.nil?
          color = color_mapper[color].map(&:to_hex_string)
          points.set_facecolors(color)
        end

        unless size.nil?
          size = size_mapper[size].map {|x| scale_scatter_point_size(x).to_f }
          points.set_sizes(size)
        end

        unless style.nil?
          paths = style_mapper[style, :marker].map(&method(:marker_to_path))
          points.set_paths(paths)
        end

        sizes = points.get_sizes
        points.set_linewidths(0.08 * Numpy.sqrt(Numpy.percentile(sizes, 10)))
      end

      def add_scatter_plot_legend(variables, color_mapper, size_mapper, style_mapper, legend)
        ax = @pyplot.gca
        add_relational_plot_legend(
          ax, variables, color_mapper, size_mapper, style_mapper,
          legend, [:color, :s, :marker]
        ) do |label, kwargs|
          ax.scatter([], [], label: label, **kwargs)
        end
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
              hexagon: [6, 0, 0].freeze,
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

      RELATIONAL_PLOT_LEGEND_BRIEF_TICKS = 6

      private def add_relational_plot_legend(ax, variables, color_mapper, size_mapper, style_mapper,
                                             verbosity, legend_attributes, &func)
        brief_ticks = RELATIONAL_PLOT_LEGEND_BRIEF_TICKS
        verbosity = :auto if verbosity == true

        legend_titles = Util.filter_map([:color, :size, :style]) {|v| variables[v] }
        legend_title = legend_titles.pop if legend_titles.length == 1

        legend_kwargs = {}
        update_legend = ->(var_name, val_name, **kw) do
          key = [var_name, val_name]
          if legend_kwargs.key?(key)
            legend_kwargs[key].update(kw)
          else
            legend_kwargs[key] = kw
          end
        end

        title_kwargs = {visible: false, color: "w", s: 0, linewidth: 0, marker: "", dashes: ""}

        # color legend

        brief_color = (color_mapper.map_type == :numeric) && (
                        (verbosity == :brief) || (
                          verbosity == :auto && color_mapper.levels.length > brief_ticks
                        )
                      )
        case
        when brief_color
          # TODO: Also support LogLocator
          # locator = Matplotlib.ticker.LogLocator.new(numticks: brief_ticks)
          locator = Matplotlib.ticker.MaxNLocator.new(nbins: brief_ticks)
          limits = color_mapper.levels.minmax
          color_levels, color_formatted_levels = locator_to_legend_entries(locator, limits)
        when color_mapper.levels.nil?
          color_levels = color_formatted_levels = []
        else
          color_levels = color_formatted_levels = color_mapper.levels
        end

        if legend_title.nil? && variables.key?(:color)
          update_legend.([variables[:color], :title], variables[:color], **title_kwargs)
        end

        color_levels.length.times do |i|
          next if color_levels[i].nil?
          color_value = color_mapper[color_levels[i]].to_rgb.to_hex_string
          update_legend.(variables[:color], color_formatted_levels[i], color: color_value)
        end

        brief_size = (size_mapper.map_type == :numeric) && (
                       verbosity == :brief ||
                       (verbosity == :auto && size_mapper.levels.length > brief_ticks)
                     )
        case
        when brief_size
          # TODO: Also support LogLocator
          # locator = Matplotlib.ticker.LogLocator(numticks: brief_ticks)
          locator = Matplotlib.ticker.MaxNLocator.new(nbins: brief_ticks)
          limits = size_mapper.levels.minmax
          size_levels, size_formatted_levels = locator_to_legend_entries(locator, limits)
        when size_mapper.levels.nil?
          size_levels = size_formatted_levels = []
        else
          size_levels = size_formatted_levels = size_mapper.levels
        end

        if legend_title.nil? && variables.key?(:size)
          update_legend.([variables[:size], :title], variables[:size], **title_kwargs)
        end

        size_levels.length.times do |i|
          next if size_levels[i].nil?
          line_width = scale_line_width(size_mapper[size_levels[i]])
          point_size = scale_scatter_point_size(size_mapper[size_levels[i]])
          update_legend.(variables[:size], size_formatted_levels[i], linewidth: line_width, s: point_size)
        end

        if legend_title.nil? && variables.key?(:style)
          update_legend.([variables[:style], :title], variables[:style], **title_kwargs)
        end

        unless style_mapper.levels.nil?
          style_mapper.levels.each do |level|
            next if level.nil?
            attrs = style_mapper[level]
            marker = if attrs.key?(:marker)
                       PYPLOT_MARKERS[attrs[:marker]]
                     else
                       ""
                     end
            dashes = if attrs.key?(:dashes)
                       attrs[:dashes]
                     else
                       ""
                     end
            update_legend.(variables[:style], level, marker: marker, dashes: dashes)
          end
        end

        legend_kwargs.each do |key, kw|
          _, label = key
          kw[:color] ||= ".2"
          use_kw = Util.filter_map(legend_attributes) {|attr|
            [attr, kw[attr]] if kw.key?(attr)
          }.to_h
          use_kw[:visible] = kw[:visible] if kw.key?(:visible)
          func.(label, use_kw)
        end

        handles = ax.get_legend_handles_labels()[0].to_a
        unless handles.empty?
          legend = ax.legend(title: legend_title || "")
          adjust_legend_subtitles(legend)
        end
      end

      private def scale_scatter_point_size(x)
        min = 0.5 * @default_marker_size**2
        max = 2.0 * @default_marker_size**2

        min + x * (max - min)
      end

      def line(x, y, variables, color:, color_mapper:, size:, size_mapper:, style:, style_mapper:, ci_params:)
        kws = {
          markeredgewidth: 0.75,
          markeredgecolor: "w",
        }
        ax = @pyplot.gca

        x = x.to_a
        y = y.to_a
        x = x.collect(&:to_s) if x[0].is_a?(Time)
        lines = ax.plot(x, y, **kws)

        lines.each do |line|
          unless color.nil?
            line.set_color(color_mapper[color].to_rgb.to_hex_string)
          end

          unless size.nil?
            scaled_size = scale_line_width(size_mapper[size])
            line.set_linewidth(scaled_size.to_f)
          end

          unless style.nil?
            attributes = style_mapper[style]
            if attributes.key?(:dashes)
              line.set_dashes(attributes[:dashes])
            end
            if attributes.key?(:marker)
              line.set_marker(PYPLOT_MARKERS[attributes[:marker]])
            end
          end
        end

        # TODO: support color, size, and style

        line = lines[0]
        line_color = line.get_color
        line_alpha = line.get_alpha
        line_capstyle = line.get_solid_capstyle

        unless ci_params.nil?
          y_min = ci_params[:y_min].to_a
          y_max = ci_params[:y_max].to_a
          case ci_params[:style]
          when :band
            # TODO: support to supply `alpha` via `err_kws`
            ax.fill_between(x, y_min, y_max, color: line_color, alpha: 0.2)
          when :bars
            error_deltas = [
              y.zip(y_min).map {|v, v_min| v - v_min },
              y.zip(y_max).map {|v, v_max| v_max - v }
            ]
            ebars = ax.errorbar(x, y, error_deltas,
                                linestyle: "", color: line_color, alpha: line_alpha)
            ebars.get_children.each do |bar|
              case bar
              when Matplotlib.collections.LineCollection
                bar.set_capstyle(line_capstyle)
              end
            end
          end
        end
      end

      def add_line_plot_legend(variables, color_mapper, size_mapper, style_mapper, legend)
        ax = @pyplot.gca
        add_relational_plot_legend(
          ax, variables, color_mapper, size_mapper, style_mapper,
          legend, [:color, :linewidth, :marker, :dashes]
        ) do |label, kwargs|
          ax.plot([], [], label: label, **kwargs)
        end
      end


      private def scale_line_width(x)
        min = 0.5 * @default_line_width
        max = 2.0 * @default_line_width

        min + x * (max - min)
      end

      def univariate_histogram(hist, name, variable_name, stat,
                               alpha, color, key_color, color_mapper,
                               multiple, element, fill, shrink)
        mid_points = hist.edges.each_cons(2).map {|a, b| a + (b - a) / 2 }
        orient = variable_name == :x ? :v : :h
        width = shrink * (hist.edges[1] - hist.edges[0])

        kw = {align: :edge}

        color = if color.nil?
                  key_color.to_rgb
                else
                  color_mapper[color].to_rgb
                end

        alpha = 1r unless fill

        if fill
          kw[:facecolor] = color.to_rgba(alpha: alpha).to_hex_string
          if multiple == :stack || multiple == :fill || element == :bars
            kw[:edgecolor] = @default_edgecolor.to_hex_string
          else
            kw[:edgecolor] = color.to_hex_string
          end
        elsif element == :bars
          kw.delete(:facecolor)
          kw[:edgecolor] = color.to_rgba(alpha: alpha).to_hex_string
        else
          kw[:color] = color.to_rgba(alpha: alpha).to_hex_string
        end

        kw[:label] = name unless name.nil?

        ax = @pyplot.gca
        if orient == :v
          ax.bar(mid_points, hist.weights, width, **kw)
        else
          ax.barh(mid_points, hist.weights, width, **kw)
        end
      end

      private def locator_to_legend_entries(locator, limits)
        vmin, vmax = limits
        dtype = case vmin
                when Numeric
                  :float64
                else
                  :object
                end
        raw_levels = locator.tick_values(vmin, vmax).astype(dtype).to_a
        raw_levels.reject! {|v| v < limits[0] || limits[1] < v }

        formatter = case locator
                    when Matplotlib.ticker.LogLocator
                      Matplotlib.ticker.LogFormatter.new
                    else
                      Matplotlib.ticker.ScalarFormatter.new
                    end

        dummy_axis = Object.new
        dummy_axis.define_singleton_method(:get_view_interval) { limits }
        formatter.axis =  dummy_axis

        formatter.set_locs(raw_levels)
        formatted_levels = raw_levels.map {|x| formatter.(x) }

        return raw_levels, formatted_levels
      end

      private def adjust_legend_subtitles(legend)
        font_size = Matplotlib.rcParams.get("legend.title_fontsize", nil)
        hpackers = legend.findobj(Matplotlib.offsetbox.VPacker)[0].get_children()
        hpackers.each do |hpack|
          draw_area, text_area = hpack.get_children()
          handles = draw_area.get_children()
          unless handles.all? {|a| a.get_visible() }
            draw_area.set_width(0)
            unless font_size.nil?
              text_area.get_children().each do |text|
                text.set_size(font_size)
              end
            end
          end
        end
      end

      def set_title(title)
        @pyplot.gca.set_title(String(title))
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

      def set_xscale(scale)
        scale = check_scale_type(scale, :xscale)
        @pyplot.gca.set_xscale(scale)
      end

      def set_yscale(scale)
        scale = check_scale_type(scale, :yscale)
        @pyplot.gca.set_yscale(scale)
      end

      private def check_scale_type(val, name)
        case
        when :linear, :log
          val
        else
          raise ArgumentError,
                "Invalid #{name} type: %p" % val,
                caller
        end
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

      def render(notebook: false)
        show
        nil
      end

      def render_mimebundle(include: [], exclude: [])
        show
        {}
      end

      SAVEFIG_OPTIONAL_PARAMS = [
        :dpi, :quality, :optimize, :progressive, :facecolor, :edgecolor,
        :orientation, :papertype, :transparent, :bbox_inches, :pad_inches,
        :bbox_extra_artists, :backend, :metadata, :pil_kwargs
      ].freeze

      def save(filename, format: nil, title: nil, width: 700, height: 500, **kwargs)
        params = {}
        params[:format] = format unless format.nil?
        SAVEFIG_OPTIONAL_PARAMS.each do |key|
          params[key] = kwargs[key] if kwargs.key?(key)
        end
        @pyplot.savefig(filename, **params)
        @pyplot.close
      end

      def show
        @pyplot.show
      end
    end
  end
end
