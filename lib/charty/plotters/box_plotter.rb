module Charty
  module Plotters
    class BoxPlotter < CategoricalPlotter
      self.default_palette = :light
      self.require_numeric = true

      def render
        backend = Backends.current
        backend.begin_figure
        draw_box_plot(backend)
        annotate_axes(backend)
        backend.invert_yaxis if orient == :h
        backend.show
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
            next nil if group_data.empty?
            group_data.drop_na
          end
          backend.box_plot(plot_data, nil, (0 ... @plot_data.length).to_a,
                           @colors, orient, gray: @gray)
        else
          offsets = self.color_offsets
          # TODO: move to categorical plotter
          nested_width = if self.dodge
                           @width / @color_names.length * 0.98r
                         else
                           @width
                         end
          @color_names.each_with_index do |color_name, i|
            # TODO: Add legend data

            plot_data = @plot_data.map.with_index do |group_data, j|
              next nil if group_data.empty?

              color_mask = @plot_colors[j].eq(color_name)
              box_data = group_data[color_mask].drop_na

              if box_data.empty?
                nil
              else
                box_data
              end
            end

            centers = (0 ... @plot_data.length).map {|x| x + offsets[i] }
            colors = Array.new(plot_data.length) { @colors[i] }
            backend.box_plot(plot_data, @group_names, centers, colors, orient,
                             label: color_name, gray: @gray, width: nested_width)
          end
        end
      end
    end
  end
end
