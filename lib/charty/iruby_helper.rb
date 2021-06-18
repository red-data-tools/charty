module Charty
  module IRubyHelper
    module_function

    def iruby_notebook?
      # TODO: This cannot distinguish notebook and console.
      defined?(IRuby)
    end

    def vscode?
      ENV.key?("VSCODE_PID")
    end

    def nteract?
      ENV.key?("NTERACT_EXE")
    end
  end
end
