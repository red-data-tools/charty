source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in charty.gemspec
gemspec

group :development, :test do
  gem "bundler", ">= 1.16"
  gem "csv"
  gem "daru"
  gem "iruby", ">= 0.7.0"
  gem "matrix" # need for daru on Ruby > 3.0
  gem "rake"
end

group :test do
  gem "test-unit"
end

group :activerecord do
  gem "activerecord"
  # This must be synchronized with `gem "sqlite", "..."` in
  # lib/active_record/connection_adapters/sqlite3_adapter.rb.
  gem "sqlite3", "~> 1.4"
end

group :cruby do
  gem "enumerable-statistics"
end

group :nmatrix do
  gem "nmatrix"
end

group :numo do
  gem "numo-narray"
end

group :python do
  gem "matplotlib"
  gem "numpy"
  gem "pandas"
end
