require "datasets"

class TableRedDatasetsTest < Test::Unit::TestCase
  sub_test_case("CIFAR") do
    def setup
      @data = Datasets::CIFAR.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :data,
                     :label,
                     :pixels,
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.label,
                     @table[0, :label])
      end

      test("column name only") do
        label_column = @data.map(&:label)
        assert_equal(Charty::Vector,
                     @table[:label].class)
        assert_equal(label_column,
                     @table[:label].data)
      end
    end
  end

  sub_test_case("adult") do
    def setup
      @data = Datasets::Adult.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :age,
                     :work_class,
                     :final_weight,
                     :education,
                     :n_education_years,
                     :marital_status,
                     :occupation,
                     :relationship,
                     :race,
                     :sex,
                     :capital_gain,
                     :capital_loss,
                     :hours_per_week,
                     :native_country,
                     :label
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.age,
                     @table[0, :age])
      end

      test("column name only") do
        race_column = @data.map(&:race)
        assert_equal(Charty::Vector,
                     @table[:race].class)
        assert_equal(race_column,
                     @table[:race].data)
      end
    end
  end

  sub_test_case("iris") do
    def setup
      @data = Datasets::Iris.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :sepal_length,
                     :sepal_width,
                     :petal_length,
                     :petal_width,
                     :label
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.sepal_length,
                     @table[0, :sepal_length])
      end

      test("column name only") do
        sepal_width_column = @data.map(&:sepal_width)
        assert_equal(Charty::Vector,
                     @table[:sepal_width].class)
        assert_equal(sepal_width_column,
                     @table[:sepal_width].data)
      end
    end
  end

  sub_test_case("mushroom") do
    def setup
      @data = Datasets::Mushroom.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :label,
                     :cap_shape,
                     :cap_surface,
                     :cap_color,
                     :bruises,
                     :odor,
                     :gill_attachment,
                     :gill_spacing,
                     :gill_size,
                     :gill_color,
                     :stalk_shape,
                     :stalk_root,
                     :stalk_surface_above_ring,
                     :stalk_surface_below_ring,
                     :stalk_color_above_ring,
                     :stalk_color_below_ring,
                     :veil_type,
                     :veil_color,
                     :n_rings,
                     :ring_type,
                     :spore_print_color,
                     :population,
                     :habitat,
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.cap_shape,
                     @table[0, :cap_shape])
      end

      test("column name only") do
        odor_column = @data.map(&:odor)
        assert_equal(Charty::Vector,
                     @table[:odor].class)
        assert_equal(odor_column,
                     @table[:odor].data)
      end
    end
  end

  sub_test_case("postal-code-japan") do
    def setup
      @data = Datasets::PostalCodeJapan.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :organization_code,
                     :old_postal_code,
                     :postal_code,
                     :prefecture_reading,
                     :city_reading,
                     :address_reading,
                     :prefecture,
                     :city,
                     :address,
                     :have_multiple_postal_codes,
                     :have_address_number_per_koaza,
                     :have_chome,
                     :postal_code_is_shared,
                     :changed,
                     :change_reason,
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.postal_code,
                     @table[0, :postal_code])
      end

      test("column name only") do
        prefecture_column = @data.map(&:prefecture)
        assert_equal(Charty::Vector,
                     @table[:prefecture].class)
        assert_equal(prefecture_column,
                     @table[:prefecture].data)
      end
    end
  end

  sub_test_case("wine") do
    def setup
      @data = Datasets::Wine.new
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal([
                     :label,
                     :alcohol,
                     :malic_acid,
                     :ash,
                     :alcalinity_of_ash,
                     :n_magnesiums,
                     :total_phenols,
                     :total_flavonoids,
                     :total_nonflavanoid_phenols,
                     :total_proanthocyanins,
                     :color_intensity,
                     :hue,
                     :optical_nucleic_acid_concentration,
                     :n_prolines,
                   ],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        first_record = @data.first
        assert_equal(first_record.malic_acid,
                     @table[0, :malic_acid])
      end

      test("column name only") do
        hue_column = @data.map(&:hue)
        assert_equal(Charty::Vector,
                     @table[:hue].class)
        assert_equal(hue_column,
                     @table[:hue].data)
      end
    end
  end
end
