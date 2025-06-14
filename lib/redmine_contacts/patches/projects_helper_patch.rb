# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2025 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'queries_helper'

module RedmineContacts
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :project_settings_tabs_without_contacts, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_contacts
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_contacts
          tabs = project_settings_tabs_without_contacts

          tabs.push(:name => 'contacts',
                    :action => :manage_contacts,
                    :partial => 'projects/contacts_settings',
                    :label => :label_contact_plural) if User.current.allowed_to?(:manage_contacts, @project)
          tabs.push(:name => 'deals',
                    :action => :manage_deals,
                    :partial => 'projects/deals_settings',
                    :label => :label_deal_plural) if User.current.allowed_to?(:manage_deals, @project)
          tabs
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineContacts::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineContacts::Patches::ProjectsHelperPatch)
end
