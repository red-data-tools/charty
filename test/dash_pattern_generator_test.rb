class DashPatternGeneratorTest < Test::Unit::TestCase
  def setup
    # Generated by the following python code:
    # [list(x) if x else x for x in seaborn._core.unique_dashes(30)]
    @expected_dashes = [
      "",
      [4, 1.5],
      [1, 1],
      [3, 1.25, 1.5, 1.25],
      [5, 1, 1, 1],
      [3, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 1, 1],
      [3, 1.25, 3, 1.25, 1.25, 1.25],
      [4, 1, 1, 1, 1, 1],
      [3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 1, 1],
      [3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 1, 1, 1, 1],
      [3, 1.25, 3, 1.25, 3, 1.25, 1.25, 1.25],
      [4, 1, 1, 1, 1, 1, 1, 1],
      [3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 4, 1, 1, 1],
      [3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 1, 1, 1, 1],
      [3, 1.25, 3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 1, 1, 1, 1, 1, 1],
      [3, 1.25, 3, 1.25, 3, 1.25, 3, 1.25, 1.25, 1.25],
      [4, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 1, 1],
      [3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 4, 1, 1, 1, 1, 1],
      [3, 1.25, 3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25],
      [4, 1, 4, 1, 4, 1, 1, 1, 1, 1, 1, 1],
      [3, 1.25, 3, 1.25, 3, 1.25, 3, 1.25, 1.25, 1.25, 1.25, 1.25]
    ]
  end

  test("the first 20 patterns") do
    generator = Charty::DashPatternGenerator
    assert_equal(@expected_dashes[0, 20],
                 generator.take(20))
  end

  test("#valid_name?") do
    assert_equal({
                   solid: true,
                   longdash: false
                 },
                 {
                   solid: Charty::DashPatternGenerator.valid_name?(:solid),
                   longdash: Charty::DashPatternGenerator.valid_name?(:longdash)
                 })
  end
end
