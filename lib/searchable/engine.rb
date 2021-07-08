module Searchable
  class Engine < ::Rails::Engine
    isolate_namespace Searchable
    config.generators.api_only = true
  end
end
