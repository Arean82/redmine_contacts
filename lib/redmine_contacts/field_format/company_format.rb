
module RedmineContacts
  module FieldFormat
    class CompanyFormat < ContactFormat
      add 'company'

      def label
        'label_crm_company'
      end

      def target_class
        @target_class ||= Contact
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        options[:is_company] = true
        super
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        options[:is_company] = true
        super
      end

      def set_custom_field_value(custom_field, custom_field_value, value)
        value = value.flatten.reject(&:blank?) if value.is_a?(Array)
        super(custom_field, custom_field_value, value)
      end
    end
  end
end
