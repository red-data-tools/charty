require "datasets/downloader"
require "json"
require "securerandom"

module Charty
  module Backends
    module PlotlyHelpers
      class HtmlRenderer
        def initialize(use_cdn: true,
                       full_html: false,
                       requirejs: true)
          @use_cdn = use_cdn
          @full_html = full_html
          @requirejs = requirejs
        end

        PLOTLY_URL = "https://plot.ly".freeze
        PLOTLY_LATEST_CDN_URL = "https://cdn.plot.ly/plotly-latest.min.js".freeze
        MATHJAX_CDN_URL = ("https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js").freeze

        DEFAULT_WIDTH = "100%".freeze
        DEFAULT_HEIGHT = 525

        def render(figure, element_id: nil, post_script: nil)
          element_id = SecureRandom.uuid if element_id.nil?
          plotly_html_div = build_plotly_html_div(figure, element_id, post_script)

          if @full_html
            <<~END_HTML % {div: plotly_html_div}
              <!DOCTYPE html>
              <html>
              <head><meta charset="utf-8" /></head>
              <body>
                %{div}
              </body>
              </html>
            END_HTML
          else
            plotly_html_div
          end
        end

        private def build_plotly_html_div(figure, element_id, post_script)
          layout = figure.fetch(:layout, {})

          json_data = JSON.dump(figure.fetch(:data, []))
          json_layout = JSON.dump(layout)
          json_frames = JSON.dump(figure[:frames]) if figure.key?(:frames)

          # TODO: config and responsive support

          template = layout.fetch(:template, {}).fetch(:layout, {})
          div_width = layout.fetch(:width, template.fetch(:width, DEFAULT_WIDTH))
          div_height = layout.fetch(:height, template.fetch(:height, DEFAULT_HEIGHT))

          div_width  = "#{div_width}px"  if Float(div_width, exception: false)
          div_height = "#{div_height}px" if Float(div_height, exception: false)

          # TODO: showLink and showSendToCloud support
          base_url_line = "window.PLOTLYENV.BASE_URL = '%{url}';" % {url: PLOTLY_URL}

          ## build script body

          # TODO: post_script support
          then_post_script = ""
          if post_script
            ary = Array.try_convert(post_script)
            post_script = ary || [post_script]
            post_script.each do |ps|
              next if ps.nil?
              then_post_script << '.then(function(){ %{post_script} })' % {
                post_script: ps % {plot_id: element_id}
              }
            end
          end

          then_addframes = ""
          then_animate = ""
          if json_frames
            then_addframes = <<~END_ADDFRAMES % {id: element_id, frames: json_frames}
              .then(function(){
                Plotly.addFrames('%{id}', {frames});
              })
            END_ADDFRAMES

            # TODO: auto_play support
          end

          json_config = JSON.dump({}) # TODO: config support

          script = <<~END_SCRIPT
            if (document.getElementById("%{id}")) {
              Plotly.newPlot("%{id}", %{data}, %{layout}, %{config})%{then_addframes}%{then_animate}%{then_post_script};
            }
          END_SCRIPT
          script = script % {
            id: element_id,
            data: json_data,
            layout: json_layout,
            config: json_config,
            then_addframes: then_addframes,
            then_animate: then_animate,
            then_post_script: then_post_script
          }

          ## Handle loading/initializing plotlyjs

          case
          when @requirejs
            include_plotlyjs = :require
            include_mathjax = false
          when @use_cdn
            include_plotlyjs = :cdn
            include_mathjax = :cdn
          else
            include_plotlyjs = true
            include_mathjax = :cdn
          end

          case include_plotlyjs
          when :require
            require_start = 'require(["plotly"], function (Plotly) {'
            require_end   = '});'
          when :cdn
            load_plotlyjs = <<~END_LOAD_PLOTLYJS % {win_config: window_plotly_config, url: PLOTLY_LATEST_CDN_URL}
              %{win_config}
              <script src="%{url}"></script>
            END_LOAD_PLOTLYJS
          when true
            load_plotlyjs = <<~END_LOAD_PLOTLYJS % {win_config: window_plotly_config, script: get_plotlyjs}
              %{win_config}
              <script type="text/javascript">%{script}</script>
            END_LOAD_PLOTLYJS
          end

          ## Handle loading/initializing MathJax

          mathjax_tmplate = %Q[<script src="%{url}?config=TeX-AMS-MML_SVG"></script>]
          case include_mathjax
          when :cdn
            mathjax_script = mathjax_tmplate % {url: MATHJAX_CDN_URL}
            mathjax_script << <<~END_SCRIPT % {mathjax_config: mathjax_config}
              <script type="text/javascript">%{mathjax_config}</script>
            END_SCRIPT
          else
            mathjax_script = ""
          end

          div_template = <<~END_DIV
            <div>
              %{mathjax_script}
              %{load_plotlyjs}
              <div id="%{id}" class="plotly-graph-div" style="height: %{height}; width: %{width};"></div>
              <script type="text/javascript">
                %{require_start}
                  window.PLOTLYENV = window.PLOTLYENV || {};
                  %{base_url_line}
                  %{script}
                %{require_end}
              </script>
            </div>
          END_DIV

          plotly_html_div = div_template % {
            mathjax_script: mathjax_script,
            load_plotlyjs: load_plotlyjs,
            id: element_id,
            height: div_height,
            width: div_width,
            require_start: require_start,
            base_url_line: base_url_line,
            script: script,
            require_end: require_end
          }
          plotly_html_div.strip!

          plotly_html_div
        end

        private def window_plotly_config
          %Q(window.PlotlyConfig = {MathJaxConfig: 'local'};)
        end

        private def mathjax_config
          %Q(if (window.MathJax) { MathJax.Hub.Config({SVG: {font: "STIX-Web"}}); })
        end

        private def get_plotlyjs
          cache_path = CacheDir.path("plotly.min.js")
          unless cache_path.exist?
            download_plotlyjs(cache_path)
          end
          cache_path.read
        end

        private def download_plotlyjs(output_path)
          downloader = Datasets::Downloader.new(PLOTLY_LATEST_CDN_URL)
          downloader.download(output_path)
        end
      end
    end
  end
end
