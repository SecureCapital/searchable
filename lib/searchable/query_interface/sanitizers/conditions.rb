module Searchable::QueryInterface
	module Sanitizers
		class Conditions < Base
			attr_writer :_filters, :_allow_xor, :_allow_xor_not
			attr_reader :_filters, :where, :where_not, :xor, :xor_not

      # :_filters => {
      # 	:issue_id => {
      # 		:type => :integer/:numeric/:boolean/:string/:date/:datetime,
      # 		:is_array => Boolean,
      # 		:is_range => Boolean
      # 		:is_relatyion => Boolean
      # 	},
      # 	...
      # }

			def _allow_xor
				if @_allow_xor == false
					false
				else
					true
				end
			end

			def _allow_xor_not
				if @_allow_xor_not == false
					false
				else
					true
				end
			end

			def to_h
				h = field_set.map{|k| [k, send(k)]}.to_h.slice(*field_set).reject do |k,v|
					v.respond_to?(:empty?) && v.empty?
				end
				h.delete(:xor) unless  _allow_xor
				h.delete(:xor_not) unless  _allow_xor_not
				h
			end

			def field_set
				%i(where where_not xor xor_not)
			end

			def rule_set
				%i(_filters _allow_xor _allow_xor_not)
			end

			def _allowed_fields
				_filters.keys
			end

			%i(where where_not xor xor_not).each do |meth|
				define_method("#{meth}=") do |hash|
					h = convert_with_exception(hash, meth, 'Hash') do
						hash.to_h
					end
					# Silently reject unpermitted filtering attributes
					h.reject!{|k,v| _allowed_fields.exclude?(k)}
					# Convert all values
					h.each do |k,v|
						rule = _filters[k]
						@field = "where.#{k}"
						@type = rule[:type]
						h[k] = if rule[:is_array]
							set_array(v)
						elsif rule[:is_range]
							set_range(v)
						elsif rule[:is_relation]
							set_relation(v, k, rule)
						else
							set_value(v)
						end
					end
					instance_variable_set("@#{meth}", h)
				end
			end

			def set_array(value)
				unless value.respond_to?(:map) || value.respond_to?(:to_a)
					return set_value(value)
				end
				values = convert_with_exception(value, :array, "Array") do
					value.to_a
				end
				return nil if values.blank?
				values.map do |v|
					set_value(v)
				end.uniq
			end

			
      def set_relation(relation, value, rule)
				unless value.respond_to?(:map) || value.respond_to?(:to_a)
					return set_value(value)
				end
				values = convert_with_exception(value, :array, "Array") do
					value.to_a
				end
				return nil if values.blank?

        vals = values.map do |v|
          set_value(v)
        end.uniq

        # Attemt to constantize relation model
        relation_model = rule[:model].to_s.singularize.camelcase.constantize
        
          
        relation_model.where(rule[:related_field].to_s => vals)
			end


			def set_range(value)
				return nil if value.blank?
				if value.is_a?(String) && ((value =~ /.*\.\..*/) == 0)
					from, to = value.split('..')
					from = set_value(from)
					from ||= -infinity
					to = set_value(to)
					to ||= infinity
					if from < to
						from..to
					else
						to..from
					end
				else
					set_value(value)
				end
			end

			def set_value(value)
				convert_with_exception(value, @field, @type) do
					case @type
					when :string then value.to_s
					when :integer then
						v = value.to_i
						if (v == 0) && (value != '0')
							raise Exceptions::ConversionError.new "Unknown format: #{@type}"
						end
						v
					when :numeric then
						v = value.to_f
						if (v == 0) && !((value == '0')||(value == '0.0'))
							raise Exceptions::ConversionError.new "Unknown format: #{@type}"
						end
						v
					when :date then Date.parse(value)
					when :datetime then DateTime.parse(value)
					when :boolean then to_boolean(value, allow_blank: true)
					else
						raise Exceptions::ConversionError.new "Unknown format: #{@type}"
					end
				end
			end

			def infinity
				case @type
				when :date then Date::Infinity.new
				when :datetime then DateTime::Infinity.new
				when :numeric, :integer then Float::INFINITY
				else
					raise Exceptions::ConversionError.new "Could not find infinity on type #{@type}"
				end
			end
		end
	end
end
