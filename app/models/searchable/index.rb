module Searchable
  class Index < ApplicationRecord
    extend Searchable::Indexation::ClassMethods
    @@indexed_models = []
    belongs_to :owner, :polymorphic => true
    validates :owner_id, :owner_type, presence: true, allow_nil: false, allow_blank: false
    validates :owner_id, uniqueness: { scope: :owner_type }, :on => :create
    # Only validate uniqueness on create, change can violate the uniqueness but
    # a violation is not allowed to be commited to the database. This saves
    # time on update. SI shpould be maintained rom the model, thus the change of
    # owner os unlikely.
    validates :searchable, presence: true, allow_blank: false
    before_save :limit_searchable
    after_save :touch_owner

    def set_searchable_with(search_string, **kwargs, &block)
      if search_string.is_a? Array
        self.searchable_array = search_string
      else
        self.searchable = search_string
      end
      kwargs.each do |key,bool|
        send(key) if bool && respond_to?(key)
      end
      strippers.each{|meth| send(meth)} if kwargs[:compress]
      self[:searchable] = yield self[:searchable] if block_given?
      return self[:searchable]
    end

    def searchable=(string)
      self[:searchable] = string.to_s.strip.gsub(/\s+/,' ')
    end

    def searchable_array
      searchable.split(/\s+/)
    end

    def searchable_array=(array)
      self.searchable = array.flatten.compact.join(' ')
    end

    ## STRIPPERS / COMPRESSORS ##
    def strippers
      methods.select{|meth| meth=~/^strip_\w+$/}
    end

    def strip_downcase
      self[:searchable] = searchable.downcase
    end

    def strip_html
      self[:searchable] = ActionController::Base.helpers.strip_tags(searchable)
    end

    def strip_numbers
      self.searchable_array = searchable_array.select{|w| !(w=~/^\-?\+?\d+\.?\,?\d*%?$/)}
    end

    def strip_non_word_boundary
      self.searchable_array = searchable_array.select{|word| word=~/\w/}
    end

    def strip_special_characters
      replacors = %q{`":;!#€<>§/}
      replacors_with_escape = %q{*^|[]()\{\}+?\\}
      replacors.split('').each do |sign|
        self[:searchable].gsub!(/#{sign}/, '')
      end
      replacors_with_escape.split('').each do |sign|
        str = '\\'+sign
        self[:searchable].gsub!(/#{str}/, '')
      end
    end

    def strip_fill_words
      self.searchable_array = searchable_array - Searchable.fill_words
    end

    def strip_duplicates
      self.searchable_array = searchable_array.uniq
    end
    ##

    def touch_owner
      if saved_changes? && owner.class.searchable_touch_on_indexation?
        owner.update_column(:updated_at, updated_at)
      end
    end

    def limit_searchable
      limit = self.class.columns_hash.find{|field,addapter| field=='searchable'}.last.limit
      self[:searchable]=self[:searchable][0..(limit-1)]
    end

    class << self
      def indexed_models
        @@indexed_models
      end
    end
  end
end
