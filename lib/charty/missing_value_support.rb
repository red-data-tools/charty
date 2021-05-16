module Charty
  module MissingValueSupport
    def missing_value?(val)
      case
      when val.nil?
        true
      when val.respond_to?(:nan?) && val.nan?
        true
      else
        false
      end
    end
  end
end
