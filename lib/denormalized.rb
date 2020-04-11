require "denormalized/core"

module Denormalized
  def denormalized?
    included_modules.include?(Denormalized::Core)
  end

  def denormalized(*attributes)
    options = attributes.extract_options!.dup

    raise ArgumentError, "You need to supply at least one column" if attributes.empty?
    raise ArgumentError, "You need to supply at least one table" if options.empty? || options[:tables]&.empty?

    class_attribute :denormalized_configuration

    self.denormalized_configuration = {
      columns: attributes,
      tables: options[:tables],
      columns_hash: Hash[attributes.map { |column| [column, true] }]
    }

    include Denormalized::Core unless denormalized?
  end
end
