require_dependency 'auto_completes_controller'

module RedmineContacts
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          include ActionView::Helpers::AssetTagHelper
          include ActionView::Helpers::SanitizeHelper
          include ApplicationHelper
          include Helper::CrmCalendarHelper
          include ERB::Util
        end
      end

      module InstanceMethods
        DEFAULT_LIMIT = 10
        DEFAULT_CONTACTS_LIMIT = 30

        def deals
          @deals = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Deal.visible
          scope = scope.by_project(@project) if @project

          if q.match(/\A#?(\d+)\z/)
            @deals << scope.find_by_id($1.to_i)
          end

          if q.present?
            deal = scope.find_by_name(q)
            @deals << deal if deal.present?

            deals_by_name = scope
            q.split(' ').each { |word| deals_by_name = deals_by_name.live_search(word) }
            @deals += deals_by_name.order("#{Deal.table_name}.name")

            scope = scope.live_search_with_contact(q)
          end

          @deals += scope.order("#{Deal.table_name}.name")
          @deals.uniq! { |deal| deal.id }
          @deals = @deals.take(params[:limit].to_i > 0 ? params[:limit].to_i : DEFAULT_LIMIT)

          render partial: 'deals', layout: false
        end

        def contact_tags
          @name = params[:q].to_s
          @tags = Contact.available_tags(name_like: @name, limit: DEFAULT_LIMIT)
          render json: format_crm_tags_json(@tags)
        end

        def taggable_tags
          klass = Object.const_get(params[:taggable_type].camelcase)
          @name = params[:q].to_s
          @tags = klass.all_tag_counts(conditions: ["#{Redmineup::Tag.table_name}.name LIKE ?", "%#{@name}%"], limit: 10)
          render json: format_crm_tags_json(@tags)
        end

        def contacts
          @contacts = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Contact.includes(:avatar).where({})
          scope = scope.limit(params[:limit] || DEFAULT_CONTACTS_LIMIT)
          scope = scope.companies if params[:is_company]
          scope = scope.joins(:projects).where(Contact.visible_condition(User.current))
          scope = Rails.version >= '5.1' ? scope.distinct : scope.uniq

          unless q.blank?
            q.split(' ').each do |search_string|
              scope = scope.live_search(search_string.gsub(/[\(\)]/, ''))
            end
          end

          scope = scope.by_project(@project) if @project
          @contacts = scope.to_a.sort_by(&:name)

          render json: params[:multiaddress] ? format_multiaddress_contacts_json(@contacts) : format_contacts_json(@contacts)
        end

        def companies
          @companies = []
          q = (params[:q] || params[:term]).to_s.strip
          if q.present?
            scope = Contact.joins(:projects).includes(:avatar).limit(params[:limit] || DEFAULT_CONTACTS_LIMIT)
            scope = scope.by_project(@project) if @project
            scope = scope.where('LOWER(first_name) LIKE LOWER(?)', "%#{q}%") unless q.blank?
            @companies = scope.visible.companies.order("#{Contact.table_name}.first_name")
          end

          render json: format_companies_json(@companies)
        end

        private

        def format_crm_tags_json(tags)
          tags.map { |tag|
            {
              id: tag.name,
              text: tag.name
            }
          }
        end

        def format_contacts_json(contacts)
          contacts.map do |contact|
            {
              id: contact.id,
              text: contact.name_with_company,
              name: contact.name,
              avatar: avatar_to(contact, size: 16),
              company: contact.is_company ? '' : contact.company,
              email: contact.primary_email,
              value: contact.id
            }
          end
        end

        def format_multiaddress_contacts_json(contacts)
          contacts.flat_map do |contact|
            (contact.emails.presence || [' ']).map do |email|
              {
                id: email.blank? ? contact.id : email,
                text: contact.name_with_company,
                name: contact.name,
                avatar: avatar_to(contact, size: 32, class: 'select2-contact__avatar'),
                company: contact.is_company ? '' : contact.company,
                email: email,
                value: contact.id
              }
            end
          end
        end

        def format_companies_json(companies)
          companies.map do |company|
            {
              id: company.id,
              name: company.name,
              avatar: avatar_to(company, size: 16),
              email: company.primary_email,
              label: company.name,
              value: company.name
            }
          end
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineContacts::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineContacts::Patches::AutoCompletesControllerPatch)
end
