module RedmineContacts
  module Patches
    module Compatibility
      module V23
        module QueryPatch
          VISIBILITY_PRIVATE = 0
          VISIBILITY_ROLES   = 1
          VISIBILITY_PUBLIC  = 2

          def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
              unloadable
              # Constants removed from here to fix dynamic constant assignment error
            end
          end
        end

        module InstanceMethods
          def is_private?
            visibility == QueryPatch::VISIBILITY_PRIVATE
          end

          def is_public?
            visibility == QueryPatch::VISIBILITY_PUBLIC
          end

          # Override visibility setter to ensure only valid values
          def visibility=(value)
            val = case value
                  when true then QueryPatch::VISIBILITY_PUBLIC
                  when false then QueryPatch::VISIBILITY_PRIVATE
                  when Integer then value
                  else QueryPatch::VISIBILITY_PRIVATE
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
