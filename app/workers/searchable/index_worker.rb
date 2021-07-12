require 'sidekiq'
require 'sidekiq-symbols'

module Searchable
  class IndexWorker
    include ::Sidekiq::Worker
    include ::Sidekiq::Symbols
    sidekiq_options queue: 'searchable'

    def perform(opts={})
      @id             = opts[:id] if opts[:id]
      @klass          = opts[:klass] if opts[:klass]
      @callback       = opts[:callback] if opts[:callback]
      @call           = opts[:call]
    end

    def set_searchable
      if @id && @klass && item
        puts item.class.name
        puts item.id
        puts item.set_searchable
        puts item.searchable_index.save
      end
    end

    def set_searchable_on_callback
      if @id && @klass && @callback && item
        array = item.send(@callback)
        array = [array] unless array.respond_to?(:map)
        array.each do |record|
          self.class.perform_async(call: :set_searchable, id: record.id, klass: record.class.name)
        end
      end
    end

    def item
      @item ||= @klass.constantize.find_by(id: @id)
    end
  end
end
