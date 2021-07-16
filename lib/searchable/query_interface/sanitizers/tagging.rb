module Searchable::QueryInterface
	module Sanitizers
		class Tagging < Base
			attr_reader :tags, :on, :any, :match_all, :exclude
			attr_writer :_allowed_tags_on

			def rule_set
				%i(_allowed_tags_on)
			end

			def field_set
				%i(tags on any match_all exclude)
			end

			def _allowed_tags_on
				@_allowed_tags_on || Searchable::QueryInterface.allowed_tags_on
			end

			def tags=(items)
				items = convert_with_exception(items, "tagged.tags", 'Array') do
					items.to_a.flatten
				end
				@tags = items.map do |item|
					convert_with_exception(item, :tags, 'String') do
						item.to_s
					end
				end.compact
			end

			def on=(value)
				@on = convert_with_exception(value, 'tagged.on', 'String') do
					value.to_s
				end
				return @on = nil if @on.blank?
				if _allowed_tags_on.is_a?(Array)
					if _allowed_tags_on.exclude?(@on)
						raise Exceptions::ProhibitedFieldError.new "Prohibited value `#{@on}` for `tagged`.`on`. Use on of the fields in `#{_allowed_tags_on.map(&:to_s).join('`, `')}`"
					end
				elsif (_allowed_tags_on == :none)
					raise Exceptions::ProhibitedFieldError.new "Prohibited value `#{@on}` for `tagged`.`on`. No value is allowed for `tagged`.`on`"
				end
			end

			def any=(value)
				@any = convert_with_exception(value, 'tagged.any', 'Boolean') do
					to_boolean(value, allow_blank: false)
				end
			end

			def match_all=(value)
				@match_all = convert_with_exception(value, 'tagged.match_all', 'Boolean') do
					to_boolean(value, allow_blank: false)
				end
			end

			def exclude=(value)
				@exclude = convert_with_exception(value, 'tagged.exclude', 'Boolean') do
					to_boolean(value, allow_blank: false)
				end
			end

			def to_h
				return {} if super.empty?
				{tagged: super}
			end
		end
	end
end
