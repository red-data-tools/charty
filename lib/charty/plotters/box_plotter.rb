module Charty
  module Plotters
    class BoxPlotter < CategoricalPlotter
      self.default_palette = :light
      self.require_numeric = true

      def initialize(data: nil, variables: {}, **options, &block)
        x, y, color = variables.values_at(:x, :y, :color)
        super(x, y, color, data: data, **options, &block)
      end

      attr_reader :flier_size

      def flier_size=(val)
        @flier_size = check_number(val, :flier_size, allow_nil: true)
      end

      attr_reader :line_width

      def line_width=(val)
        @line_width = check_number(val, :line_width, allow_nil: true)
      end

      attr_reader :whisker

      def whisker=(val)
        @whisker = check_number(val, :whisker, allow_nil: true)
      end

      def render(notebook: false)
        backend = Backends.current
        backend.begin_figure
        draw_box_plot(backend)
        annotate_axes(backend)
        backend.invert_yaxis if orient == :h
        backend.render(notebook: notebook)
      end

      # TODO:
      # - Should infer mime type from file's extname
      # - Should check backend's supported mime type before begin_figure
      def save(filename, **opts)
        backend = Backends.current
        backend.begin_figure
        draw_box_plot(backend)
        annotate_axes(backend)
        backend.invert_yaxis if orient == :h
        backend.save(filename, **opts)
      end

      private def draw_box_plot(backend)
        if @plot_colors.nil?
          plot_data = @plot_data.map do |group_data|
            unless group_data.empty?
              group_data = group_data.drop_na
              group_data unless group_data.empty?
            end
          end

          backend.box_plot(plot_data,
                           @group_names,
                           orient: orient,
                           colors: @colors,
                           gray: @gray,
                           dodge: dodge,
                           width: @width,
                           flier_size: flier_size,
                           whisker: whisker)
        else
          grouped_box_data = @color_names.map.with_index do |color_name, i|
            @plot_data.map.with_index do |group_data, j|
              unless group_data.empty?
                color_mask = @plot_colors[j].eq(color_name)
                group_data = group_data[color_mask].drop_na
                group_data unless group_data.empty?
              end
            end
          end

          backend.grouped_box_plot(grouped_box_data,
                                   @group_names,
                                   @color_names,
                                   orient: orient,
                                   colors: @colors,
                                   gray: @gray,
                                   dodge: dodge,
                                   width: @width,
                                   flier_size: flier_size,
                                   whisker: whisker)
        end
      end
    end
  end
end
