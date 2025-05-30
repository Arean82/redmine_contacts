

module RedmineContacts
  module Patches
    module Compatibility
      module V23
        module QueryPatch
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
              unloadable
              # Constants for visibility states
              VISIBILITY_PRIVATE = 0
              VISIBILITY_ROLES   = 1
              VISIBILITY_PUBLIC  = 2
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
            visibility == VISIBILITY_PUBLIC
          end

          # Override visibility setter to ensure only valid values
          def visibility=(value)
            # Accept value either as integer or boolean
            val = case value
                  when true then VISIBILITY_PUBLIC
                  when false then VISIBILITY_PRIVATE
                  when Integer then value
                  else VISIBILITY_PRIVATE
                  end
            write_attribute(:visibility, val)
          end

          # Override visibility getter to read attribute
          def visibility
            read_attribute(:visibility).to_i
          end
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::Compatibility::V23::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::Compatibility::V23::QueryPatch)
end
