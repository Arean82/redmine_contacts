
module RedmineContacts
  module FieldFormat
    class ContactFormat < Redmine::FieldFormat::RecordList
      add 'contact'
      self.customized_class_names = nil
#      self.multiple_supported = false
      self.multiple_supported = true

#      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
#        contact = Contact.where(id: custom_value.value).first unless custom_value.value.blank?
#        view.select_contact_tag(tag_name, contact, options.merge(id: tag_id,
#                                                                 add_contact: true,
#                                                                 include_blank: !custom_value.custom_field.is_required))
#      end  
	  
	  def edit_tag(view, tag_id, tag_name, custom_value, options = {})
	  # If multiple_supported, delegate to render_contacts_tag which handles multi-select rendering
	  if self.multiple_supported
		  view.render_contacts_tag(
		  tag_id,
		  tag_name,
		  custom_value.custom_field,
		  custom_value.value,
		  options
		  )
	  else
		  # Single value support: find the contact only if value present and not blank
		  contact = if custom_value.value.present?
					  Contact.find_by(id: custom_value.value)
				  end
	  
		  # Render single-select contact tag with proper options
		  view.select_contact_tag(
		  tag_name,
		  contact,
		  options.merge(
			  id: tag_id,
			  add_contact: true,
			  include_blank: !custom_value.custom_field.is_required
		  )
		  )
	  end
	  end
																
      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        render_contacts_tag(view, tag_id, tag_name, custom_field, value, options.merge(skip_add: true)) +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
      end

      def query_filter_options(custom_field, query)
        super.merge(type: name.to_sym)
      end

      def validate_custom_value(_custom_value)
        []
      end

      def set_custom_field_value(custom_field, custom_field_value, value)
        value = value.flatten.reject(&:blank?) if value.is_a?(Array)
        super(custom_field, custom_field_value, value)
      end

      private

      def render_contacts_tag(view, tag_id, tag_name, custom_field, value, options={})
        contacts = Contact.where(id: value).to_a unless value.blank?
        view.select_contact_tag(tag_name, contacts || [], options.merge(id: tag_id,
                                                                        add_contact: !options[:skip_add],
                                                                        class: "contact_cf #{custom_field.multiple ? 'select2_multi_cf' : ''}",
                                                                        include_blank: !custom_field.is_required,
                                                                        multiple: custom_field.multiple))
      end
    end
  end
end
