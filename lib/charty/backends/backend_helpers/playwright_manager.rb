module Charty
  module Backends
    module BackendHelpers
      module PlaywrightManager
        @_playwright_exec = nil
        @_browser = nil
        @_context = nil

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

        module_function def shutdown
          @_playwright_exec.stop if @_playwright_exec
          @_playwright_exec = nil
          @_context = nil
          @_browser = nil
        end

        at_exit do
          shutdown
        end
      end
    end
  end
end
