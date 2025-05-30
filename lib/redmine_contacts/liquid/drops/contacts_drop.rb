module RedmineContacts
  module Liquid
    module Drops

class ContactsDrop < ::Liquid::Drop  # explicitly use the top-level Liquid::Drop

  def initialize(contacts)
    @contacts = contacts
  end

  def before_method(id)
    contact = @contacts.where(:id => id).first || Contact.new
    ContactDrop.new contact
  end

  def all
    @all ||= @contacts.map do |contact|
      ContactDrop.new contact
    end
  end

  def visible
    @visible ||= @contacts.visible.map do |contact|
      ContactDrop.new contact
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class ContactDrop < ::Liquid::Drop

  delegate :id, :name, :first_name, :last_name, :middle_name, :company, :phones, :emails, :primary_email, :website, :skype_name, :birthday, :age, :background, :job_title, :is_company, :tag_list, :post_address, :to => :@contact

  def initialize(contact)
    @contact = contact
  end

  def contact_company
    ContactDrop.new @contact.contact_company if @contact.contact_company
  end

  def company_contacts
    @contact.company_contacts.map{|c| ContactDrop.new c } if @contact.company_contacts
  end

  def avatar_diskfile
    @contact.avatar.diskfile
  end

  def avatar_url
    helpers.url_for :controller => "attachments", :action => "contacts_thumbnail", :id => @contact.avatar, :size => '64', :only_path => true
  end

  def notes
    @contact.notes.map{|n| NoteDrop.new(n) }
  end

  def address
    AddressDrop.new(@contact.address) if @contact.address
  end
  def custom_field_values
    @contact.custom_field_values
  end

  private

  def helpers
    Rails.application.routes.url_helpers
  end

end
    end
  end
end