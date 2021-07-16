module Searchable::QueryInterface
	module Sanitizers
		class Pagination < Base
			attr_writer :_max_limit
			attr_reader :limit, :offset, :page

			def initialize(**args, &block)
				super(**{limit: nil}.merge(args), &block)
			end

			def rule_set
				%i(_max_limit)
			end

			def field_set
				%i(limit offset page)
			end

			def _max_limit
				@_max_limit || Searchable::QueryInterface.max_limit
			end

			def limit=(value)
				@limit = convert_with_exception(value, :limit, 'Integer') do
					value.to_i
				end
				@limit = _max_limit if @limit.blank?
				raise Exceptions::LimitError.new("Disallowed limit `#{@limit}` given, should be greater than 0.") if @limit < 1
				raise Exceptions::LimitError.new("Disallowed limit `#{@limit}` given, should be less than or equal to #{_max_limit}") if @limit > _max_limit
				@limit
			end

			def offset=(value)
				@offset = convert_with_exception(value, :offset, 'Integer') do
					value.to_i
				end
				return nil if @offset.blank?
				raise Exceptions::OffsetError.new("Offset `#{@offset}` given, but should be positive") if @offset < 0
				@offset
			end

			def page=(value)
				@page = convert_with_exception(value, :page, 'Integer') do
					value.to_i
				end
				return nil if @page.blank?
				raise Exceptions::OffsetError.new("Page `#{@page}` given, but should be at least 1") if @page < 1
				@page
			end
		end
	end
end
