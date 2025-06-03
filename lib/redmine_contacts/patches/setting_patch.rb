
module RedmineContacts
  module Patches
    module SettingPatch
      def self.included(base)
        base.extend(ClassMethods)
        # base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          # Setting.available_settings["disable_taxes"] = {'default' => 0}
          # @@available_settings["disable_taxes"] = {}

        end
      end

      module ClassMethods

        # Setting.available_settings["disable_taxes"] = {}

        # def disable_taxes?
        #   self[:disable_taxes].to_i > 0
        # end

        # def disable_taxes=(value)
        #   self[:disable_taxes] = value
        # end

        %w(disable_taxes default_tax tax_type default_currency money_thousands_delimiter money_decimal_separator).each do |name|
          src = <<-END_SRC
          Setting.available_settings["#{name}"] = ""

          def #{name}
            self[:#{name}]
          end

          def #{name}?
            self[:#{name}].to_i > 0
          end

          def #{name}=(value)
            self[:#{name}] = value
          end
          END_SRC
          class_eval src, __FILE__, __LINE__
        end

      end
    end
  end
end

unless Setting.included_modules.include?(RedmineContacts::Patches::SettingPatch)
  Setting.send(:include, RedmineContacts::Patches::SettingPatch)
end
