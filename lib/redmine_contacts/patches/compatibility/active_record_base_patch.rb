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
        def has_many_with_contacts(name, *args, &extension)
          # If there is a :through option, call original has_many directly
          if args.any? && args[0].is_a?(Hash) && args[0][:through]
            return has_many_without_contacts(name, *args, &extension)
          end

          # Separate scope and options based on argument types
          scope = nil
          options = {}

          if args.first.is_a?(Proc)
            scope = args.shift
            options = args.first || {}
          else
            options = args.first || {}
          end

          # Rails 4+ signature fix: pass options as keyword args
          if ActiveRecord::VERSION::MAJOR >= 4
            if scope.nil?
              scope, options = build_scope_and_options(options)
            end
            has_many_without_contacts(name, scope, **options, &extension)
          else
            has_many_without_contacts(name, options, &extension)
          end
        end

        private

        def build_scope_and_options(options)
          scope_opts, opts = parse_options(options)

          scope = nil
          unless scope_opts.empty?
            scope = lambda do
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
            if opts.key?(key)
              scope_opts[key] = opts.delete(key)
            end
          end

          scope_opts[:where] = opts.delete(:conditions) if opts.key?(:conditions)
          scope_opts[:joins] = opts.delete(:include) if opts.key?(:include)
          scope_opts[:distinct] = opts.delete(:uniq) if opts.key?(:uniq)

          [scope_opts, opts]
        end
      end
    end
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend(RedmineContacts::Patches::ActiveRecordBasePatch::InstanceMethods)
  unless ActiveRecord::Associations::ClassMethods.included_modules.include?(RedmineContacts::Patches::ActiveRecordBasePatch)
    ActiveRecord::Associations::ClassMethods.send(:include, RedmineContacts::Patches::ActiveRecordBasePatch)
  end
end
