

module RedmineContacts
  module Patches
    module Compatibility
      module V23
        module QueryPatch
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
              unloadable
              class << self
                VISIBILITY_PRIVATE = 0
                VISIBILITY_ROLES   = 1
                VISIBILITY_PUBLIC  = 2
              end
            end
          end
        end

        module InstanceMethods
          VISIBILITY_PRIVATE = 0
          VISIBILITY_ROLES   = 1
          VISIBILITY_PUBLIC  = 2

          def is_private?
            visibility == VISIBILITY_PRIVATE
          end

          def is_public?
            !is_private?
          end

          def visibility=(value)
            self.is_public = value == VISIBILITY_PUBLIC
          end

          def visibility
            self.is_public ? VISIBILITY_PUBLIC : VISIBILITY_PRIVATE
          end
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::Compatibility::V23::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::Compatibility::V23::QueryPatch)
end
