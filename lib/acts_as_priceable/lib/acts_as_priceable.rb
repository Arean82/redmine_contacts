

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
          priceable_methods = ""
          priceable_options.each do |priceable_attr|
            priceable_methods << %(
              def #{priceable_attr.to_s}_to_s
                object_price(
                  self, 
                  :#{priceable_attr},
                  { 
                    :decimal_mark => ContactsSetting.decimal_separator,
                    :thousands_separator => ContactsSetting.thousands_delimiter
                  }
                ) if self.respond_to?(:#{priceable_attr})
              end
            )
          end

          class_eval <<-EOV
            include RedmineCrm::MoneyHelper
            include RedmineContacts::Acts::Priceable::InstanceMethods

            #{priceable_methods}
          EOV

        end
      end

      module InstanceMethods
#        def self.included(base)
#          base.extend ClassMethods
#        end

      end

    end
  end
end
