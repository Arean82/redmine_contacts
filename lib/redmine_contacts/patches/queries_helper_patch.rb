
require_dependency 'queries_helper'

module RedmineContacts
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :column_value_without_contacts, :column_value
          alias_method :column_value, :column_value_with_contacts
        end
      end

      module InstanceMethods
        def column_value_with_contacts(column, list_object, value)
          if column.name == :id && list_object.is_a?(Contact)
            link_to(value, contact_path(list_object))
          elsif column.name == :id && list_object.is_a?(Deal)
            link_to(value, deal_path(list_object))
          elsif column.name == :name && list_object.is_a?(Contact)
            contact_tag(list_object)
          elsif column.name == :name && list_object.is_a?(Deal)
            link_to(list_object.name, deal_path(list_object))
          elsif column.name == :price && list_object.is_a?(Deal)
            list_object.price_to_s
          elsif column.name == :expected_revenue && list_object.is_a?(Deal)
            list_object.expected_revenue_to_s
          elsif column.name == :probability && !value.blank? && list_object.is_a?(Deal)
            "#{value.to_i}%"
          elsif value.is_a?(Deal)
            deal_tag(value, no_contact: true, plain: true)
          elsif value.is_a?(Contact)
            contact_tag(value)
          elsif column.name == :contacts_relations
            Array(value).map { |contact| contact_tag(contact) }.join(', ').html_safe
          elsif column.name == :tags && list_object.is_a?(Contact)
            Array(value).map(&:name).join(', ')
          else
            column_value_without_contacts(column, list_object, value)
          end
        end
      end
    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineContacts::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineContacts::Patches::QueriesHelperPatch)
end
