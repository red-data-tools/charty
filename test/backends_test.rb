require_relative "./test_helper"
require_relative "./lib/load_error_backend"

class BackendsTest < Test::Unit::TestCase
  sub_test_case(".find_backend_class") do
    test("find by symbol") do
      backend_class = Charty::Backends.find_backend_class(:pyplot)
      assert_equal(Charty::Backends::Pyplot, backend_class)
    end

    test("find by string") do
      backend_class = Charty::Backends.find_backend_class("pyplot")
      assert_equal(Charty::Backends::Pyplot, backend_class)
    end

    test("unregistered backend") do
      assert_raise(Charty::BackendNotFoundError) do
        Charty::Backends.find_backend_class("unregistered_backend")
      end
    end

    test("unable to prepare backend") do
      assert_raise(Charty::BackendLoadError) do
        Charty::Backends.find_backend_class("load_error_backend")
      end
    end
  end
end
