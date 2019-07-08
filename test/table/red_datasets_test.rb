require 'test_helper'
require 'datasets'

class TableRedDatasetsTest < Test::Unit::TestCase
  test("adult") do
    data = Datasets::Adult.new
    table = Charty::Table.new(data)
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
                 table.columns)
    first_record = data.first
    assert_equal(first_record.age,
                 table[0, :age])
  end

  test("iris") do
    data = Datasets::Iris.new
    table = Charty::Table.new(data)
    assert_equal([
                   :sepal_length,
                   :sepal_width,
                   :petal_length,
                   :petal_width,
                   :label
                 ],
                 table.columns)
    first_record = data.first
    assert_equal(first_record.sepal_length,
                 table[0, :sepal_length])
  end

  test("mushroom") do
    omit("Datasets::Mushroom is required") unless defined?(Datasets::Mushroom)
    data = Datasets::Mushroom.new
    table = Charty::Table.new(data)
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
                 table.columns)
    first_record = data.first
    assert_equal(first_record.cap_shape,
                 table[0, :cap_shape])
  end

  test("postal-code-japan") do
    omit("Datasets::PostalCodeJapan is required") unless defined?(Datasets::PostalCodeJapan)
    data = Datasets::PostalCodeJapan.new
    table = Charty::Table.new(data)
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
                 table.columns)
    first_record = data.first
    assert_equal(first_record.postal_code,
                 table[0, :postal_code])
  end

  test("wine") do
    omit("Datasets::Wine is required") unless defined?(Datasets::Wine)
    data = Datasets::Wine.new
    table = Charty::Table.new(data)
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
                 table.columns)
    first_record = data.first
    assert_equal(first_record.malic_acid,
                 table[0, :malic_acid])
  end
end
