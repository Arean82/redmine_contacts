
module RedmineContacts
  module Utils
    module CsvUtils
      include Redmine::I18n

      class << self
        def csv_custom_value(custom_value)
          return '' unless custom_value
          value = custom_value.value
          case custom_value.custom_field.field_format
          when 'date'
            begin; format_date(value.to_date); rescue; value end
          when 'bool'
            l(value == "1" ? :general_text_Yes : :general_text_No)
          when 'float'
            sprintf('%.2f', value).gsub('.', l(:general_csv_decimal_separator))
          when 'contact', 'company'
            Contact.where(id: value).first.to_s
          else
            if value.is_a?(Array)
              value.map(&:to_s).join(', ')
            else
              value.to_s
            end
          end
        rescue
          ''
        end
      end
    end
  end
end
