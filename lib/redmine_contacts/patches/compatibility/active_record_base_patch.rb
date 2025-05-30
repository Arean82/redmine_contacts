module RedmineContacts
  module Patches
    module Compatibility
    module ActiveRecordBasePatch
      def has_many(name, *args, &extension)
        if args.first.is_a?(Proc)
          scope = args.shift
        else
          scope = nil
        end

        options = args.first || {}

        # Don't patch if :through option present
        return super(name, scope, **options, &extension) if options[:through]

        # Convert legacy options to modern scope calls
        scope_opts = {}
        scope_opts[:where]    = options.delete(:conditions) if options[:conditions]
        scope_opts[:joins]    = options.delete(:include) if options[:include]
        scope_opts[:distinct] = options.delete(:uniq) if options[:uniq]

        [:order, :having, :select, :group, :limit, :offset, :readonly].each do |key|
          scope_opts[key] = options.delete(key) if options.key?(key)
        end

        if scope_opts.any?
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
          super(name, scope, **options, &extension)
        else
          super(name, **options, &extension)
        end
      end
    end
    end
  end
end

# Defer patching until ActiveRecord is fully loaded
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.singleton_class.prepend(RedmineContacts::Patches::Compatibility::ActiveRecordBasePatch)
end
