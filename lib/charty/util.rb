module Charty
  module Util
    if [].respond_to?(:filter_map)
      module_function def filter_map(enum, &block)
        enum.filter_map(&block)
      end
    else
      module_function def filter_map(enum, &block)
        enum.inject([]) do |acc, x|
          y = block.call(x)
          if y
            acc.push(y)
          else
            acc
          end
        end
      end
    end

    module_function def missing?(val)
      val.nil? || nan?(val)
    end

    module_function def nan?(val)
      val.respond_to?(:nan?) && val.nan?
    end
  end
end
