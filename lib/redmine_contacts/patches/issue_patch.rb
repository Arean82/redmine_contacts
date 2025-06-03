
require_dependency 'issue'

module RedmineContacts
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          has_and_belongs_to_many :contacts, -> { distinct }
          has_one :deals_issue
          has_one :deal, through: :deals_issue
          accepts_nested_attributes_for :deals_issue, reject_if: :reject_deal, allow_destroy: true

          safe_attributes 'deals_issue_attributes',
            if: ->(issue, user) { user.allowed_to?(:edit_deals, issue.project) }
        end
      end

      class ContactsRelations < IssueRelation::Relations
        def to_s(*args)
          map(&:to_s).join(", ")
        end
      end

      class DealsRelations < IssueRelation::Relations
        def to_s(*args)
          map(&:to_s).join(", ")
        end
      end

      module InstanceMethods
        def reject_deal(attributes)
          exists = attributes['id'].present?
          empty = attributes[:deal_id].blank?
          attributes[:_destroy] = 1 if exists && empty
          !exists && empty
        end

        def related_custom_objects(klass)
          conditions = "#{CustomField.table_name}.type = 'IssueCustomField' AND #{CustomField.table_name}.field_format = '#{klass.to_s.downcase}'"
          conditions += id ? " AND #{CustomValue.table_name}.customized_id = #{id}" : " AND 1=0"
          klass.where(id: CustomValue.joins(:custom_field).where(conditions).pluck(:value).uniq)
        end

        def contacts_relations
          ContactsRelations.new(self, contacts_from_custom_and_assoc.to_a)
        end

        def deals_relations
          DealsRelations.new(self, deals_from_custom_and_assoc.to_a)
        end

        def contacts
          contacts_from_custom_and_assoc
        end

        def deals
          deals_from_custom_and_assoc
        end

        private

        def contacts_from_custom_and_assoc
          (related_custom_objects(Contact) + (super if defined?(super) && super.present?)).uniq
        end

        def deals_from_custom_and_assoc
          (related_custom_objects(Deal) + (deal ? [deal] : [])).uniq
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineContacts::Patches::IssuePatch)
  Issue.send(:include, RedmineContacts::Patches::IssuePatch)
end
