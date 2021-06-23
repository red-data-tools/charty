class TableCSVTest < Test::Unit::TestCase
  def setup
    @data = CSV.parse(<<END_CSV, headers: true, converters: :all)
foo,bar,baz
1,aaa,2021-01-02
2,bbb,2021-01-01
3,aaa,2021-01-04
4,ccc,2021-01-13
5,ccc,2021-01-20
6,aaa,2021-02-08
7,bbb,2021-02-23
8,ccc,2021-03-01
9,aaa,2021-02-28
10,ccc,2021-03-03
END_CSV
    @table = Charty::Table.new(@data)
  end

  test("#adapter") do
    assert_equal(Charty::TableAdapters::HashAdapter,
                 @table.adapter.class)
  end

  test("#columns") do
    assert_equal(@data.headers,
                 @table.columns.to_a)
  end
end
