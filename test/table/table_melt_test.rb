class TableMeltTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("generic table data") do
    data(:adapter_type, [:array_hash, :daru, :pandas], keep: true)
    data(:key_type,     [:string, :symbol], keep: true)
    def test_melt_without_id_vars(data)
      setup_table(data[:adapter_type], data[:key_type])
      melted = @table.melt
      assert_equal(@expected_without_id_vars, melted)
    end

    def test_melt_with_id_vars(data)
      setup_table(data[:adapter_type], data[:key_type])
      melted = @table.melt(id_vars: :name)
      assert_equal(@expected_with_id_vars, melted)
    end
  end

  sub_test_case("CSV") do
    def test_melt_without_id_vars
      setup_table
      melted = @table.melt
      assert_equal(@expected_without_id_vars, melted)
    end

    def test_melt_with_id_vars
      setup_table
      melted = @table.melt(id_vars: :name)
      assert_equal(@expected_with_id_vars, melted)
    end

    def setup_table
      @table = Charty::Table.new(csv_table)
      @expected_without_id_vars = Charty::Table.new(expected_data_without_id_vars)
      @expected_with_id_vars = Charty::Table.new(expected_data_with_id_vars)
    end
  end

  def setup_table(adapter_type, key_type)
    send("setup_table_by_#{adapter_type}", key_type)
  end

  def setup_table_by_array_hash(key_type)
    @table = Charty::Table.new(raw_data(key_type))
    @expected_without_id_vars = Charty::Table.new(expected_data_without_id_vars)
    @expected_with_id_vars = Charty::Table.new(expected_data_with_id_vars)
  end

  def setup_table_by_daru(key_type)
    @table = Charty::Table.new(Daru::DataFrame.new(raw_data(key_type)))
    @expected_without_id_vars = Charty::Table.new(expected_data_without_id_vars)
    @expected_with_id_vars = Charty::Table.new(expected_data_with_id_vars)
  end

  def setup_table_by_pandas(key_type)
    csv = csv_table.by_col!
    data = csv.headers.map { |cn|
      [cn, csv[cn]]
    }.to_h
    @table = Charty::Table.new(Pandas::DataFrame.new(data: data))
    @expected_without_id_vars = Charty::Table.new(Pandas::DataFrame.new(data: expected_data_without_id_vars))
    @expected_with_id_vars = Charty::Table.new(Pandas::DataFrame.new(data: expected_data_with_id_vars))
  end

  def expected_data_without_id_vars
    {
      variable: [
        "name", "name",
        "2018", "2018",
        "2019", "2019",
        "2020", "2020"
      ],
      value: [
        "GOOG", "AAPL",
        1035.61, 39.44,
        1337.02, 73.41,
        1751.88, 132.69
      ]
    }
  end

  def expected_data_with_id_vars
    {
      name: [
        "GOOG", "AAPL",
        "GOOG", "AAPL",
        "GOOG", "AAPL"
      ],
      variable: [
        "2018", "2018",
        "2019", "2019",
        "2020", "2020"
      ],
      value: [
        1035.61, 39.44,
        1337.02, 73.41,
        1751.88, 132.69
      ]
    }
  end

  def raw_data(key_type)
    csv = csv_table.by_col!
    csv.headers.map { |cn|
      key = if key_type == :string
              cn
            else
              cn.to_sym
            end
      [key, csv[cn]]
    }.to_h
  end

  def csv_table
    CSV.parse(<<~END_CSV, headers: true, converters: :all)
      name,2018,2019,2020
      GOOG,1035.61,1337.02,1751.88
      AAPL,39.44,73.41,132.69
      END_CSV
  end
end

