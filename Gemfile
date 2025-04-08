source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in charty.gemspec
gemspec

group :development, :test do
  gem "bundler", ">= 1.16"
  gem "csv"
  gem "daru"
  gem "fiddle"
  gem "iruby", ">= 0.7.0"
  gem "matrix" # need for daru on Ruby > 3.0
  gem "rake"
end

group :test do
  gem "test-unit"
end

group :activerecord do
  gem "activerecord"
  # We may need to specify version explicitly to align with `gem
  # "sqlite", "..."` in
  # lib/active_record/connection_adapters/sqlite3_adapter.rb.
  gem "sqlite3"
end

group :cruby do
  gem "enumerable-statistics"
end

group :numo do
  gem "numo-narray"
end

group :python do
  gem "matplotlib"
  gem "numpy"
  gem "pandas"
end
