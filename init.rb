#$LOAD_PATH.unshift File.expand_path('lib', __dir__)

# Check for required gems versions with clearer error handling:
begin
  requires_redmine_crm version_or_higher: '0.0.51'
rescue StandardError
  raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"
end

begin
  requires_redmineup version_or_higher: '1.0.10'
rescue StandardError
  raise "\n\033[31mRedmine requires newer redmineup gem version.\nPlease update with 'bundle update redmineup'.\033[0m"
end

require 'redmine'
require_relative 'lib/csv_importable'
require_relative 'lib/redmine_contacts/acts/priceable'

ActiveRecord::Base.include(RedmineContacts::Acts::Priceable)

CONTACTS_VERSION_NUMBER = '4.2.6'.freeze
CONTACTS_VERSION_TYPE = 'PRO version'.freeze

if ActiveRecord::VERSION::MAJOR >= 4
  require 'csv'
  FCSV = CSV
end

Redmine::Plugin.register :redmine_contacts do
  name "Redmine CRM plugin (#{CONTACTS_VERSION_TYPE})"
  author 'RedmineUP'
  description 'This is a CRM plugin for Redmine that can be used to track contacts and deals information'
  version CONTACTS_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/plugins/crm'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '4.0'

  settings default: {
    name_format: :lastname_firstname.to_s,
    auto_thumbnails: true,
    major_currencies: 'USD, EUR, GBP, RUB, CHF',
    contact_list_default_columns: %w[first_name last_name],
    max_thumbnail_file_size: 300
  }, partial: 'settings/contacts/contacts'

  project_module :deals do
    permission :delete_deals, deals: [:destroy, :bulk_destroy]
    permission :view_deals,
               {
                 deals: [:index, :show, :context_menu],
                 notes: [:show],
                 deal_categories: [:index]
               }, read: true
    permission :edit_deals,
               {
                 deals: [:edit, :update, :add_attachment, :bulk_update, :bulk_edit, :update_form],
                 deal_contacts: [:search, :autocomplete, :add, :delete],
                 notes: [:create, :destroy, :update]
               }
    permission :add_deals, deals: [:new, :create, :update_form]
    permission :manage_deals,
               {
                 deal_categories: [:new, :edit, :destroy, :update, :create],
                 deal_statuses: [:assign_to_project]
               }, require: :member
    permission :delete_deal_watchers, watchers: :destroy
    permission :import_deals, deal_imports: [:new, :create, :show, :settings, :mapping, :run]
  end

  project_module :contacts do
    permission :view_contacts, {
      contacts: [:show, :index, :live_search, :contacts_notes, :context_menu],
      notes: [:show]
    }, read: true
    permission :view_private_contacts, {
      contacts: [:show, :index, :live_search, :contacts_notes, :context_menu],
      notes: [:show]
    }, read: true

    permission :add_contacts, {
      contacts: [:new, :create],
      contacts_duplicates: [:index, :duplicates],
      contacts_vcf: [:load]
    }

    permission :edit_contacts, {
      contacts: [:edit, :update, :bulk_update, :bulk_edit],
      notes: [:create, :destroy, :edit, :update],
      contacts_duplicates: [:index, :merge, :duplicates],
      contacts_projects: [:new, :destroy, :create],
      contacts_vcf: [:load]
    }

    permission :manage_contact_issue_relations, {
		contacts_issues: [:new, :create_issue, :create, :delete, :close, :autocomplete_for_contact]
    }

    permission :delete_contacts, contacts: [:destroy, :bulk_destroy]
    permission :add_notes, notes: [:create]
    permission :delete_notes, notes: [:destroy, :edit, :update]
    permission :delete_own_notes, notes: [:destroy, :edit, :update]

    permission :manage_contacts, {
      projects: :settings,
      contacts_settings: :save,
    }

    permission :manage_public_contacts_queries, {}, require: :member
    permission :save_contacts_queries, {}, require: :loggedin
    permission :manage_public_deals_queries, {}, require: :member
    permission :save_deals_queries, {}, require: :loggedin
  end

  menu :project_menu, :contacts, {controller: 'contacts', action: 'index'}, caption: :contacts_title, param: :project_id
  menu :project_menu, :new_contact, {controller: 'contacts', action: 'new'}, caption: :label_crm_contact_new, param: :project_id, parent: :new_object

  menu :top_menu, :contacts,
       {controller: 'contacts', action: 'index', project_id: nil},
       caption: :label_contact_plural,
       if: Proc.new {
         User.current.allowed_to?({controller: 'contacts', action: 'index'},
                                          nil, {global: true})  && ContactsSetting.contacts_show_in_top_menu?
       }

  menu :application_menu, :contacts,
       {controller: 'contacts', action: 'index'},
       caption: :label_contact_plural,
       if: Proc.new{
         User.current.allowed_to?({controller: 'contacts', action: 'index'},
                                          nil, {global: true})  && ContactsSetting.contacts_show_in_app_menu? }
       #}

  menu :top_menu, :deals,
       {controller: 'deals', action: 'index', project_id: nil},
       caption: :label_deal_plural,
       if: proc {
         User.current.allowed_to?({controller: 'deals', action: 'index'}, nil, global: true) && ContactsSetting.deals_show_in_top_menu?
       }

  menu :application_menu, :deals,
       {controller: 'deals', action: 'index'},
       caption: :label_deal_plural,
       if: proc {
         User.current.allowed_to?({controller: 'deals', action: 'index'}, nil, global: true) && ContactsSetting.deals_show_in_app_menu?
       }

  menu :project_menu, :deals, {controller: 'deals', action: 'index'}, caption: :label_deal_plural, param: :project_id
  menu :project_menu, :new_deal, {controller: 'deals', action: 'new'}, caption: :label_crm_deal_new, param: :project_id, parent: :new_object

#  menu :admin_menu, :contacts, {controller: 'settings', action: 'plugin', id: 'redmine_contacts'}, caption: :contacts_title, html: {class: 'icon'}
  menu :admin_menu, :contacts, {controller: 'settings', action: 'plugin', id: "redmine_contacts"}, caption: :contacts_title, html: {class: 'icon'}, icon: 'vcard', plugin: :redmine_contacts

  activity_provider :contacts, default: false, class_name: ['ContactNote', 'Contact']
  activity_provider :deals, default: false, class_name: ['DealNote', 'Deal']

  Redmine::Search.map do |search|
    search.register :contacts
    search.register :deals
  end
end

require File.dirname(__FILE__) + '/lib/redmine_contacts
#require 'redmine_contacts'

Redmineup::Settings.initialize_gem_settings
Redmineup::Currency.add_admin_money_menu
#RedmineCrm::Settings.initialize_gem_settings
#RedmineCrm::Currency.add_admin_money_menu
