lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "charty/version"

Gem::Specification.new do |spec|
  spec.name          = "charty"
  version_components = [
    Charty::Version::MAJOR.to_s,
    Charty::Version::MINOR.to_s,
    Charty::Version::MICRO.to_s,
    Charty::Version::TAG,
  ]
  spec.version       = version_components.compact.join(".")
  spec.authors       = ["youchan", "mrkn", "284km"]
  spec.email         = ["youchan01@gmail.com", "mrkn@mrkn.jp", "k.furuhashi10@gmail.com"]

  spec.summary       = %q{Visualizing your data in a simple way.}
  spec.description   = %q{Visualizing your data in a simple way.}
  spec.homepage      = "https://github.com/red-data-tools/charty"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "red-colors", ">= 0.3.0"
  spec.add_dependency "red-datasets", ">= 0.1.2"
  spec.add_dependency "red-palette", ">= 0.5.0"

  spec.add_dependency "matplotlib", ">= 1.2.0"
  spec.add_dependency "pandas", ">= 0.3.5"
  spec.add_dependency "playwright-ruby-client"

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "daru"
  spec.add_development_dependency "matrix" # need for daru on Ruby > 3.0
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "iruby", ">= 0.7.0"
  spec.add_development_dependency "csv"
end
