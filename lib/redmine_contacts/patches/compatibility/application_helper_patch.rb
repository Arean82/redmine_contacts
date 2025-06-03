
require_dependency 'application_helper'

module RedmineContacts
  module Patches
    module Compatibility
      module ApplicationHelperPatch
        def self.included(base) # :nodoc:
          base.send(:include, InstanceMethods)

          base.class_eval do
            unloadable

            def stocked_reorder_link(object, name = nil, url = {}, method = :post)
              Redmine::VERSION.to_s > '3.3' ? reorder_handle(object, :param => name) : reorder_links(name, url, method)
            end

            alias_method :format_object_without_contact, :format_object
            alias_method :format_object, :format_object_with_contact
          end
        end

        module InstanceMethods
          def format_object_with_contact(object, html = true, &block)
            case object.class.name
            when 'CustomFieldValue', 'CustomValue'
              html = html[:html] if html.is_a?(Hash)

              case object.custom_field.field_format
              when 'deal'
                Deal.where(id: object.value).map do |deal|
                  html ? link_to(deal.name, deal_path(deal)) : deal.to_s
                end.join(', ').html_safe
              when 'contact', 'company'
                Contact.where(id: object.value).map do |contact|
                  html ? contact_tag(contact) : contact.to_s
                end.join(', ').html_safe
              else
                format_object_without_contact(object, html, &block)
              end
            else
              format_object_without_contact(object, html, &block)
            end
          end
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineContacts::Patches::Compatibility::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineContacts::Patches::Compatibility::ApplicationHelperPatch)
end
