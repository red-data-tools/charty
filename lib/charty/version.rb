module Charty
  VERSION = "0.2.0"

  module Version
    numbers, TAG = VERSION.split("-")
    MAJOR, MINOR, MICRO = numbers.split(".").collect(&:to_i)
    STRING = VERSION
  end
end
