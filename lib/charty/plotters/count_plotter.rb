module Charty
  module Plotters
    class CountPlotter < BarPlotter
      self.require_numeric = false
    end
  end
end
