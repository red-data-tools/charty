module Charty
  module PlotMethods
    # Show the given data as rectangular bars.
    #
    # @param x  x-dimension input for plotting long-form data.
    # @param y  y-dimension input for plotting long-form data.
    # @param color  color-dimension input for plotting long-form data.
    # @param data  Dataset for plotting.
    # @param order  Order of the categorical dimension to plot the categorical levels in.
    # @param color_order  Order of the color dimension to plot the categorical levels in.
    # @param estimator  Statistical function to estimate withint each categorical bin.
    # @param ci  Size of confidence intervals to draw around estimated values.
    # @param n_boot  The size of bootstrap sample to use when computing confidence intervals.
    # @param units  Identifier of sampling unit.
    # @param random  Random seed or random number generator for reproducible bootstrapping.
    # @param orient  Orientation of the plot (:v for vertical, or :h for
    #        horizontal).
    # @param key_color  Color for all of the elements, or seed for a gradient palette.
    # @param palette  Colors to use for the different levels of the color-dimension variable.
    # @param saturation  Propotion of the original saturation to draw colors.
    # @param error_color  Color for the lines that represent the confidence intervals.
    # @param error_width  Thickness of error bar lines (and caps).
    # @param cap_size  Width of the caps on error bars.
    # @param dodge  [true,false]  If true, bar position is shifted along the
    #        categorical axis for avoid overlapping when the color-dimension is used.
    def bar_plot(x: nil, y: nil, color: nil, data: nil,
                 order: nil, color_order: nil,
                 estimator: :mean, ci: 95, n_boot: 1000, units: nil, random: nil,
                 orient: nil, key_color: nil, palette: nil, saturation: 1r,
                 error_color: [0.26, 0.26, 0.26], error_width: nil, cap_size: nil,
                 dodge: true, **options, &block)
      Plotters::BarPlotter.new(
        data: data, variables: { x: x, y: y, color: color },
        order: order, orient: orient,
        estimator: estimator, ci: ci, n_boot: n_boot, units: units, random: random,
        color_order: color_order, key_color: key_color, palette: palette, saturation: saturation,
        error_color: error_color, error_width: error_width, cap_size: cap_size,
        dodge: dodge,
        **options, &block
      )
    end

    def count_plot(x: nil, y: nil, color: nil, data: nil,
                   order: nil, color_order: nil,
                   orient: nil, key_color: nil, palette: nil, saturation: 1r,
                   dodge: true, **options, &block)
      case
      when x.nil? && !y.nil?
        x = y
        orient = :h
      when y.nil? && !x.nil?
        y = x
        orient = :v
      when !x.nil? && !y.nil?
        raise ArgumentError,
              "Unable to pass both x and y to count_plot"
      end

      Plotters::CountPlotter.new(
        data: data,
        variables: { x: x, y: y, color: color },
        order: order,
        orient: orient,
        estimator: :count,
        ci: nil,
        units: nil,
        random: nil,
        color_order: color_order,
        key_color: key_color,
        palette: palette,
        saturation: saturation,
        dodge: dodge,
        **options
      ) do |plotter|
        plotter.value_label = "count"
        block.(plotter) unless block.nil?
      end
    end

    # Show the distributions of the given data by boxes and whiskers.
    #
    # @param x  X-dimension input for plotting long-Form data.
    # @param y  Y-dimension input for plotting long-form data.
    # @param color  Color-dimension input for plotting long-form data.
    # @param data  Dataset for plotting.
    # @param order  Order of the categorical dimension to plot the categorical
    #        levels in.
    # @param color_order  Order of the color dimension to plot the categorical
    #        levels in.
    # @param orient  Orientation of the plot (:v for vertical, or :h for
    #        horizontal).
    # @param key_color  Color for all of the elements, or seed for a gradient
    #        palette.
    # @param palette  Colors to use for the different levels of the
    #        color-dimension variable.
    # @param saturation  Propotion of the original saturation to draw colors.
    # @param width  Width of a full element when not using the color-dimension,
    #        or width of all the elements for one level of the major grouping
    #        variable.
    # @param dodge  [true,false]  If true, bar position is shifted along the
    #        categorical axis for avoid overlapping when the color-dimension
    #        is used.
    # @param flier_size  Size of the markers used to indicate outlier
    #        observations.
    # @param line_width  Width of the gray lines that frame the plot elements.
    # @param whisker  Propotion of the IQR past the low and high quartiles to
    #        extend the plot whiskers.  Points outside of this range will be
    #        treated as outliers.
    def box_plot(x: nil, y: nil, color: nil, data: nil,
                 order: nil, color_order: nil,
                 orient: nil, key_color: nil, palette: nil, saturation: 1r,
                 width: 0.8r, dodge: true, flier_size: 5, line_width: nil,
                 whisker: 1.5, **options, &block)
      Plotters::BoxPlotter.new(
        data: data,
        variables: { x: x, y: y, color: color },
        order: order,
        color_order: color_order,
        orient: orient,
        key_color: key_color,
        palette: palette,
        saturation: saturation,
        width: width,
        dodge: dodge,
        flier_size: flier_size,
        line_width: line_width,
        whisker: whisker,
        **options,
        &block
      )
    end

    # Line plot
    #
    # @param x [vector-like object, key in data]
    # @param y [vector-like object, key in data]
    # @param color [vector-like object, key in data]
    # @param style [vector-like object, key in data]
    # @param size [vector-like object, key in data]
    # @param data [table-like object]
    # @param key_color [color object]
    # @param palette [String,Array<Numeric>,Palette]
    # @param color_order [Array<String>,Array<Symbol>]
    # @param color_norm
    # @param sizes [Array, Hash]
    # @param size_order [Array]
    # @param size_norm
    # @param dashes [true, false, Array, Hash]
    # @param markers [true, false, Array, Hash]
    # @param style_order [Array]
    # @param units [vector-like object, key in data]
    # @param estimator [:mean]
    # @param n_boot [Integer]
    # @param random [Integer, Random, nil]
    # @param sort [true, false]
    # @param err_style [:band, :bars]
    # @param err_params [Hash]
    # @param error_bar
    # @param x_scale [:linear, :log10]
    # @param y_scale [:linear, :log10]
    # @param legend [:auto, :brief, :full, false]
    #        How to draw legend.  If :brief, numeric color and size variables
    #        will be represented with a sample of evenly spaced values.  If
    #        :full, every group will get an entry in the legend.  If :auto,
    #        choose between brief or full representation based on number of
    #        levels.  If false, no legend data is added and no legend is drawn.
    def line_plot(x: nil, y: nil, color: nil, style: nil, size: nil,
                  data: nil, key_color: nil, palette: nil, color_order: nil,
                  color_norm: nil, sizes: nil, size_order: nil, size_norm: nil,
                  markers: nil, dashes: true, style_order: nil,
                  units: nil, estimator: :mean, n_boot: 1000, random: nil,
                  sort: true, err_style: :band, err_params: nil, error_bar: [:ci, 95],
                  x_scale: :linear, y_scale: :linear, legend: :auto, **options, &block)
      Plotters::LinePlotter.new(
        data: data,
        variables: { x: x, y: y, color: color, style: style, size: size },
        key_color: key_color,
        palette: palette,
        color_order: color_order,
        color_norm: color_norm,
        sizes: sizes,
        size_order: size_order,
        size_norm: size_norm,
        markers: markers,
        dashes: dashes,
        style_order: style_order,
        units: units,
        estimator: estimator,
        n_boot: n_boot,
        random: random,
        sort: sort,
        err_style: err_style,
        err_params: err_params,
        error_bar: error_bar,
        x_scale: x_scale,
        y_scale: y_scale,
        legend: legend,
        **options,
        &block
      )
    end

    # Scatter plot
    #
    # @param x [vector-like object, key in data]
    # @param y [vector-like object, key in data]
    # @param color [vector-like object, key in data]
    # @param style [vector-like object, key in data]
    # @param size [vector-like object, key in data]
    # @param data [table-like object]
    # @param key_color [color object]
    # @param palette [String,Array<Numeric>,Palette]
    # @param color_order [Array<String>,Array<Symbol>]
    # @param color_norm
    # @param sizes [Array, Hash]
    # @param size_order [Array]
    # @param size_norm
    # @param markers [true, false, Array, Hash]
    # @param style_order [Array]
    # @param alpha [scalar number]
    #        Propotional opacity of the points.
    # @param legend [:auto, :brief, :full, false]
    #        How to draw legend.  If :brief, numeric color and size variables
    #        will be represented with a sample of evenly spaced values.  If
    #        :full, every group will get an entry in the legend.  If :auto,
    #        choose between brief or full representation based on number of
    #        levels.  If false, no legend data is added and no legend is drawn.
    def scatter_plot(x: nil, y: nil, color: nil, style: nil, size: nil,
                     data: nil, key_color: nil, palette: nil, color_order: nil,
                     color_norm: nil, sizes: nil, size_order: nil, size_norm: nil,
                     markers: true, style_order: nil, alpha: nil, legend: :auto,
                     **options, &block)
      Plotters::ScatterPlotter.new(
        data: data,
        variables: { x: x, y: y, color: color, style: style, size: size },
        key_color: key_color,
        palette: palette,
        color_order: color_order,
        color_norm: color_norm,
        sizes: sizes,
        size_order: size_order,
        size_norm: size_norm,
        markers: markers,
        style_order: style_order,
        alpha: alpha,
        legend: legend,
        **options,
        &block
      )
    end

    def hist_plot(data: nil, x: nil, y: nil, color: nil, weights: nil,
                  stat: :count, bins: :auto,
                  common_bins: true,
                  key_color: nil, palette: nil, color_order: nil, color_norm: nil,
                  legend: true, **options, &block)
      # TODO: support following arguments
      # - wiehgts
      # - binwidth
      # - binrange
      # - discrete
      # - cumulative
      # - common_norm
      # - multiple
      # - element
      # - fill
      # - shrink
      # - kde
      # - kde_params
      # - line_params
      # - thresh
      # - pthresh
      # - pmax
      # - cbar
      # - cbar_params
      # - x_log_scale
      # - y_log_scale
      Plotters::HistogramPlotter.new(
        data: data,
        variables: { x: x, y: y, color: color },
        weights: weights,
        stat: stat,
        bins: bins,
        common_bins: common_bins,
        key_color: key_color,
        palette: palette,
        color_order: color_order,
        color_norm: color_norm,
        legend: legend,
        **options,
        &block)
    end
  end

  extend PlotMethods
end
