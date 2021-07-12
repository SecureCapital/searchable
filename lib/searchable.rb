require "searchable/version"
require "searchable/engine"
require "searchable/indexation"

module Searchable
  class << self
    def config
      @config ||= OpenStruct.new(
        searchable_data_types: %i(string text), # Columns to search in field_scope
        latency: 1, # Seconds to wait before calling indexation
        callback_latency: 0.1, # Seconds to wait on each callback (incrementing)
        collate_function: "UTF8MB4_GENERAL_CI",
        locale: :en, # Used in returning right fill words
        fill_words_en: %w(a and any are as at be by can can't cant for from hers
          his if in is its may not of often on one or such tehir the then there
          these this those thus to two which whose ie eg i.e. e.g. it's),
        fill_words_da: %w(er i hvor der den det deres hendes hans hende ham hun
          hvor hvorfor derfor hvorledes herfor således og samt dels mit min dit
          dem hvormed har på ved også til her at en et han ikke over disse blot
          de fordi af ad noget nogle kan vil ville have men da som idet fx feks
          dens dets mens medens side siges alle ifølge være var under over sine
          mod nok set jeg mig sig fik får få samme for vi nu ind man skal fra
          kunne med enten før ud)
      )
    end

    def configure(&block)
      yield config if block_given?
      config.to_h.keys.each do |key|
        self.class.define_method(key){config[key]} unless respond_to?(key)
      end
    end

    def fill_words
      meth = "fill_words_#{config.locale}"
      @config.respond_to?(meth) ? @config.send(meth) : @config.fill_words_en
    end
  end

  configure
end
