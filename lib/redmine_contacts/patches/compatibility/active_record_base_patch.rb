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
          # Separate args into scope and options
          # Rails has_many(name, scope = nil, **options, &block)

          if args.first.is_a?(Proc)
            scope = args.shift
          else
            scope = nil
          end

          options = args.first || {}

          # If options contain :through, call original immediately
          return has_many_without_contacts(name, scope, **options, &extension) if options[:through]

          # Convert legacy options to modern style
          scope_opts = {}
          scope_opts[:where]     = options.delete(:conditions) if options[:conditions]
          scope_opts[:joins]     = options.delete(:include) if options[:include]
          scope_opts[:distinct]  = options.delete(:uniq) if options[:uniq]

          [:order, :having, :select, :group, :limit, :offset, :readonly].each do |key|
            scope_opts[key] = options.delete(key) if options.key?(key)
          end

          if scope_opts.any?
            # Build scope proc applying the scope options as chained methods
            scope = proc do
              scope_opts.inject(all) do |relation, (method, arg)|
                if arg.nil? || arg == true || arg == false
                  relation.public_send(method)
                else
                  relation.public_send(method, arg)
                end
              end
            end
          end

          if scope
            has_many_without_contacts(name, scope, **options, &extension)
          else
            has_many_without_contacts(name, **options, &extension)
          end
        end
      end
    end
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send(:include, RedmineContacts::Patches::ActiveRecordBasePatch)
end
