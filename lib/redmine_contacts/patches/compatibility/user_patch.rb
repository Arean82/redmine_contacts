
module RedmineContacts
  module Patches
    module Compatibility
      module UserPatch
        def self.included(base)
          base.send(:include, InstanceMethods)

          base.class_eval do
            # Define scope :having_mail (shared by both)
            scope :having_mail, lambda {|arg|
              addresses = Array.wrap(arg).map {|a| a.to_s.downcase }
              if addresses.any?
                joins(:email_addresses).where("LOWER(#{EmailAddress.table_name}.address) IN (?)", addresses).uniq
              else
                none
              end
            }

            # Enhanced find_by_mail for both AR < 4 and >= 4 compatibility
            def self.find_by_mail(mail)
              if ActiveRecord::VERSION::MAJOR >= 4
                mail = mail.is_a?(Array) ? mail : [mail]
                having_mail(mail).first
              else
                where("LOWER(mail) = ?", mail.to_s.downcase).first
              end
            end
          end
        end

        module InstanceMethods
          # Adds the missing atom_key method for Redmine < 5.0
          def atom_key
            return super if Redmine::VERSION.to_s >= '5.0'
            rss_key
          end
        end
      end
    end
  end
end

unless User.included_modules.include?(RedmineContacts::Patches::Compatibility::UserPatch)
  User.send(:include, RedmineContacts::Patches::Compatibility::UserPatch)
end
