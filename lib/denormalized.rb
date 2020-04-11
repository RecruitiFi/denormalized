# frozen_string_literal: true

require 'active_record'
require 'denormalized/core'

module Denormalized
  def denormalized?
    included_modules.include?(Denormalized::Core)
  end

  def denormalized(*attributes)
    options = attributes.extract_options!.dup

    if attributes.empty?
      raise ArgumentError, 'You need to supply at least one column'
    end
    if options.empty? || options[:tables]&.empty?
      raise ArgumentError, 'You need to supply at least one table'
    end

    class_attribute :denormalized_configuration

    self.denormalized_configuration = {
      columns: attributes,
      tables: options[:tables],
      columns_hash: Hash[attributes.map { |column| [column, true] }]
    }

    include Denormalized::Core unless denormalized?
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.extend Denormalized
