module Searchable::QueryInterface
	module Sanitizers
		class Base
			def field_set
				@feild_set ||= []
			end

			def field_has_been_set(value)
				field_set << value unless field_set.include?(value)
			end

			def self.sanitize!(**args)
				new(**args).to_h
			end

			def initialize(**args, &block)
				field_set
				key_set.each do |k|
					if args.keys.include?(k)
						self.send("#{k}=", args[k])
						field_has_been_set(k)
					end
				end
				yield self if block_given?
			end

			def key_set
				rule_set + field_set
			end

			def rule_set
				%i()
			end

			def to_h
				field_set.map{|k| [k, send(k)]}.to_h.slice(*field_set).compact
			end

			def convert_with_exception(value, field, type, return_blank: true, &block)
				if return_blank
					return nil if value.respond_to?(:blank?) && value.blank? && (value!=false)
				end
				begin
					yield
				rescue
					str_value = value.respond_to?(:to_s) ? value.to_s : 'NON_STRING_VALUE'
					raise Exceptions::ConversionError.new("Faild to convert `#{str_value}` for field `#{field}` to type `#{type}`." )
				end
			end

			def to_boolean(value, allow_blank: true)
				if (value == false) || (value == 'false') || (value == '0') || (value == 0)
					false
				elsif (value == true) || (value == 'true') || (value == '1') || (value == 1)
					true
				else
					if allow_blank
						nil
					else
						raise Exceptions::ConversionError.new("Unable to transform value to boolean")
					end
				end
			end
		end
	end
end
