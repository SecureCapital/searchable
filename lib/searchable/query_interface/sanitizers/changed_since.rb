require_relative './base.rb'

module Searchable::QueryInterface
	module Sanitizers
		class ChangedSince < Base
			attr_reader :updated_at

			def field_set
				%i(updated_at)
			end

			def updated_at=(value)
				@updated_at = convert_with_exception(value, :updated_at, 'DateTime') do
					DateTime.parse(value)
				end
			end
		end
	end
end
