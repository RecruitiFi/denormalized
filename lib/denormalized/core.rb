# frozen_string_literal: true

module Denormalized
  module Core
    def self.included(base)
      base.extend ClassMethods
    end

    def contains_denormalized_attributes(attributes)
      attributes.keys.any? do |name|
        self.class.denormalized_attribute?(name)
      end
    end

    def extract_existing_denormalized_attributes(new_attributes)
      {}.tap do |extracted_attributes|
        (columns & new_attributes.keys).each do |attribute|
          extracted_attributes[attribute] = read_attribute(attribute)
        end
      end
    end

    def extract_denormalized_attributes(new_attributes)
      {}.tap do |extracted_attributes|
        (columns & new_attributes.keys).each do |attribute|
          extracted_attributes[attribute] = new_attributes[attribute]
        end
      end
    end

    def write_attribute(attr_name, value)
      if self.class.denormalized_attribute?(attr_name)
        denormalized_configuration.tables.each do |table|
          table.classify
               .constantize
               .where(attr_name => read_attribute(attr_name))
               .each { |obj| obj.write_attribute(attr_name, value) }
        end
      end

      super
    end

    def update_attribute(name, value)
      if self.class.denormalized_attribute?(attr_name)
        denormalized_configuration.tables.each do |table|
          table.classify
               .constantize
               .where(name => read_attribute(name))
               .each { |obj| obj.update_attribute(name, value) }
        end
      end

      super
    end

    def assign_attributes(new_attributes)
      if contains_denormalized_attributes(new_attributes)
        gifted_attributes = extract_denormalized_attributes(new_attributes)

        denormalized_configuration.tables.each do |table|
          table.classify
               .constantize
               .where(extract_existing_denormalized_attributes(new_attributes))
               .each { |obj| obj.assign_attributes(gifted_attributes) }
        end
      end

      super
    end

    def update_columns(attributes)
      if contains_denormalized_attributes(attributes)
        gifted_attributes = extract_denormalized_attributes(attributes)

        denormalized_configuration.tables.each do |table|
          table.classify
               .constantize
               .where(extract_existing_denormalized_attributes(attributes))
               .each { |obj| obj.update_columns(gifted_attributes) }
        end
      end

      super
    end

    module ClassMethods
      def denormalized_attribute?(name)
        name = name.to_sym if name.is_a?(String)

        if name.is_a?(Symbol)
          return denormalized_configuration.columns_hash[name]
        end

        Rails.logger.warn '[DENORMALIZED]: Syboml expected, instead received ' + name.class.to_s
        false
      end

      def update(id, attributes)
        if attributes.keys.any? { |name| denormalized_attribute?(name) }
          subjects = base_class.where(id: id) # we will let super handle errors if subject doesn't exist

          if subjects.any?
            subjects.each do |subject|
              gifted_attributes = subject.extract_denormalized_attributes(attributes)

              denormalized_configuration.tables.each do |table|
                table.classify
                     .constantize
                     .where(subject.extract_existing_denormalized_attributes(attributes))
                     .each { |obj| obj.update(gifted_attributes) }
              end
            end
          end
        end

        super
      end

      def update_all(updates)
        if updates.keys.any? { |name| denormalized_attribute?(name) }
          Rails.logger.warn '[DENORMALIZED]: Unable to update followers when using `update_all` -- orphans may have been created'
        end

        super
      end
    end
  end
end
