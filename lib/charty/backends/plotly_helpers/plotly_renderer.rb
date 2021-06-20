require "date"
require "json"
require "time"

module Charty
  module Backends
    module PlotlyHelpers
      class PlotlyRenderer
        def render(figure)
          json = JSON.generate(figure, allow_nan: true)
          case json
          when /\b(?:Infinity|NaN)\b/
            visit(figure)
          else
            JSON.load(json)
          end
        end

        private def visit(obj)
          case obj
          when Integer, String, Symbol, true, false, nil
            obj

          when Numeric
            visit_float(obj)

          when Time
            visit_time(obj)

          when Date
            visit_date(obj)

          when DateTime
            visit_datetime(obj)

          when Array
            visit_array(obj)

          when Hash
            visit_hash(obj)

          when ->(x) { defined?(Numo::NArray) && obj.is_a?(Numo::NArray) }
            visit_array(obj.to_a)

          when ->(x) { defined?(NMatrix) && obj.is_a?(NMatrix) }
            visit_array(obj.to_a)

          when ->(x) { defined?(Numpy::NDArray) && obj.is_a?(Numpy::NDArray) }
            visit_array(obj.to_a)

          when ->(x) { defined?(PyCall::List) && obj.is_a?(PyCall::List) }
            visit_array(obj.to_a)

          when ->(x) { defined?(PyCall::Tuple) && obj.is_a?(PyCall::Tuple) }
            visit_array(obj.to_a)

          when ->(x) { defined?(PyCall::Dict) && obj.is_a?(PyCall::Dict) }
            visit_hash(obj.to_h)

          when ->(x) { defined?(Pandas::Series) && obj.is_a?(Pandas::Series) }
            visit_array(obj.to_a)

          else
            str = String.try_convert(obj)
            return str unless str.nil?

            ary = Array.try_convert(obj)
            return visit_array(ary) unless ary.nil?

            hsh = Hash.try_convert(obj)
            return visit_hash(hsh) unless hsh.nil?

            type_error(obj)
          end
        end

        private def visit_float(obj)
          obj = obj.to_f
        rescue RangeError
          type_error(obj)
        else
          case
          when obj.finite?
            obj
          else
            nil
          end
        end

        private def visit_time(obj)
          obj.iso8601(6)
        end

        private def visit_date(obj)
          obj.iso8601(6)
        end

        private def visit_datetime(obj)
          obj.iso8601(6)
        end

        private def visit_array(obj)
          obj.map {|x| visit(x) }
        end

        private def visit_hash(obj)
          obj.map { |key, value|
            [
              key,
              visit(value)
            ]
          }.to_h
        end

        private def type_error(obj)
          raise TypeError, "Unable to convert to JSON: %p" % obj
        end
      end
    end
  end
end
