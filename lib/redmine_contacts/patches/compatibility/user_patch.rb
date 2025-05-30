module RedmineContacts
  module Patches
    module Compatibility
      module UserPatch
        def self.included(base)
          base.class_eval do
            scope :having_mail, lambda { |arg|
              addresses = Array.wrap(arg).map { |a| a.to_s.downcase }
              if addresses.any?
                joins(:email_addresses).where("LOWER(#{EmailAddress.table_name}.address) IN (?)", addresses).uniq
              else
                none
              end
            }

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
      end
    end
  end
end

unless User.included_modules.include?(RedmineContacts::Patches::Compatibility::UserPatch)
  User.send(:include, RedmineContacts::Patches::Compatibility::UserPatch)
end
