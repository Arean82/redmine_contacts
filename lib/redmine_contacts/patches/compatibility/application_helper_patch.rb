

module RedmineContacts
  module Patches
    module Compatibility
    module ApplicationHelperPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          def stocked_reorder_link(object, name = nil, url = {}, method = :post)
            Redmine::VERSION.to_s > '3.3' ? reorder_handle(object, :param => name) : reorder_links(name, url, method)
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
