

module RedmineContacts
  module Patches
    module Compatibility
    module ActiveRecordSanitizationPatch
      def self.included(base)
        base.class_eval do
          def quote_value(value, column = nil)
            connection.quote(value, column)
          end
        end
      end
    end
  end
  end
end

unless ActiveRecord::Sanitization::ClassMethods.included_modules.include?(RedmineContacts::Patches::Compatibility::ActiveRecordSanitizationPatch)
  ActiveRecord::Sanitization::ClassMethods.send(:include, RedmineContacts::Patches::Compatibility::ActiveRecordSanitizationPatch)
end
