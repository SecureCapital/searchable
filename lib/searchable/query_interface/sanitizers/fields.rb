module Searchable::QueryInterface
	module Sanitizers
		class Fields < Base
			attr_writer :_allowed_fields, :_required_fields
			attr_reader :_required_fields, :fields

			def rule_set
				%i(_required_fields _allowed_fields)
			end

			def field_set
				%i(fields)
			end

			def _allowed_fields
				@_allowed_fields||Searchable::QueryInterface.allowed_fields
			end

			def fields=(flds)
				return nil if _allowed_fields == :none

				flds = convert_with_exception(flds, :fields, 'Array') do
					flds.to_a.flatten
				end
				# Take all fields in
				@fields = flds.map do |fld|
					if (fld.is_a?(String) || fld.is_a?(Symbol)) && !fld.blank?
						fld.to_s
					end
				end.compact

				# If whitelist use intersection, do not raise exception!
				if _allowed_fields.is_a?(Array)
					@fields = @fields & _allowed_fields
				end

				# If required fields append
				if _required_fields
					@fields += _required_fields
					@fields.uniq!
				end

				# If empty or fields are not allowed specified return blank
				@fields = nil if @fields.empty?
				@fields
			end
		end
	end
end
