module RedmineContacts
  module Acts
    module Priceable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_priceable(*args)
          priceable_options = args
          priceable_options << :price if priceable_options.empty?

          priceable_methods = priceable_options.map do |attr|
            %(
              def #{attr}_to_s
                object_price(
                  self, 
                  :#{attr},
                  { 
                    :decimal_mark => ContactsSetting.decimal_separator,
                    :thousands_separator => ContactsSetting.thousands_delimiter
                  }
                ) if respond_to?(:#{attr})
              end
            )
          end.join("\n")

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            include RedmineCrm::MoneyHelper
            include RedmineContacts::Acts::Priceable::InstanceMethods

            #{priceable_methods}
          RUBY
        end
      end

      module InstanceMethods
        # No need to include anything here for now
      end
    end
  end
end
