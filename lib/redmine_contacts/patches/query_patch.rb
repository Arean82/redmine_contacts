
require_dependency 'query'

module RedmineContacts
  module Patches
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          if instance_methods.include?(:add_filter) && !method_defined?(:add_filter_with_contacts)
            alias_method :add_filter_without_contacts, :add_filter
            alias_method :add_filter, :add_filter_with_contacts
          end

          if instance_methods.include?(:add_available_filter) && !method_defined?(:add_available_filter_with_contacts)
            alias_method :add_available_filter_without_contacts, :add_available_filter
            alias_method :add_available_filter, :add_available_filter_with_contacts
          end
        end
      end

      module InstanceMethods
        def add_available_filter_with_contacts(field, options)
          add_available_filter_without_contacts(field, options)
          return @available_filters unless filters[field]

          values = filters[field][:values] || []
          initialize_values_for_select2(field, values)
          @available_filters
        end

        def add_filter_with_contacts(field, operator, values = nil)
          add_filter_without_contacts(field, operator, values)
          return unless available_filters[field]
          initialize_values_for_select2(field, values)
          true
        end

        def initialize_values_for_select2(field, values)
          return unless @available_filters[field]

          case @available_filters[field][:type]
          when :contact, :company
            @available_filters[field][:values] = ids_to_names_with_ids(values, Contact)
          when :deal
            @available_filters[field][:values] = ids_to_names_with_ids(values, Deal)
          end
        end

        def ids_to_names_with_ids(ids, model)
          ids.blank? ? [] : model.visible.where(:id => ids).map { |r| [r.name, r.id.to_s] }
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::QueryPatch)
end
