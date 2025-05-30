

require "redmine_contacts/liquid/drops/contacts_drop"
require "redmine_contacts/liquid/drops/deals_drop"
require "redmine_contacts/liquid/drops/notes_drop"
require "redmine_contacts/liquid/drops/addresses_drop"

module RedmineContacts
  module Liquid
  module Liquid
    module Filters
      include RedmineCrm::MoneyHelper

      def underscore(input)
        input.to_s.gsub(' ', '_').gsub('/', '_').underscore
      end

      def dasherize(input)
        input.to_s.gsub(' ', '-').gsub('/', '-').dasherize
      end

      def encode(input)
        Rack::Utils.escape(input)
      end

      # alias newline_to_br
      def multi_line(input)
        input.to_s.gsub("\n", '<br/>').html_safe
      end

      def concat(input, *args)
        result = input.to_s
        args.flatten.each { |a| result << a.to_s }
        result
      end

      # right justify and padd a string
      def rjust(input, integer, padstr = '')
        input.to_s.rjust(integer, padstr)
      end

      # left justify and padd a string
      def ljust(input, integer, padstr = '')
        input.to_s.ljust(integer, padstr)
      end

      def textile(input)
        ::RedCloth3.new(input).to_html
      end

      def currency(input, currency_code=nil)
        price_to_currency(input, currency_code || container_currency, :converted => false)
      end

      def custom_field(input, field_name)
        if input.respond_to?(:custom_field_values)
          input.custom_field_values.detect{|cfv| cfv.custom_field.name == field_name}.try(:value)
        end
      end

      def attachment(input, file_name)
        if input.respond_to?(:attachments)
          input.attachments.detect{|a| a.file_name == file_name}.try(:diskfile)
        end
      end

    private
      def container
        @container ||= @context.registers[:container]
      end

      def container_currency
        container.currency if container.respond_to?(:currency)
      end

    end

    ::Liquid::Template.register_filter(RedmineContacts::Liquid::Liquid::Filters)

  end
  end
end
