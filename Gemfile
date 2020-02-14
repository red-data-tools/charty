source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in charty.gemspec
gemspec

group :matplotlib do
  gem "matplotlib"
end

group :nmatrix do
  gem "nmatrix"
end

group :numo do
  gem "numo-narray"
end

if defined?(JRUBY_VERSION)
  gem "activerecord-jdbcsqlite3-adapter"
else
  gem "sqlite3"
end
