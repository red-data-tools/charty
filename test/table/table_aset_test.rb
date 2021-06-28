class TableAsetTest < Test::Unit::TestCase
  include Charty::TestHelpers

  if {}.respond_to?(:transform_keys)
    def transform_keys(h, &block)
      h.transform_keys(&block)
    end
  else
    def transform_keys(h)
      h.map {|k, v| [yield(k), v] }.to_h
    end
  end

  def raw_data(key_type)
    raw_data = {
      foo: [1, 2, 3, 4, 5],
      bar: ["a", "b", "c", "d", "e"]
    }
    case key_type
    when :string
      transform_keys(raw_data, &:to_s)
    else
      raw_data
    end
  end

  sub_test_case("Array Hash") do
    data(:data_key_type,     [:string, :symbol], keep: true)
    data(:aset_key_type,     [:string, :symbol], keep: true)
    def test_aset_existing(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      table = Charty::Table.new(raw_data(data_key_type), index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end

    def test_aset_new(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      table = Charty::Table.new(raw_data(data_key_type), index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end
  end

  sub_test_case("Daru") do
    data(:data_key_type,     [:string, :symbol], keep: true)
    data(:aset_key_type,     [:string, :symbol], keep: true)
    def test_aset_existing(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      data = Daru::DataFrame.new(raw_data(data_key_type))
      table = Charty::Table.new(data, index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      expected_data = Daru::DataFrame.new(expected_data)
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end

    def test_aset_new(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      data = Daru::DataFrame.new(raw_data(data_key_type))
      table = Charty::Table.new(data, index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      expected_data = Daru::DataFrame.new(expected_data)
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end
  end

  sub_test_case("Pandas") do
    def setup
      pandas_required
    end

    data(:data_key_type,     [:string, :symbol], keep: true)
    data(:aset_key_type,     [:string, :symbol], keep: true)
    def test_aset_existing(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      data = Pandas::DataFrame.new(data: raw_data(data_key_type))
      table = Charty::Table.new(data, index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      expected_data = Pandas::DataFrame.new(data: expected_data)
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end

    def test_aset_new(data)
      data_key_type, aset_key_type = data.values_at(:data_key_type, :aset_key_type)
      data = Pandas::DataFrame.new(data: raw_data(data_key_type))
      table = Charty::Table.new(data, index: [2, 4, 6, 8, 10])
      key = case aset_key_type
            when :symbol
              :bar
            else
              "bar"
            end
      table[key] = [10, 20, 30, 40, 50]
      expected_data = {
        foo: [1, 2, 3, 4, 5],
        bar: [10, 20, 30, 40, 50]
      }
      expected_data = transform_keys(expected_data, &:to_s) if data_key_type == :string
      expected_data = Pandas::DataFrame.new(data: expected_data)
      assert_equal(Charty::Table.new(expected_data, index: [2, 4, 6, 8, 10]),
                   table)
    end
  end
end
