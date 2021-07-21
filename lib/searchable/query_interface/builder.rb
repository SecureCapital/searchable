# Caller of of rails query interface given structure of requitrement on the query.
# We expect at this point that arguments has been sanitized, and all arguments
# are composed propperly

module Searchable::QueryInterface
	class Builder
		attr_accessor :chain, :limit, :page, :offset, :fields, :search,
			:tagged, :order, :updated_at, :where, :where_not, :xor, :xor_not

		def self.call(**args)
			inst = new(**args)
			inst.result_hash
		end

		def self.to_sql(**args)
			new(**args).to_sql
		end

		def initialize(**args, &block)
			args.each do |k,v|
				send("#{k}=", v)
			end
			yield self if block_given?
		end

		def result_hash
			{
				data: call,
				count: count,
				limit: limit,
				page: page,
				offset: offset
			}
		end

		def offset
			return @offset if @offset
			if @page && @limit
				return @page * @limit - @limit
			end
			return 0
		end

		def page
			return @page if @page
			if @limit && @offset
				return (@offset.to_f / @limit).floor + 1
			end
			return 1
		end

		def taggable?
		  chain.respond_to?(:taggable?) && chain.taggable? && tagged && tagged['tags']
		end

		def searchable?
			chain.respond_to?(:search)
		end

		def base_chain
			q = "chain"
			q << ".select(*fields)" if fields
			q << ".search(**search)" if searchable? && search
			q << ".where('`#{chain.table_name}`.`updated_at` > ?': updated_at)" if updated_at
			q << ".where(where)" if where
			q << ".where.not(where_not)" if where_not
			q << ".or(chain#{fields ? '.select(*fields)':''}.where(xor).where.not(or_not))" if (where || where_not) && xor && xor_not
			q << ".or(chain#{fields ? '.select(*fields)':''}.where(xor))" if (where || where_not) && xor && !xor_not
			q << ".or(chain#{fields ? '.select(*fields)':''}.where.not(xor_not))" if (where || where_not) && xor_not && !xor
			q << ".tagged_with(*tagged['tags'], **tagged.except('tags'))" if taggable?
			unless q.index("\.")
				q << ".all"
			end
			q
		end

		def chained_call
			q = base_chain
			q << ".order(order)" if order
			q << ".limit(limit)" if limit
			q << ".offset(offset)" if offset && offset > 0
			q
		end

		def call
			eval(chained_call)
		end

		def count
			eval "#{base_chain}.count(:all)"
		end

		# def count
		# 	eval(base_chain.sub(".select(*fields)", '')+'.count')
		# end

		def to_sql
			eval(chained_call).to_sql
		end
	end
end
