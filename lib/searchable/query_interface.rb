require_relative './query_interface/builder.rb'
require_relative './query_interface/exceptions.rb'
require_relative './query_interface/sanitizers.rb'
require_relative './query_interface/controller_methods.rb'

module Searchable
	module QueryInterface
		class << self
			def config
				@config ||= OpenStruct.new(
					sanitize_fields: true, # Wheter or not the iser may sumit fields
					sanitize_search: true, # Whereter or not the user may submit search queries
					sanitize_changed_sinze: true, # Wheter or not the user may submit schanged_sinze query
					sanitize_conditions: true, # Wheter or not to allow where, or, not, or not conditions
					sanitize_tagging: true, # Wheter to call acts_as taggable with conditions
					sanitize_order: true, # Wheter or not to allow he user to set ordering
					max_limit: 10000, # Global default max limit results
					allowed_fields: :any, # :any/:none to pre-allow select on any or not allow select query
					allow_search: true, # To allow search(...) by defualt
					allowed_tags_on: :any, # :any/:none to allow the user to specify tags_on fields or not
					allowed_ordering: :any, #Array/:any/:none
					search_fuzzy_default: true,
					search_join_default: 'OR',
				)
			end

			# Partialize this!
			def configure(&block)
	      yield config if block_given?
	      config.to_h.keys.each do |key|
	        self.class.define_method(key){config[key]} unless respond_to?(key)
	      end
	    end
		end

		configure
	end
end
