require 'test_helper'
require 'daru'
require 'numo/narray'

class TableAdaptersTest < Test::Unit::TestCase
  sub_test_case(".find_adapter_maker") do
    test("for a hash of arrays") do
      data = {
               "foo" => [1, 2, 3, 4],
               "bar" => [5, 6, 7, 8],
             }
      assert_equal(Charty::TableAdapters::HashAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for an array of hashes") do
      data = [
               {"foo" => 1, "bar" => 5},
               {"foo" => 2, "bar" => 6},
               {"foo" => 3, "bar" => 7},
               {"foo" => 4, "bar" => 8},
             ]
      assert_equal(Charty::TableAdapters::HashAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for an array of arrays") do
      data = [
               [1, 2, 3, 4],
               [5, 6, 7, 8]
             ]
      assert_equal(Charty::TableAdapters::HashAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for an array of Numo::NArray arrays") do
      data = [
               [1, 2, 3, 4],
               [5, 6, 7, 8]
             ]
      assert_equal(Charty::TableAdapters::HashAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for an array of scalar values") do
      data = [1, 2, 3, 4]
      assert_equal(Charty::TableAdapters::HashAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for a Daru::DataFrame") do
      data = Daru::DataFrame.new(
        "foo" => [1, 2, 3, 4],
        "bar" => [5, 6, 7, 8]
      )
      assert_equal(Charty::TableAdapters::DaruAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for a Numo::NArray matrix") do
      data = Numo::Int32[
                          [1, 5,  9],
                          [2, 6, 10],
                          [3, 7, 11],
                          [4, 8, 12],
                        ]
      assert_equal(Charty::TableAdapters::NArrayAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end

    test("for a NMatrix matrix") do
      data = NMatrix.new([4, 3],
                         [
                           1, 5,  9,
                           2, 6, 10,
                           3, 7, 11,
                           4, 8, 12,
                         ])
      assert_equal(Charty::TableAdapters::NMatrixAdapter,
                   Charty::TableAdapters.find_adapter_maker(data))
    end
  end
end
