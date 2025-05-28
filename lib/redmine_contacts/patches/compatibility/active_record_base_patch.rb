module RedmineContacts
  module Patches
    module ActiveRecordBasePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :has_many_without_contacts, :has_many
          alias_method :has_many, :has_many_with_contacts
        end
      end

      module InstanceMethods
        def has_many_with_contacts(name, param2 = nil, *param3, &extension)
          # If through option is used, call original has_many
          if param3.is_a?(Array) && param3[0] && param3[0][:through]
            return has_many_without_contacts(name, param2, *param3, &extension)
          end

          options = {}
          scope = nil

          if param2.nil?
            options = {}
          else
            if param2.is_a?(Proc)
              scope = param2
              options = param3.empty? ? {} : param3[0]
            else
              options = param2
            end
          end

          if ActiveRecord::VERSION::MAJOR >= 4
            scope, options = build_scope_and_options(options) if scope.nil?
            has_many_without_contacts(name, scope, options, &extension)
          else
            has_many_without_contacts(name, options, &extension)
          end
        end

        def build_scope_and_options(options)
          scope_opts, opts = parse_options(options)

          scope = if scope_opts.any?
            lambda do
              scope_opts.inject(self) do |result, (method, value)|
                result.send(method, value)
              end
            end
          end

          [scope, opts]
        end

        def parse_options(opts)
          scope_opts = {}
          [:order, :having, :select, :group, :limit, :offset, :readonly].each do |key|
            scope_opts[key] = opts.delete(key) if opts[key]
          end
          scope_opts[:where] = opts.delete(:conditions) if opts[:conditions]
          scope_opts[:joins] = opts.delete(:include) if opts[:include]
          scope_opts[:distinct] = opts.delete(:uniq) if opts[:uniq]

          [scope_opts, opts]
        end
      end
    end
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend RedmineContacts::Patches::ActiveRecordBasePatch::InstanceMethods
  unless ActiveRecord::Associations::ClassMethods.included_modules.include?(RedmineContacts::Patches::ActiveRecordBasePatch)
    ActiveRecord::Associations::ClassMethods.send(:include, RedmineContacts::Patches::ActiveRecordBasePatch)
  end
end
