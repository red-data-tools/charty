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
    # @param orient  Orientation of the plot (vertical or horizontal).
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
                 orient: nil, key_color: nil, palette: nil, saturation: 0.75,
                 error_color: 0.26, error_width: nil, cap_size: nil, dodge: true,
                 **options, &block)
      Plotters::BarPlotter.new(
        data: data, variables: { x: x, y: y, color: color },
        order: order, orient: nil,
        estimator: estimator, ci: ci, n_boot: n_boot, units: units, random: random,
        color_order: color_order, key_color: key_color, palette: palette, saturation: saturation,
        error_color: error_color, error_width: error_width,
        cap_size: cap_size, dodge: dodge,
        **options, &block
      )
    end

    def box_plot(x: nil, y: nil, color: nil, **options, &block)
      Plotters::BoxPlotter.new(x, y, color, **options, &block)
    end
  end

  extend PlotMethods
end
