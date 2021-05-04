module Charty
  module Plotters
    class BoxPlotter < CategoricalPlotter
      self.require_numeric = true

      def render
        backend = Backends.current
        backend.begin_figure
        draw_box_plot(backend)
        annotate_axes(backend)
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
        backend.save(filename, **opts)
      end

      private def draw_box_plot(backend)
        plot_data = @plot_data.map do |group_data|
          next nil if group_data.empty?
          group_data.drop_na
        end
        backend.box_plot(plot_data, (0 ... @plot_data.length).to_a,
                         @colors, orient, gray: @gray)
      end
    end
  end
end
