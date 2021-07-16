require_relative './sanitizers/base.rb'
require_relative './sanitizers/changed_since.rb'
require_relative './sanitizers/conditions.rb'
require_relative './sanitizers/fields.rb'
require_relative './sanitizers/order.rb'
require_relative './sanitizers/pagination.rb'
require_relative './sanitizers/search.rb'
require_relative './sanitizers/tagging.rb'

module Searchable::QueryInterface
	module Sanitizers
		def self.sanitize!(params, rules)
			params = params.to_h.deep_symbolize_keys.strip_strings!.nilify_blanks!
			params[:xor] = params.delete(:or) if params.keys.include?(:or)
			params[:xor_not] = params.delete(:or_not) if params.keys.include?(:or_not)

			search = {}
			search = params.delete(:search) if params.keys.include?(:search)
			search = search.merge(rules.slice(*%i(_allow_search _default_search_field _allowed_search_fields)))

			tagged = {}
			tagged = params.delete(:tagged) if params.keys.include?(:tagged) && params[:tagged].is_a?(Hash)
			tagged = tagged.merge(rules.slice(*%i(_allowed_tags_on)))

			args = {}
			args.deep_merge! Fields.sanitize!(**params.merge(rules)) if Searchable::QueryInterface.sanitize_fields
			args.deep_merge! Search.sanitize!(**search) if search.any? && Searchable::QueryInterface.sanitize_search
			args.deep_merge! ChangedSince.sanitize!(**params.merge(rules)) if Searchable::QueryInterface.sanitize_changed_sinze
			args.deep_merge! Conditions.sanitize!(**params.merge(rules)) if Searchable::QueryInterface.sanitize_conditions
			args.deep_merge! Tagging.sanitize!(**tagged) if tagged.any? && Searchable::QueryInterface.sanitize_tagging
			args.deep_merge! Pagination.sanitize!(**params.merge(rules))
			args.deep_merge! Order.sanitize!(**params.merge(rules)) if Searchable::QueryInterface.sanitize_order
			args
		end
	end
end
