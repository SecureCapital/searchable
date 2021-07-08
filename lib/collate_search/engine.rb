module CollateSearch
  class Engine < ::Rails::Engine
    isolate_namespace CollateSearch
    config.generators.api_only = true
  end
end
