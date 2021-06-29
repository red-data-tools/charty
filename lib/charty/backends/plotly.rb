require "json"
require "securerandom"
require "tmpdir"

require_relative "plotly_helpers/html_renderer"
require_relative "plotly_helpers/notebook_renderer"
require_relative "plotly_helpers/plotly_renderer"

module Charty
  module Backends
    class Plotly
      Backends.register(:plotly, self)

      attr_reader :context

      class << self
        attr_writer :chart_id, :with_api_load_tag, :plotly_src

        def chart_id
          @chart_id ||= 0
        end

        def with_api_load_tag
          return @with_api_load_tag unless @with_api_load_tag.nil?

          @with_api_load_tag = true
        end

        def plotly_src
          @plotly_src ||= 'https://cdn.plot.ly/plotly-latest.min.js'
        end
      end

      def initilize
      end

      def label(x, y)
      end

      def series=(series)
        @series = series
      end

      def old_style_render(context, filename)
        plot(nil, context)
      end

      def plot(plot, context)
        context = context
        self.class.chart_id += 1

        case context.method
        when :bar
          render_graph(context, :bar)
        when :curve
          render_graph(context, :scatter)
        when :scatter
          render_graph(context, nil, options: {data: {mode: "markers"}})
        else
          raise NotImplementedError
        end
      end

      private def plotly_load_tag
        if self.class.with_api_load_tag
          "<script type='text/javascript' src='#{self.class.plotly_src}'></script>"
        else
        end
      end

      private def div_id
        "charty-plotly-#{self.class.chart_id}"
      end

      private def div_style
        "width: 100%;height: 100%;"
      end

      private def render_graph(context, type, options: {})
        data = context.series.map do |series|
          {
            type: type,
            x: series.xs.to_a,
            y: series.ys.to_a,
            name: series.label
          }.merge(options[:data] || {})
        end
        layout = {
          title: { text: context.title },
          xaxis: {
            title: context.xlabel,
            range: [context.range[:x].first, context.range[:x].last]
          },
          yaxis: {
            title: context.ylabel,
            range: [context.range[:y].first, context.range[:y].last]
          }
        }
        render_html(data, layout)
      end

      private def render_html(data, layout)
        <<~FRAGMENT
          #{plotly_load_tag unless self.class.chart_id > 1}
          <div id="#{div_id}" style="#{div_style}"></div>
          <script>
            Plotly.plot('#{div_id}', #{JSON.dump(data)}, #{JSON.dump(layout)} );
          </script>
        FRAGMENT
      end

      # ==== NEW PLOTTING API ====

      class HTML
        def initialize(html)
          @html = html
        end

        def to_iruby
          ["text/html", @html]
        end
      end

      def begin_figure
        @traces = []
        @layout = {showlegend: false}
      end

      def bar(bar_pos, group_names, values, colors, orient, label: nil, width: 0.8r,
              align: :center, conf_int: nil, error_colors: nil, error_width: nil, cap_size: nil)
        bar_pos = Array(bar_pos)
        values = Array(values)
        colors = Array(colors).map(&:to_hex_string)

        if orient == :v
          x, y = bar_pos, values
        else
          x, y = values, bar_pos
        end

        trace = {
          type: :bar,
          orientation: orient,
          x: x,
          y: y,
          width: width,
          marker: {color: colors}
        }
        trace[:name] = label unless label.nil?

        unless conf_int.nil?
          errors_low = conf_int.map.with_index {|(low, _), i| values[i] - low }
          errors_high = conf_int.map.with_index {|(_, high), i| high - values[i] }

          error_bar = {
            type: :data,
            visible: true,
            symmetric: false,
            array: errors_high,
            arrayminus: errors_low,
            color: error_colors[0].to_hex_string
          }
          error_bar[:thickness] = error_width unless error_width.nil?
          error_bar[:width] = cap_size unless cap_size.nil?

          error_bar_key = orient == :v ? :error_y : :error_x
          trace[error_bar_key] = error_bar
        end

        @traces << trace

        if group_names
          @layout[:barmode] = :group
        end
      end

      def box_plot(plot_data, group_names,
                   orient:, colors:, gray:, dodge:, width: 0.8r,
                   flier_size: 5, whisker: 1.5, notch: false)
        colors = Array(colors).map(&:to_hex_string)
        gray = gray.to_hex_string
        width = Float(width)
        flier_size = Float(width)
        whisker = Float(whisker)

        traces = plot_data.map.with_index do |group_data, i|
          group_data = Array(group_data)
          trace = {
            type: :box,
            orientation: orient,
            name: group_names[i],
            marker: {color: colors[i]}
          }
          if orient == :v
            trace.update(y: group_data)
          else
            trace.update(x: group_data)
          end

          trace
        end

        traces.reverse! if orient == :h

        @traces.concat(traces)
      end

      def grouped_box_plot(plot_data, group_names, color_names,
                           orient:, colors:, gray:, dodge:, width: 0.8r,
                           flier_size: 5, whisker: 1.5, notch: false)
        colors = Array(colors).map(&:to_hex_string)
        gray = gray.to_hex_string
        width = Float(width)
        flier_size = Float(width)
        whisker = Float(whisker)

        @layout[:boxmode] = :group

        if orient == :h
          @layout[:xaxis] ||= {}
          @layout[:xaxis][:zeroline] = false

          plot_data = plot_data.map {|d| d.reverse }
          group_names = group_names.reverse
        end

        traces = color_names.map.with_index do |color_name, i|
          group_keys = group_names.flat_map.with_index { |name, j|
            Array.new(plot_data[i][j].length, name)
          }.flatten

          values = plot_data[i].flat_map {|d| Array(d) }

          trace = {
            type: :box,
            orientation: orient,
            name: color_name,
            marker: {color: colors[i]}
          }

          if orient == :v
            trace.update(y: values, x: group_keys.map(&:to_s))
          else
            trace.update(x: values, y: group_keys.map(&:to_s))
          end

          trace
        end

        @traces.concat(traces)
      end

      def scatter(x, y, variables, color:, color_mapper:,
                  style:, style_mapper:, size:, size_mapper:)
        orig_x, orig_y = x, y

        x = case x
            when Charty::Vector
              x.to_a
            else
              Array.try_convert(x)
            end
        if x.nil?
          raise ArgumentError, "Invalid value for x: %p" % orig_x
        end

        y = case y
            when Charty::Vector
              y.to_a
            else
              Array.try_convert(y)
            end
        if y.nil?
          raise ArgumentError, "Invalid value for y: %p" % orig_y
        end

        unless color.nil? && style.nil?
          grouped_scatter(x, y, variables,
                          color: color, color_mapper: color_mapper,
                          style: style, style_mapper: style_mapper,
                          size: size, size_mapper: size_mapper)
          return
        end

        trace = {
          type: :scatter,
          mode: :markers,
          x: x,
          y: y,
          marker: {
            line: {
              width: 1,
              color: "#fff"
            },
            size: 10
          }
        }

        unless size.nil?
          trace[:marker][:size] = size_mapper[size].map {|x| 6.0 + x * 6.0 }
        end

        @traces << trace
      end

      private def grouped_scatter(x, y, variables, color:, color_mapper:,
                                  style:, style_mapper:, size:, size_mapper:)
        @layout[:showlegend] = true

        groups = (0 ... x.length).group_by do |i|
          key = {}
          key[:color] = color[i] unless color.nil?
          key[:style] = style[i] unless style.nil?
          key
        end

        groups.each do |group_key, indices|
          trace = {
            type: :scatter,
            mode: :markers,
            x: x.values_at(*indices),
            y: y.values_at(*indices),
            marker: {
              line: {
                width: 1,
                color: "#fff"
              },
              size: 10
            }
          }

          unless size.nil?
            vals = size.values_at(*indices)
            trace[:marker][:size] = size_mapper[vals].map do |x|
              scale_scatter_point_size(x).to_f
            end
          end

          name = []
          legend_title = []

          if group_key.key?(:color)
            trace[:marker][:color] = color_mapper[group_key[:color]].to_hex_string
            name << group_key[:color]
            legend_title << variables[:color]
          end

          if group_key.key?(:style)
            trace[:marker][:symbol] = style_mapper[group_key[:style], :marker]
            name << group_key[:style]
            legend_title << variables[:style]
          end

          trace[:name] = name.uniq.join(", ") unless name.empty?

          @traces << trace

          unless legend_title.empty?
            @layout[:legend] ||= {}
            @layout[:legend][:title] = {text: legend_title.uniq.join(", ")}
          end
        end
      end

      def add_scatter_plot_legend(variables, color_mapper, size_mapper, style_mapper, legend)
        if legend == :full
          warn("Plotly backend does not support full verbosity legend")
        end
      end

      private def scale_scatter_point_size(x)
        min = 6
        max = 12

        min + x * (max - min)
      end

      def line(x, y, variables, color:, color_mapper:, size:, size_mapper:, style:, style_mapper:, ci_params:)
        x = case x
            when Charty::Vector
              x.to_a
            else
              orig_x, x = x, Array.try_convert(x)
              if x.nil?
                raise ArgumentError, "Invalid value for x: %p" % orig_x
              end
            end

        y = case y
            when Charty::Vector
              y.to_a
            else
              orig_y, y = y, Array.try_convert(y)
              if y.nil?
                raise ArgumentError, "Invalid value for y: %p" % orig_y
              end
            end

        name = []
        legend_title = []

        if color.nil?
          # TODO: do not hard code this
          line_color = Colors["#1f77b4"] # the first color of D3's category10 palette
        else
          line_color = color_mapper[color].to_rgb
          name << color
          legend_title << variables[:color]
        end

        unless style.nil?
          marker, dashes = style_mapper[style].values_at(:marker, :dashes)
          name << style
          legend_title << variables[:style]
        end

        trace = {
          type: :scatter,
          mode: marker.nil? ? "lines" : "lines+markers",
          x: x,
          y: y,
          line: {
            shape: :linear,
            color: line_color.to_hex_string
          }
        }

        default_line_width = 2.0
        unless size.nil?
          line_width = default_line_width + 2.0 * size_mapper[size]
          trace[:line][:width] = line_width
        end

        unless dashes.nil?
          trace[:line][:dash] = convert_dash_pattern(dashes, line_width || default_line_width)
        end

        unless marker.nil?
          trace[:marker] = {
            line: {
              width: 1,
              color: "#fff"
            },
            symbol: marker,
            size: 10
          }
        end

        unless ci_params.nil?
          case ci_params[:style]
          when :band
            y_min = ci_params[:y_min].to_a
            y_max = ci_params[:y_max].to_a
            @traces << {
              type: :scatter,
              x: x,
              y: y_max,
              mode: :lines,
              line: { shape: :linear, width: 0 },
              showlegend: false
            }
            @traces << {
              type: :scatter,
              x: x,
              y: y_min,
              mode: :lines,
              line: { shape: :linear, width: 0 },
              fill: :tonexty,
              fillcolor: line_color.to_rgba(alpha: 0.2).to_hex_string,
              showlegend: false
            }
          when :bars
            y_min = ci_params[:y_min].map.with_index {|v, i| y[i] - v }
            y_max = ci_params[:y_max].map.with_index {|v, i| v - y[i] }
            trace[:error_y] = {
              visible: true,
              type: :data,
              array: y_max,
              arrayminus: y_min
            }
            unless line_color.nil?
              trace[:error_y][:color] = line_color
            end
            unless line_width.nil?
              trace[:error_y][:thickness] = line_width
            end
          end
        end

        trace[:name] = name.uniq.join(", ") unless name.empty?

        @traces << trace

        unless legend_title.empty?
          @layout[:showlegend] = true
          @layout[:legend] ||= {}
          @layout[:legend][:title] = {text: legend_title.uniq.join(", ")}
        end
      end

      def add_line_plot_legend(variables, color_mapper, size_mapper, style_mapper, legend)
        if legend == :full
          warn("Plotly backend does not support full verbosity legend")
        end

        legend_order = if variables.key?(:color)
                         if variables.key?(:style)
                           # both color and style
                           color_mapper.levels.product(style_mapper.levels)
                         else
                           # only color
                           color_mapper.levels
                         end
                       elsif variables.key?(:style)
                         # only style
                         style_mapper.levels
                       else
                         # no legend entries
                         nil
                       end

        if legend_order
          # sort traces
          legend_index = legend_order.map.with_index { |name, i|
            [Array(name).uniq.join(", "), i]
          }.to_h
          @traces = @traces.each_with_index.sort_by { |trace, trace_index|
            index = legend_index.fetch(trace[:name], legend_order.length)
            [index, trace_index]
          }.map(&:first)

          # remove duplicated legend entries
          names = {}
          @traces.each do |trace|
            if trace[:showlegend] != false
              name = trace[:name]
              if name
                if names.key?(name)
                  # Hide duplications
                  trace[:showlegend] = false
                else
                  trace[:showlegend] = true
                  names[name] = true
                end
              else
                # Hide no name trace in legend
                trace[:showlegend] = false
              end
            end
          end
        end
      end

      private def convert_dash_pattern(pattern, line_width)
        case pattern
        when ""
          :solid
        else
          pattern.map {|d| "#{line_width * d}px" }.join(",")
        end
      end

      PLOTLY_HISTNORM = {
        count: "".freeze,
        frequency: "density".freeze,
        density: "probability density".freeze,
        probability: "probability".freeze
      }.freeze

      def univariate_histogram(hist, name, variable_name, stat,
                               alpha, color, key_color, color_mapper,
                               _multiple, _element, _fill, _shrink)
        value_axis = variable_name
        case value_axis
        when :x
          weights_axis = :y
          orientation = :v
        else
          weights_axis = :x
          orientation = :h
        end

        mid_points = hist.edges.each_cons(2).map {|a, b| a + (b - a) / 2 }

        trace = {
          type: :bar,
          name: name.to_s,
          value_axis => mid_points,
          weights_axis => hist.weights,
          orientation: orientation,
          opacity: alpha
        }

        if color.nil?
          trace[:marker] = {
            color: key_color.to_rgb.to_hex_string
          }
        else
          trace[:marker] = {
            color: color_mapper[color].to_rgb.to_hex_string
          }
        end

        @traces << trace

        @layout[:bargap] = 0.05

        if @traces.length > 1
          @layout[:barmode] = "overlay"
          @layout[:showlegend] = true
        end
      end

      def set_title(title)
        @layout[:title] ||= {}
        @layout[:title][:text] = title
      end

      def set_xlabel(label)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:title] = label
      end

      def set_ylabel(label)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:title] = label
      end

      def set_xticks(values)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:tickmode] = "array"
        @layout[:xaxis][:tickvals] = values
      end

      def set_yticks(values)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:tickmode] = "array"
        @layout[:yaxis][:tickvals] = values
      end

      def set_xtick_labels(labels)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:tickmode] = "array"
        @layout[:xaxis][:ticktext] = labels
      end

      def set_ytick_labels(labels)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:tickmode] = "array"
        @layout[:yaxis][:ticktext] = labels
      end

      def set_xlim(min, max)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:range] = [min, max]
      end

      def set_ylim(min, max)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:range] = [min, max]
      end

      def set_xscale(scale)
        scale = check_scale_type(scale, :xscale)
        @layout[:xaxis] ||= {}
        @layout[:xaxis][:type] = scale
      end

      def set_yscale(scale)
        scale = check_scale_type(scale, :yscale)
        @layout[:yaxis] ||= {}
        @layout[:yaxis][:type] = scale
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
        # do nothing
      end

      def disable_yaxis_grid
        # do nothing
      end

      def invert_yaxis
        @traces.each do |trace|
          case trace[:type]
          when :bar
            trace[:y].reverse!
          end
        end

        if @layout[:boxmode] == :group
          @traces.reverse!
        end

        if @layout[:yaxis] && @layout[:yaxis][:ticktext]
          @layout[:yaxis][:ticktext].reverse!
        end
      end

      def legend(loc:, title:)
        @layout[:showlegend] = true
        @layout[:legend] = {
          title: {
            text: title
          }
        }
        # TODO: Handle loc
      end

      def save(filename, format: nil, title: nil, width: 700, height: 500, **kwargs)
        format = detect_format(filename) if format.nil?

        case format
        when nil, :html, "text/html"
          save_html(filename, title: title, **kwargs)
        when :png, "png", "image/png",
             :jpeg, "jpeg", "image/jpeg"
          render_image(format, filename: filename, notebook: false, title: title, width: width, height: height, **kwargs)
        end
        nil
      end

      private def detect_format(filename)
        case File.extname(filename).downcase
        when ".htm", ".html"
          :html
        when ".png"
          :png
        when ".jpg", ".jpeg"
          :jpeg
        else
          raise ArgumentError,
                "Unable to infer file type from filename: %p" % filename
        end
      end

      private def save_html(filename, title:, element_id: nil)
        html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
          <meta charset="utf-8">
          <title>%{title}</title>
          <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
          </head>
          <body>
          <div id="%{id}" style="width: 100%%; height:100%%;"></div>
          <script type="text/javascript">
          Plotly.newPlot("%{id}", %{data}, %{layout});
          </script>
          </body>
          </html>
        HTML

        element_id = SecureRandom.uuid if element_id.nil?

        html %= {
          title: title || default_html_title,
          id: element_id,
          data: JSON.dump(@traces),
          layout: JSON.dump(@layout)
        }
        File.write(filename, html)
      end

      private def default_html_title
        "Charty plot"
      end

      def render(element_id: nil, format: nil, notebook: false)
        case format
        when :html, "html", nil
          format = "text/html"
        when :png, "png"
          format = "image/png"
        when :jpeg, "jpeg"
          format = "image/jpeg"
        end

        case format
        when "text/html"
          # render html after this case cause
        when "image/png", "image/jpeg"
          image_data = render_image(format, element_id: element_id, notebook: false)
          if notebook
            return [format, image_data]
          else
            return image_data
          end
        else
          raise ArgumentError,
                "Unsupported mime type to render: %p" % format
        end

        element_id = SecureRandom.uuid if element_id.nil?

        renderer = PlotlyHelpers::HtmlRenderer.new(full_html: !notebook)
        html = renderer.render({data: @traces, layout: @layout}, element_id: element_id)
        if notebook
          [format, html]
        else
          html
        end
      end

      def render_mimebundle(include: [], exclude: [])
        types = case
               when IRubyHelper.vscode?,
                 IRubyHelper.nteract?
                 [:plotly_mimetype]
               else
                 [:plotly_mimetype, :notebook]
               end
        bundle = Util.filter_map(types) { |type|
          case type
          when :plotly_mimetype
            render_plotly_mimetype_bundle
          when :notebook
            render_notebook_bundle
          end
        }.to_h
        bundle
      end

      private def render_plotly_mimetype_bundle
        renderer = PlotlyHelpers::PlotlyRenderer.new
        obj = renderer.render({data: @traces, layout: @layout})
        [ "application/vnd.plotly.v1+json", obj ]
      end

      private def render_notebook_bundle
        renderer = self.class.notebook_renderer
        renderer.activate
        html = renderer.render({data: @traces, layout: @layout})
        [ "text/html", html ]
      end

      # for new APIs
      def self.notebook_renderer
        @notebook_renderer ||= PlotlyHelpers::NotebookRenderer.new
      end

      private def render_image(format=nil, filename: nil, element_id: nil, notebook: false,
                       title: nil, width: nil, height: nil)
        format = "image/png" if format.nil?
        case format
        when :png, "png", :jpeg, "jpeg"
          image_type = format.to_s
        when "image/png", "image/jpeg"
          image_type = format.split("/").last
        else
          raise ArgumentError,
                "Unsupported mime type to render image: %p" % format
        end

        height = 525 if height.nil?
        width = (height * Math.sqrt(2)).to_i if width.nil?
        title = "Charty plot" if title.nil?

        element_id = SecureRandom.uuid if element_id.nil?
        element_id = "charty-plotly-#{element_id}"
        Dir.mktmpdir do |tmpdir|
          html_filename = File.join(tmpdir, "%s.html" % element_id)
          save_html(html_filename, title: title, element_id: element_id)
          return self.class.render_image(html_filename, filename, image_type, element_id, width, height)
        end
      end

      module IRubyOutput
        @prepared = false

        def self.prepare
          return if @prepared

          html = <<~HTML
            <script type="text/javascript">
              %{win_config}
              %{mathjax_config}
              require.config({
                paths: {
                  plotly: "https://cdn.plot.ly/plotly-latest.min"
                }
              });
            </script>
          HTML

          html %= {
            win_config: window_plotly_config,
            mathjax_config: mathjax_config
          }

          IRuby.display(html, mime: "text/html")
          @prepared = true
        end

        def self.window_plotly_config
          <<~END
            window.PlotlyConfig = {MathJaxConfig: 'local'};
          END
        end


        def self.mathjax_config
          <<~END
            if (window.MathJax) {MathJax.Hub.Config({SVG: {font: "STIX-Web"}});}
          END
        end
      end

      @playwright_fiber = nil

      def self.ensure_playwright
        if @playwright_fiber.nil?
          begin
            require "playwright"
          rescue LoadError
            $stderr.puts "ERROR: You need to install playwright and playwright-ruby-client before using Plotly renderer"
            raise
          end

          @playwright_fiber = Fiber.new do
            playwright_cli_executable_path = ENV.fetch("PLAYWRIGHT_CLI_EXECUTABLE_PATH", "npx playwright")
            Playwright.create(playwright_cli_executable_path: playwright_cli_executable_path) do |playwright|
              playwright.chromium.launch(headless: true) do |browser|
                request = Fiber.yield
                loop do
                  result = nil
                  case request.shift
                  when :finish
                    break
                  when :render
                    input, output, format, element_id, width, height = request

                    page = browser.new_page
                    page.set_viewport_size(width: width, height: height)
                    page.goto("file://#{input}")
                    element = page.query_selector("\##{element_id}")

                    kwargs = {type: format}
                    kwargs[:path] = output unless output.nil?
                    result = element.screenshot(**kwargs)
                  end
                  request = Fiber.yield(result)
                end
              end
            end
          end
          @playwright_fiber.resume
        end
      end

      def self.terminate_playwright
        return if @playwright_fiber.nil?

        @playwright_fiber.resume([:finish])
      end

      at_exit { terminate_playwright }

      def self.render_image(input, output, format, element_id, width, height)
        ensure_playwright if @playwright_fiber.nil?
        @playwright_fiber.resume([:render, input, output, format.to_s, element_id, width, height])
      end
    end
  end
end
