require "forwardable"

module Charty
  module TableAdapters
    class BaseAdapter
      extend Forwardable
      include Enumerable

      attr_reader :columns

      def columns=(values)
        @columns = check_and_convert_index(values, :columns, column_length)
      end

      def column_names
        columns.to_a
      end

      def column?(name)
        return true if column_names.include?(name)

        case name
        when String
          column_names.include?(name.to_sym)
        when Symbol
          column_names.include?(name.to_s)
        else
          false
        end
      end

      attr_reader :index

      def index=(values)
        @index = check_and_convert_index(values, :index, length)
      end

      def ==(other)
        case other
        when BaseAdapter
          return false if columns != other.columns
          return false if index != other.index
          compare_data_equality(other)
        else
          false
        end
      end

      def group_by(table, grouper, sort, drop_na)
        Table::HashGroupBy.new(table, grouper, sort, drop_na)
      end

      def compare_data_equality(other)
        columns.each do |name|
          if self[nil, name] != other[nil, name]
            return false
          end
        end
        true
      end

      def drop_na
        # TODO: Must implement this method in each adapter
        missing_index = index.select do |i|
          column_names.any? do |key|
            Util.missing?(self[i, key])
          end
        end
        if missing_index.empty?
          nil
        else
          select_index = index.to_a - missing_index
          new_data = column_names.map { |key|
            vals = select_index.map {|i| self[i, key] }
            [key, vals]
          }.to_h
          Charty::Table.new(new_data, index: select_index)
        end
      end

      def sort_values(by, na_position: :last)
        na_cmp_val = check_na_position(na_position)
        case by
        when String, Symbol
          order = (0 ... length).sort do |i, j|
            a = self[i, by]
            b = self[j, by]
            case
            when Util.missing?(a)  # missing > b
              na_cmp_val
            when Util.missing?(b)  # a < missing
              -na_cmp_val
            else
              cmp = a <=> b
              if cmp == 0
                i <=> j
              else
                cmp
              end
            end
          end
        when Array
          order = (0 ... length).sort do |i, j|
            cmp = 0
            by.each do |key|
              a = self[i, key]
              b = self[j, key]
              case
              when Util.missing?(a)  # missing > b
                cmp = na_cmp_val
                break
              when Util.missing?(b)  # a < missing
                cmp = -na_cmp_val
                break
              else
                cmp = a <=> b
                break if cmp != 0
              end
            end
            if cmp == 0
              i <=> j
            else
              cmp
            end
          end
        else
          raise ArgumentError,
                "%p is invalid value for `by`" % by
        end

        Charty::Table.new(
          column_names.map { |name|
            [
              name,
              self[nil, name].values_at(*order)
            ]
          }.to_h,
          index: index.to_a.values_at(*order)
        )
      end

      def melt(id_vars: nil, value_vars: nil, var_name: nil, value_name: :value)
        if column?(value_name)
          raise ArgumentError,
                "The value of `value_name` must not be matched to the existing column names."
        end

        case value_name
        when Symbol
          # do nothing
        else
          value_name = value.to_str.to_sym
        end

        id_vars = check_melt_vars(id_vars, :id_vars)
        value_vars = check_melt_vars(value_vars, :value_vars) { self.column_names }
        value_vars -= id_vars

        case var_name
        when nil
          var_name = self.columns.name
          var_name = :variable if var_name.nil?
        when Symbol
          # do nothing
        else
          var_name = var_name.to_str
        end
        var_name = var_name.to_sym

        n_batch_rows = self.length
        n_target_columns = value_vars.length
        melted_data = id_vars.map { |cn|
          id_values = self[nil, cn].to_a
          [cn.to_sym, id_values * n_target_columns]
        }.to_h

        melted_data[var_name] = value_vars.map { |cn| Array.new(n_batch_rows, cn) }.flatten

        melted_data[value_name] = value_vars.map { |cn| self[nil, cn].to_a }.flatten

        Charty::Table.new(melted_data)
      end

      private def check_melt_vars(val, name)
        if val.nil?
          val = if block_given?
                  yield
                else
                  []
                end
        end
        case val
        when nil
          nil
        when Array
          missing = val.reject {|cn| self.column?(cn) }
          if missing.empty?
            val.map do |v|
              case v
              when Symbol
                v.to_s
              else
                v.to_str
              end
            end
          else
            raise ArgumentError,
                  "Missing column names in `#{name}` (%s)" % missing.join(", ")
          end
        when Symbol
          [val.to_s]
        else
          [val.to_str]
        end
      end

      private def check_na_position(val)
        case val
        when :first, "first"
          -1
        when :last, "last"
          1
        else
          raise ArgumentError,
                "`na_position` must be :first or :last",
                caller
        end
      end

      private def check_and_convert_index(values, name, expected_length)
        case values
        when Index, Range
        else
          unless (ary = Array.try_convert(values))
            raise ArgumentError, "invalid object for %s: %p" % [name, values]
          end
          values = ary
        end
        if expected_length != values.size
          raise ArgumentError,
                "invalid length for %s (%d for %d)" % [name, values.size, expected_length]
        end
        case values
        when Index
          values
        when Range
          RangeIndex.new(values)
        when Array
          Index.new(values)
        end
      end
    end
  end
end
