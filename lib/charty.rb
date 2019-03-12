require_relative "charty/version"

require_relative "charty/main"
require_relative "charty/layout"
require_relative "charty/linspace"
require_relative "charty/table"

module Charty
  def self.new(*args)
    Charty::Main.new(*args)
  end
end
