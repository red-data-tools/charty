module Charty
  module Backends
    module PlotlyHelpers
      class NotebookRenderer < HtmlRenderer
        def initialize(use_cdn: false)
          super(use_cdn: use_cdn, full_html: false, requirejs: true)
          @initialized = false
        end

        def activate()
          return if @initialized

          unless IRubyHelper.iruby_notebook?
            raise "IRuby is unavailable"
          end

          if @use_cdn
            script = <<~END_SCRIPT % {win_config: window_plotly_config, mathjax_config: mathjax_config}
              <script type="text/javascript">
                %{win_config}
                %{mathjax_config}
                if (typeof require !== 'undefined') {
                  require.undef("plotly");
                  requirejs.config({
                    paths: {
                      'plotly': ['https://cdn.plot.ly/plotly-latest.min']
                    }
                  });
                  require(['plotly'], function (Plotly) {
                    window._Plotly = Plotly;
                  });
                }
              </script>
            END_SCRIPT
          else
            script = <<~END_SCRIPT % {script: get_plotlyjs, win_config: window_plotly_config, mathjax_config: mathjax_config}
              <script type="text/javascript">
                %{win_config}
                %{mathjax_config}
                if (typeof require !== 'undefined') {
                  require.undef("plotly");
                  define('plotly', function (require, exports, module) {
                    %{script}
                  });
                  require(['plotly'], function (Plotly) {
                    window._Plotly = Plotly;
                  });
                }
              </script>
            END_SCRIPT
          end
          IRuby.display(script, mime: "text/html")
        end

        def render(figure, element_id: nil, post_script: nil)
          ary = Array.try_convert(post_script)
          post_script = ary || [post_script]
          post_script.unshift(<<~END_POST_SCRIPT)
            var gd = document.getElementById('%{plot_id}');
            var x = new MutationObserver(function (mutations, observer) {
              var display = window.getComputedStyle(gd).display;
              if (!display || display === 'none') {
                console.log([gd, 'removed']);
                Plotly.purge(gd);
                observer.disconnect();
              }
            });

            // Listen for the removal of the full notebook cell
            var notebookContainer = gd.closest('#notebook-container');
            if (notebookContainer) {
              x.observe(notebookContainer, {childList: true});
            }

            // Listen for the clearing of the current output cell
            var outputEl = gd.closest('.output');
            if (outputEl) {
              x.observe(outputEl, {childList: true});
            }
          END_POST_SCRIPT

          super(figure, element_id: element_id, post_script: post_script)
        end
      end
    end
  end
end
