module Searchable::QueryInterface
  module ControllerMethods
    def qi_build_sql(chain:, params:, rules:)
      hash = qi_sanitize(params: params, rules: rules)
      Searchable::QueryInterface::Builder.to_sql(**hash.merge(chain: chain))
    end

    def qi_build(chain:, params:, rules:)
      hash = qi_sanitize(params: params, rules: rules)
      qi_builder(**hash.merge(chain: chain))
    end

    def qi_builder(**args)
      Searchable::QueryInterface::Builder.call(**args)
    end

    def qi_sanitize(params:, rules:)
      Searchable::QueryInterface::Sanitizers.sanitize!(params, rules)
    end

    def with_qi_rescue
      begin
				yield
			rescue Searchable::QueryInterface::Exceptions::ConversionError,
						 Searchable::QueryInterface::Exceptions::LimitError,
						 Searchable::QueryInterface::Exceptions::OffsetError,
						 Searchable::QueryInterface::Exceptions::ProhibitedFieldError => e
			  return {error: "Incompatible query: #{e}"}
			rescue ActiveRecord::StatementInvalid => e
        return {error: "Invalid statement (this could be server-sided): #{e}"}
			end
    end
  end
end
