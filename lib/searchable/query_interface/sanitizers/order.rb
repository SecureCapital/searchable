module Searchable::QueryInterface
	module Sanitizers
		class Order < Base
			attr_reader :order
			attr_writer :_allowed_ordering

			def field_set
				%i(order)
			end

			def rule_set
				%i(_allowed_ordering)
			end

			def _allowed_ordering
				@_allowed_ordering||Searchable::QueryInterface.allowed_ordering
			end

			def order=(hash)
				return nil if _allowed_ordering == :none

				@order = convert_with_exception(hash, :order, 'Hash') do
					hash.to_h
				end
				@order.each do |k,v|
					val = convert_with_exception(v, k, 'String') do
						val = v.to_s
						if val =~ /^desc$/i
							val = 'desc'
						elsif val =~ /^asc$/i
							val = 'asc'
						else
							val = nil
						end
						val
					end
					raise Exceptions::ConversionError.new("Expected ordering attribute `#{k}` to be of value 'ASC' or 'DESC'") if val.nil?
					@order[k] = val
				end

				if _allowed_ordering.is_a?(Array)
					@order = @order.slice(*_allowed_ordering)
				end

				@order = nil if @order.empty?
				@order
			end
		end
	end
end
