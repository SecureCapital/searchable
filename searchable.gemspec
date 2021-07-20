require_relative "lib/searchable/version"

Gem::Specification.new do |spec|
  spec.name        = "searchable"
  spec.version     = Searchable::VERSION
  spec.authors     = ["MadsJaeger"]
  spec.email       = ["mhh@securespectrum.dk"]
  spec.homepage    = "https://www.github.com/MadsJaeger/searchable"
  spec.summary     = "Indexing active records as searchable and query interface to active record"
  spec.description = "The developer will get full control on the searchble string per record, which will be stored into `searchble_indices`. A querry interface is provided turning a json arguments into complex queries leveraging active records qurying methods."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://www.github.com/MadsJaeger/searchable/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.3", ">= 6.1.3.2"
  spec.add_dependency "sidekiq", "~> 6.2", ">= 6.2.1"
  spec.add_dependency "sidekiq-symbols", "=0.2.0"
  spec.add_development_dependency "pry"
end
