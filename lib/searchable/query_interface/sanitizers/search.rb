module Searchable::QueryInterface
	module Sanitizers
		class Search < Base
			attr_writer :_allowed_search_fields, :_default_search_field, :_allow_search

			# def with_having
			# 	return false if @with_having == false
			# 	@with_having || false
			# end
			#
			# def with_having=(value)
			# 	@with_having = convert_with_exception(value, 'search.with_having', 'Boolean') do
			# 		to_boolean(value, allow_blank: true)
			# 	end
			# end

			def fuzzy
				return false if @fuzzy == false
				@fuzzy || Searchable::QueryInterface.search_fuzzy_default
			end

			def fuzzy=(value)
				@fuzzy = convert_with_exception(value, 'search.fuzzy', 'Boolean') do
					to_boolean(value, allow_blank: true)
				end
			end

			def join
				@join || Searchable::QueryInterface.search_join_default
			end

			def join=(value)
				return nil if value.respond_to?(:blank?) && value.blank?
				if value.is_a?(String)
					if value =~ /^or$/i
						@join = 'OR'
					elsif value =~ /^and$/i
						@join = 'AND'
					else
						raise Exceptions::ConversionError.new("Expected string given in search.join with the value 'OR' or 'AND', but recieved `#{value}`" )
					end
				else
					raise Exceptions::ConversionError.new("Expected string given in search.join but recieved `#{value.class.name}`. Please supply string with the value 'OR' or 'AND'" )
				end
				@join
			end

			def rule_set
				%i(_allow_search _default_search_field _allowed_search_fields)
			end

			def argument_fields
				%i(join fuzzy)
			end

			def _allow_search
				return false  if @_allow_search == false
				@_allow_search || Searchable::QueryInterface.allow_search
			end

			def _allowed_search_fields
				@_allowed_search_fields||:any
			end

			def _default_search_field
				@_default_search_field||:searchable
			end

			def initialize(**args, &block)
				field_set
				(rule_set+argument_fields).each do |k|
					if args.keys.include?(k)
						self.send("#{k}=", args[k])
						field_has_been_set(k) if argument_fields.include?(k)
					end
				end
				field_has_been_set(:fuzzy)
				field_has_been_set(:join)

				if _allow_search
					parsing_args = args.except(*rule_set)
					parsing_args = parsing_args.except(*argument_fields)
					if _allowed_search_fields.is_a?(Array)
						extra_search_fields = parsing_args.keys - _allowed_search_fields - [:default]
						if extra_search_fields.any?
							raise Exceptions::ProhibitedFieldError.new "Fields `#{extra_search_fields.map(&:to_s).join(', ')}` are not permitted! Allowef ields are contained in `#{_allowed_search_fields.map(&:to_s).join(', ')}`"
						end
					end

					parsing_args.each do |field, value|
						define_search_pair(field, value)
					end
				end

				yield self if block_given?
			end

			def define_search_pair(field, value)
				return if value.nil? || (value.respond_to?(:blank?) && value.blank?)
				raise Exceptions::ConversionError.new("Expected string given in search.#{field} but recieved `#{value.class.name}`. Please suplly a string.") unless value.is_a?(String)
				key = (field == :default) ? _default_search_field : field
				instance_variable_set("@#{key}", value)
				define_singleton_method(key){instance_variable_get("@#{key}")}
				field_has_been_set(key)
			end

			def to_h
				if _allow_search
					{search: super}
				else
					{}
				end
			end
		end
	end
end
