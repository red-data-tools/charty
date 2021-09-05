module Charty
  module VectorAdapters
    class ArrowAdapter < BaseAdapter
      VectorAdapters.register(:arrow, self)

      include Enumerable
      include NameSupport
      include IndexSupport

      def self.supported?(data)
        (defined?(Arrow::Array) && data.is_a?(Arrow::Array)) ||
          (defined?(Arrow::ChunkedArray) && data.is_a?(Arrow::ChunkedArray))
      end

      def initialize(data)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      def size
        @data.length
      end

      def empty?
        @data.length.zero?
      end

      def where(mask)
        mask = check_mask_vector(mask)
        mask_data = mask.data
        unless mask_data.is_a?(Arrow::BooleanArray)
          mask_data = mask.to_a
          mask_data = mask_data.map(&:nonzero?) if mask_data[0].is_a?(Integer)
          mask_data = Arrow::BooleanArray.new(mask_data)
        end
        masked_data = @data.filter(mask_data)
        masked_index = []
        mask_data.to_a.each_with_index do |boolean, i|
          masked_index << index[i] if boolean
        end
        Charty::Vector.new(masked_data, index: masked_index, name: name)
      end

      def boolean?
        case @data
        when Arrow::BooleanArray
          true
        when Arrow::ChunkedArray
          @data.value_data_type.is_a?(Arrow::BooleanDataType)
        else
          false
        end
      end

      def numeric?
        case @data
        when Arrow::NumericArray
          true
        when Arrow::ChunkedArray
          @data.value_data_type.is_a?(Arrow::NumericDataType)
        else
          false
        end
      end

      def categorical?
        case @data
        when Arrow::DictionaryArray
          true
        when Arrow::ChunkedArray
          @data.value_data_type.is_a?(Arrow::DictionaryDataType)
        else
          false
        end
      end

      def categories
        @data.dictionary.to_a
      end

      def unique_values
        @data.unique.to_a
      end

      def group_by(grouper)
        grouper = Vector.new(grouper) unless grouper.is_a?(Vector)
        group_keys = grouper.unique_values
        grouper_data = grouper.data
        unless grouper_data.is_a?(Arrow::Array)
          grouper_data = Arrow::Array.new(grouper.to_a)
        end
        equal = Arrow::Function.find("equal")
        group_keys.map { |key|
          if key.nil?
            target_vector = Charty::Vector.new([nil] * @data.n_nulls)
          else
            mask = equal.execute([grouper_data, key]).value
            target_vector = Charty::Vector.new(@data.filter(mask))
          end
          [key, target_vector]
        }.to_h
      end

      def drop_na
        if @data.n_nulls.zero?
          Vector.new(@data, index: index, name: name)
        else
          data_without_null =
            Arrow::Function.find("drop_null").execute([@data]).value
          Vector.new(data_without_null)
        end
      end

      def eq(val)
        mask = Arrow::Function.find("equal").execute([@data, val]).value
        Vector.new(mask, index: index, name: name)
      end

      def notnull
        if @data.n_nulls.zero?
          mask = Arrow::BooleanArray.new([true] * @data.length)
        else
          mask = Arrow::BooleanArray.new(@data.length,
                                         @data.null_bitmap,
                                         nil,
                                         0)
        end
        Vector.new(mask, index: index, name: name)
      end

      def mean
        @data.mean
      end

      def stdev(population: false)
        options = Arrow::VarianceOptions.new
        if population
          options.ddof = 0
        else
          options.ddof = 1
        end
        Arrow::Function.find("stddev").execute([@data], options).value.value
      end
    end
  end
end
