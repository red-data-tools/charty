module Charty
  module Backends
    module BackendHelpers
      module PlaywrightManager
        @_playwright_exec = nil
        @_browser = nil
        @_context = nil

        at_exit do
          if @_context
            @_context.close
            @_context = nil
          end
          if @_browser
            @_browser.close
            @_browser = nil
          end
          if @_playwright_exec
            @_playwright_exec.stop
            @_playwright_exec = nil
          end
        end

        module_function def playwright
          unless @_playwright_exec
            load_playwright
            path = ENV.fetch("PLAYWRIGHT_CLI_EXECUTABLE_PATH", "npx playwright")
            @_playwright_exec = Playwright.create(playwright_cli_executable_path: path)
          end
          @_playwright_exec.playwright
        end

        module_function def launch_browser
          playwright.chromium.launch(headless: true)
        end

        module_function def default_browser
          unless @_browser
            @_browser = launch_browser
          end
          @_browser
        end

        module_function def default_context
          unless @_context
            @_context = default_browser.new_context
          end
          @_context
        end

        module_function def new_page(&block)
          page = default_context.new_page
          return page unless block

          begin
            return block.call(page)
          ensure
            page.close
          end
        end

        module_function def load_playwright
          require "playwright"
        rescue LoadError
          $stderr.puts "ERROR: You need to install playwright and playwright-ruby-client before using Plotly renderer"
          raise
        end
      end
    end
  end
end
