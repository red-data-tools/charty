require "pathname"

module Charty
  module CacheDir
    module_function

    def cache_dir_path
      platform_cache_dir_path + "charty"
    end

    def platform_cache_dir_path
      base_dir = case RUBY_PLATFORM
                 when /mswin/, /mingw/
                   ENV.fetch("LOCALAPPDATA", "~/AppData/Local")
                 when /darwin/
                   "~/Library/Caches"
                 else
                   ENV.fetch("XDG_CACHE_HOME", "~/.cache")
                 end
      Pathname(base_dir).expand_path
    end

    def path(*path_components)
      cache_dir_path.join(*path_components)
    end
  end
end
