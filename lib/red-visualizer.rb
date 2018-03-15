require "red-visualizer/version"

module RedVisualizer
end

require_relative "./red-visualizer/main"
require_relative "./red-visualizer/matplot"
require_relative "./red-visualizer/layout"

Rdv = RedVisualizer
RdvMain = Rdv::Main
