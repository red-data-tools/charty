$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "charty"
require "test/unit"
require "tmpdir"

require "active_record"
require "bigdecimal"
require "csv"
require "daru"
require "datasets"
require "set" # NOTE: daru needs set

require "iruby"
require "iruby/logger"
IRuby.logger = Logger.new(STDERR, level: Logger::Severity::INFO)

begin
  require "numo/narray"
rescue LoadError
end

begin
  require "nmatrix"
rescue LoadError
end

begin
  require "matplotlib"
rescue LoadError, StandardError
end

begin
  require "pandas"
rescue LoadError, StandardError
end

begin
  require "arrow"
rescue LoadError
end

module Charty
  module PythonTestHelpers
    def define_python_warning_check
      PyCall.exec(<<PYTHON)
import contextlib
import io
import re
import sys

class WarningCheckError(Exception):
  pass

class CaptureIO(io.TextIOWrapper):
  def __init__(self) -> None:
    super().__init__(io.BytesIO(), encoding="UTF-8", newline="", write_through=True)

  def getvalue(self) -> str:
    assert isinstance(self.buffer, io.BytesIO)
    return self.buffer.getvalue().decode("UTF-8")

class WarningCheckIO(CaptureIO):
  def __init__(self, pattern: str) -> None:
    super().__init__()
    self.pattern = pattern

  def write(self, s: str) -> int:
    if re.search(self.pattern, s) is not None:
      raise WarningCheckError(s)
    return super().write(s)

@contextlib.contextmanager
def warning_check(pattern: str):
  old = sys.stderr
  setattr(sys, "stderr", WarningCheckIO(pattern))
  try:
    yield
  finally:
    setattr(sys, "stderr", old)
PYTHON
    end

    def python_warning_check(pattern)
      f = PyCall.eval("warning_check")
      f.(pattern)
    rescue PyCall::PyError
      define_python_warning_check
      python_warning_check(pattern)
    end

    def check_python_warning(pattern, &block)
      PyCall.with(python_warning_check(pattern), &block)
    end
  end

  module TestHelpers
    include PythonTestHelpers

    def setup
      super
      if pandas_available?
        check_python_warning("FutureWarning") do
          yield
        end
      end
    end

    module_function def arrow_available?
      defined?(::Arrow::Table) and Arrow::Version::MAJOR >= 6
    end

    module_function def arrow_required
      omit("red-arrow 6.0.0 or later is requried") unless arrow_available?
    end

    module_function def numo_available?
      defined?(::Numo::NArray)
    end

    module_function def numo_required
      omit("Numo::NArray is requried") unless numo_available?
    end

    module_function def nmatrix_available?
      return false if RUBY_VERSION >= "3.0" # SEGV occurs in NMatrix on Ruby >= 3.0
      defined?(::NMatrix::VERSION::STRING)
    end

    module_function def nmatrix_required
      omit("NMatrix is requried") unless nmatrix_available?
    end

    module_function def matplotlib_available?
      defined?(::Matplotlib)
    end

    module_function def matplotlib_required
      omit("Matplotlib is required") unless matplotlib_available?
    end

    module_function def numpy_available?
      pandas_available?
    end

    module_function def numpy_required
      omit("Numpy is required") unless numpy_available?
    end

    module_function def pandas_available?
      defined?(::Pandas)
    end

    module_function def pandas_required
      omit("Pandas is required") unless pandas_available?
    end

    def assert_near(c1, c2, eps=1e-8)
      assert_equal(c1.class, c2.class)
      c1.components.zip(c2.components).each do |x1, x2|
        x1, x2 = [x1, x2].map(&:to_f)
        assert { (x1 - x2).abs < eps }
      end
    end
  end

  module RenderingTestHelpers
    include Charty::TestHelpers

    def setup_data(adapter_name)
      setup_array_data
      case adapter_name
      when :arrow
        arrow_required
        setup_arrow_data
      when :daru
        setup_daru_data
      when :nmatrix
        nmatrix_required
        setup_nmatrix_data
      when :numo
        numo_required
        setup_numo_data
      when :pandas
        pandas_required
        setup_pandas_data
      when :numpy
        pandas_required
        setup_numpy_data
      end
    end

    def setup_backend(backend_name)
      case backend_name
      when :pyplot
        if defined?(Matplotlib)
          setup_pyplot_backend
        else
          matplotlib_required
        end
      end
      Charty::Backends.use(backend_name)
    end

    def setup_pyplot_backend
      require "matplotlib"
      Matplotlib.use("agg")
    end

    def render_plot(backend_name, plot, **kwargs)
      plot.render(**kwargs)
    end
  end

  module IRubyTestHelper
    def setup_iruby
      @__iruby_config_dir = Dir.mktmpdir("iruby-test")
      @__iruby_config_path = Pathname.new(@__iruby_config_dir) + "config.json"
      File.write(@__iruby_config_path, {
        control_port: 50160,
        shell_port: 57503,
        transport: "tcp",
        signature_scheme: "hmac-sha256",
        stdin_port: 52597,
        hb_port: 42540,
        ip: "127.0.0.1",
        iopub_port: 40885,
        key: "a0436f6c-1916-498b-8eb9-e81ab9368e84"
      }.to_json)

      @__original_iruby_kernel_instance = IRuby::Kernel.instance

      IRuby::Kernel.new(@__iruby_config_path.to_s, "test")
      $stdout = STDOUT
      $stderr = STDERR
    end

    def teardown_iruby
      IRuby::Kernel.instance = @__original_iruby_kernel_instance
    end
  end
end
