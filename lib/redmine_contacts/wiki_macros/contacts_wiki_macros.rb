module RedmineContacts
  module WikiMacros
    module ContactsWikiMacros  # ✅ Add this module

      Redmine::WikiFormatting::Macros.register do

        desc "Contact Description Macro"
        macro :contact_plain do |obj, args|
          args, options = extract_macro_options(args, :parent)
          raise 'No or bad arguments.' if args.size != 1
          if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
            first_name, last_name = args.first.split
            conditions = {:first_name => first_name}
            conditions[:last_name] = last_name if last_name
            contact = Contact.visible.find(:first, :conditions => conditions)
          else
            contact = Contact.visible.find_by_id(args.first)
          end
          link_to_source(contact) if contact
        end

        desc "Contact avatar"
        macro :contact_avatar do |obj, args|
          args, options = extract_macro_options(args, :parent)
          raise 'No or bad arguments.' if args.size != 1
          if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
            first_name, last_name = args.first.split
            conditions = {:first_name => first_name}
            conditions[:last_name] = last_name if last_name
            contact = Contact.visible.find(:first, :conditions => conditions)
          else
            contact = Contact.visible.find_by_id(args.first)
          end
          link_to avatar_to(contact, :size => "32"), contact_path(contact), :id => "avatar", :title => contact.name if contact
        end

        desc "Contact with avatar"
        macro :contact do |obj, args|
          args, options = extract_macro_options(args, :parent)
          raise 'No or bad arguments.' if args.size != 1
          if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
            first_name, last_name = args.first.split
            conditions = {:first_name => first_name}
            conditions[:last_name] = last_name if last_name
            contact = Contact.visible.find(:first, :conditions => conditions)
          else
            contact = Contact.visible.find_by_id(args.first)
          end
          contact_tag(contact) if contact
        end

        desc "Contact/Deal note"
        macro :contact_note do |obj, args|
          args, options = extract_macro_options(args, :parent)
          raise 'No or bad arguments.' if args.size != 1
          note = Note.find_by_id(args.first)
          textilizable(note, :content).html_safe if note && note.source.visible?
        end

        desc "Deal"
        macro :deal do |obj, args|
          args, options = extract_macro_options(args, :parent)
          raise 'No or bad arguments.' if args.size != 1
          deal = Deal.visible.find(args.first)
          deal_tag(deal)
        end

      end

    end # module ContactsWikiMacros
  end
end
