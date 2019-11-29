module Charty
  module Plotters
    class BoxPlotter < CategoricalPlotter
      def render
        backend = Backends.current
        backend.begin_figure
        draw_box_plot(backend)
        annotate_axes(backend)
        backend.show
      end

      private def draw_box_plot(backend)
        plot_data = @plot_data.each do |group_data|
          next nil if group_data.empty?

          group_data = Array(group_data)
          remove_na!(group_data)

          group_data
        end
        backend.box_plot(plot_data, (0 ... @plot_data.length).to_a,
                         color: @colors, gray: @gray)
      end
    end
  end
end
