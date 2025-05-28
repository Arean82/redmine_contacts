# plugins/redmine_contacts/lib/redmine_contacts/patches/compatibility/active_record_base_patch.rb

module RedmineContacts
  module Compatibility
    module ActiveRecordBasePatch
      def self.included(base)
        base.class_eval do
          # Define a new has_many method that wraps the original one
          class << self
            alias_method :has_many_without_contacts, :has_many

            def has_many_with_contacts(name, scope = nil, **options, &extension)
              # If scope is a Hash (like :through => :memberships), don't call `arity` on it directly
              if scope.respond_to?(:arity)
                if scope.arity == 0
                  has_many_without_contacts(name, scope.call, **options, &extension)
                else
                  has_many_without_contacts(name, scope, **options, &extension)
                end
              else
                has_many_without_contacts(name, scope, **options, &extension)
              end
            end

            # Override has_many to use our custom method
            alias_method :has_many, :has_many_with_contacts
          end
        end
      end
    end
  end
end
