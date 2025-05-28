module RedmineContacts
  module Patches
    module CompatibilityPatch
      if Redmine::VERSION.to_s < '2.4'
        Dir[File.dirname(__FILE__) + '/compatibility/2.3/*.rb'].each { |f| require f }
      end

      if ActiveRecord::VERSION::MAJOR > 3
        Dir[File.dirname(__FILE__) + '/compatibility/rails/*.rb'].each { |f| require f }
      end
    end
  end
end
