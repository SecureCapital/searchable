## Module to include or extend on ActiveRecord models
# Class methods provides:
#   search: For searching columns with COLLATE
#   index_as_searchable: creating realtion to searchable_indices and persist searchable string
# Searches are conducted by SQL: COLLATE UTF8_GENERAL_CI LIKE '%#{value}%'.
# Instance methods should only be included if th class calls index_as_searchable.
# The insance methods gives methods to save and generate searchable text. The
# user should override generate_searchable, and on index_as_searchable provide
# metadata on the generator and configure behaviour of the class.

module Searchable
  module Indexation
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    def searchable
      return attributes['searchable'] if attributes['searchable']
      si = searchable_index || build_searchable_index
      set_searchable unless si.searchable
      si.searchable
    end

    # Override setserachable to reduce or increase the compression. If
    # generate_searchable contains HTML override with compres: true option
    def set_searchable
      (searchable_index||build_searchable_index).set_searchable_with(
        generate_searchable,
        **self.class.searchable_strippers.map{|key| [key,true]}.to_h
      )
    end

    # Do override this function with custom string generation, but ensure to
    # map it to the searchable_watch_fields
    def generate_searchable
      self.class.searchable_columns.map{|field| send(field)}.comapct.map(&:to_s)
    end

    def save_searchable
      if searchable_should_change?
        send "save_searchable_#{self.class.searchable_save_async? ? 'async' : 'sync'}"
      else
        false
      end
    end

    def save_searchable_sync
      set_searchable
      searchable_index.save
      save_searchable_callbacks_sync
      true
    end

    def save_searchable_callbacks
      send "save_searchable_callbacks_#{self.class.searchable_save_async? ? 'async' : 'sync'}"
    end

    def save_searchable_callbacks_sync
      searchable_callbacks.each do |rec|
        rec.set_searchable
        rec.searchable_index.save
      end
    end

    def searchable_callbacks
      items = self.class.searchable_callbacks.map{|meth| send(meth)}
      items.map{|item| item.respond_to?(:to_a) ? item.to_a : item}.flatten.compact.uniq
    end

    def save_searchable_async
      Searchable::IndexWorker.perform_in(
        Searchable.latency.seconds,
        id: id,
        klass: self.class.name,
        call: "set_searchable"
      )
      self.class.searchable_callbacks.each_with_index do |meth, index|
        delay = Searchable.latency + index * Searchable.callback_latency
        Searchable::IndexWorker.perform_in(
          delay.seconds,
          id: id,
          klass: self.class.name,
          callback: meth,
          call: "set_searchable_on_callback"
        )
      end
      true
    end

    def save_searchable_callbacks_async
      searchable_callbacks.each do |record|
        Searchable::IndexWorker.perform_in(
          Searchable.latency.seconds,
          id: record.id,
          klass: item.class.name,
          call: "set_searchable"
        )
      end
    end

    ## Check for data change before updating searchable
    # We do not care for changes on related data as these should implement
    # a callback saving this record.

    def searchable_should_change?
      return true if new_record? || (searchable_index || build_searchable_index).new_record?
      # Change on attributes affecting result?
      attrs = self.class.searchable_watch_fields.select do |field|
        respond_to?(field)&&respond_to?("saved_change_to_#{field}?")
      end
      attrs.any?{|field| send("saved_change_to_#{field}?")}
    end

    module ClassMethods
      attr_writer :searchable_touch_on_indexation, :searchable_indexed,
        :searchable_watch_fields, :searchable_callbacks, :searchable_save_async,
        :searchable_indexation_inclusions, :searchable_strippers

      def searchable_touch_on_indexation?
        return false if @searchable_touch_on_indexation==false
        @searchable_touch_on_indexation||true
      end

      def searchable_indexed?
        @searchable_indexed||false
      end

      def searchable_watch_fields
        @searchable_watch_fields||[]
      end

      def searchable_callbacks
        @searchable_callbacks||[]
      end

      def searchable_save_async?
        return false if @searchable_save_async==false
        @searchable_save_async||true
      end

      def searchable_indexation_inclusions
        @searchable_indexation_inclusions
      end

      def searchable_strippers
        @searchable_strippers||Searchable.default_strippers
      end

      def index_as_searchable(
        watch_fields: [],
        save_async: true,
        touch_on_indexation: true,
        callbacks: [],
        indexation_inclusions: nil,
        strippers: nil)
        @searchable_indexed = true
        @searchable_callbacks = callbacks
        @searchable_watch_fields = watch_fields
        @searchable_save_async = save_async
        @searchable_touch_on_indexation = touch_on_indexation
        @searchable_indexation_inclusions = indexation_inclusions
        @searchable_strippers = strippers
        Searchable::Index.indexed_models << self
        has_one :searchable_index, as: :owner, :dependent => :delete, class_name: 'Searchable::Index'
        after_save :save_searchable
        after_destroy :save_searchable_callbacks
      end

      def index_all_searchable(of: 50)
        if searchable_indexed?
          includers = [:searchable_index]+(searchable_indexation_inclusions||searchable_callbacks)
          includes(*includers).in_batches(of: of).each do |batch|
            batch.each do |record|
              record.set_searchable
              record.searchable_index.save
            end
          end
        end
      end

      def searchable_columns
        columns_hash.select{|k,v| Searchable.searchable_data_types.include? v.type}.map(&:first)
      end

      def searchable_field_scope(*fields, column_name: '`searchable`')
        flds = fields.map{|field| field.to_s}.join(', ')
        flds = "`#{table_name}`.*" if flds.blank?
        searchable = searchable_columns.map do |field|
          "IFNULL(`#{field}`,' ')"
        end.join(", ' ', ")
        select("#{flds}, CONCAT(#{searchable}) as #{column_name}")
      end

      def join_searchable_index
        table_type = if column_names.include?('type')
          "`#{table_name}`.`type`"
        else
          "'#{name}'"
        end
        joins("LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `#{table_name}`.`id` AND `searchable_indices`.`owner_type` = #{table_type}")
      end

      def with_searchable
        select("`#{table_name}`.*", '`searchable_indices`.`searchable` as `searchable`').join_searchable_index
      end

      ## Serach by columns with collate
      # Give argument join: {'OR'/'AND'} if strings shuold match in either or
      # all columns. Place wildcards % in the string, before or/and after.
      # Or just  use the fuzzy oprion to place wilcards all around

      def search(join: 'OR', with_having: false, fuzzy: true, **args)
        args = args.select{|k,v| v&&v.is_a?(String)&&!v.blank? }
        args = args.map do |k,v|
          mod = v.strip.gsub(/\s+/,' ')
          mod = '%'+mod.split(' ').join('%')+'%' if fuzzy
          [k,mod]
        end

        if args.empty?
          all
        else
          q = args.map do |field, argument|
            "(#{field} COLLATE #{Searchable.collate_function} LIKE '#{argument}')"
          end.join(" #{join} ")
          if with_having
            having(q)
          else
            where(q)
          end
        end
      end
    end
  end
end
