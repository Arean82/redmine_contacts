
class Contact < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  CONTACT_FORMATS = {
    firstname_lastname: {
      string: '#{first_name} #{last_name}',
      order: %w(first_name middle_name last_name id),
      setting_order: 1
    },
    lastname_firstname_middlename: {
      string: '#{last_name} #{first_name} #{middle_name}',
      order: %w(last_name first_name middle_name id),
      setting_order: 1
    },
    firstname_middlename_lastname: {
      string: '#{first_name} #{middle_name} #{last_name}',
      order: %w(first_name middle_name last_name id),
      setting_order: 1
    },
    firstname_lastinitial: {
      string: '#{first_name} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?} #{last_name.to_s.chars.first + \'.\' unless last_name.blank?}',
      order: %w(first_name middle_name last_name id),
      setting_order: 2
    },
    firstinitial_lastname: {
      string: '#{first_name.to_s.gsub(/(([[:alpha:]])[[:alpha:]]*\.?)/, \'\2.\')} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?} #{last_name}',
      order: %w(first_name middle_name last_name id),
      setting_order: 2
    },
    lastname_firstinitial: {
      string: '#{last_name} #{first_name.to_s.gsub(/(([[:alpha:]])[[:alpha:]]*\.?)/, \'\2.\')} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?}',
      order: %w(last_name first_name middle_name id),
      setting_order: 2
    },
    firstname: {
      string: '#{first_name}',
      order: %w(first_name middle_name id),
      setting_order: 3
    },
    lastname_firstname: {
      string: '#{last_name} #{first_name}',
      order: %w(last_name first_name middle_name id),
      setting_order: 4
    },
    lastname_coma_firstname: {
      string: '#{last_name.to_s + \',\' unless last_name.blank?} #{first_name}',
      order: %w(last_name first_name middle_name id),
      setting_order: 5
    },
    lastname: {
      string: '#{last_name}',
      order: %w(last_name id),
      setting_order: 6
    }
  }

  VISIBILITY_PROJECT = 0
  VISIBILITY_PUBLIC = 1
  VISIBILITY_PRIVATE = 2

  delegate :street1, :street2, :city, :country, :country_code, :postcode, :region, :post_address, to: :address, allow_nil: true

  has_many :notes, as: :source, class_name: 'ContactNote', dependent: :delete_all
  has_many :addresses, dependent: :destroy, as: :addressable, class_name: 'Address'
  belongs_to :assigned_to, class_name: 'Principal', foreign_key: 'assigned_to_id'
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  if ActiveRecord::VERSION::MAJOR >= 4
    has_one :avatar, -> { where("#{Attachment.table_name}.description = 'avatar'") }, class_name: 'Attachment', as: :container, dependent: :destroy
    has_one :address, -> { where(address_type: 'business') }, dependent: :destroy, as: :addressable, class_name: 'Address'
    has_many :deals, -> { order("#{Deal.table_name}.status_id") }
    has_and_belongs_to_many :related_deals, -> { order("#{Deal.table_name}.status_id") }, uniq: true, class_name: 'Deal'
    has_and_belongs_to_many :projects, uniq: true
    has_and_belongs_to_many :issues, -> { order("#{Issue.table_name}.due_date") }, uniq: true
  else
    has_one :avatar, conditions: "#{Attachment.table_name}.description = 'avatar'", class_name: 'Attachment', as: :container, dependent: :destroy
    has_one :address, conditions: { address_type: 'business' }, dependent: :destroy, as: :addressable, class_name: 'Address'
    has_many :deals, order: "#{Deal.table_name}.status_id"
    has_and_belongs_to_many :related_deals, order: "#{Deal.table_name}.status_id", class_name: 'Deal', uniq: true
    has_and_belongs_to_many :projects, uniq: true
    has_and_belongs_to_many :issues, order: "#{Issue.table_name}.due_date", uniq: true
  end

  attr_accessor :phones
  attr_accessor :emails

  acts_as_customizable
  rcrm_acts_as_taggable
  acts_as_watchable
  acts_as_attachable view_permission: :view_contacts,
                     delete_permission: :edit_contacts

  acts_as_event datetime: :created_on,
                url: ->(o) { { controller: 'contacts', action: 'show', id: o } },
                type: 'icon icon-contact',
                title: ->(o) { o.name },
                description: ->(o) { [o.info, o.company, o.email, o.address, o.background].join(' ') }

  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider type: 'contacts',
                              permission: :view_contacts,
                              author_key: :author_id,
                              scope: joins(:projects)

    acts_as_searchable columns: ["#{table_name}.first_name",
                                "#{table_name}.middle_name",
                                "#{table_name}.last_name",
                                "#{table_name}.company",
                                "#{table_name}.email",
                                "#{Address.table_name}.full_address",
                                "#{table_name}.background",
                                "#{ContactNote.table_name}.content"],
                       project_key: "#{Project.table_name}.id",
                       scope: includes([:address, :notes]),
                       date_column: "created_on"
  else
    acts_as_activity_provider type: 'contacts',
                              permission: :view_contacts,
                              author_key: :author_id,
                              find_options: { include: :projects }

    acts_as_searchable columns: ["#{table_name}.first_name",
                                "#{table_name}.middle_name",
                                "#{table_name}.last_name",
                                "#{table_name}.company",
                                "#{table_name}.email",
                                "#{Address.table_name}.full_address",
                                "#{table_name}.background",
                                "#{ContactNote.table_name}.content"],
                       project_key: "#{Project.table_name}.id",
                       include: [:projects, :address, :notes],
                       order_column: "#{table_name}.id"
  end

  accepts_nested_attributes_for :address, allow_destroy: true, update_only: true, reject_if: proc { |attributes| Address.reject_address(attributes) }

  scope :visible, ->(*args) { eager_load(:projects).where(Contact.visible_condition(args.shift || User.current, *args)) }
  scope :deletable, ->(*args) { eager_load(:projects).where(Contact.deletable_condition(args.shift || User.current, *args)).readonly(false) }
  scope :editable, ->(*args) { eager_load(:projects).where(Contact.editable_condition(args.shift || User.current, *args)).readonly(false) }
  scope :by_project, ->(prj) { joins(:projects).where("#{Project.table_name}.id = ?", prj) unless prj.blank? }
  scope :like_by, ->(field, search) { { conditions: ["LOWER(#{Contact.table_name}.#{field}) LIKE ?", search.downcase + "%"] } }
  scope :companies, -> { where(is_company: true) }
  scope :people, -> { where(is_company: false) }
  scope :order_by_name, -> { order(Contact.fields_for_order_statement) }
  scope :order_by_creation, -> { order("#{Contact.table_name}.created_on DESC") }

  scope :by_full_name, ->(search) { where("LOWER(CONCAT(#{Contact.table_name}.first_name,' ',#{Contact.table_name}.last_name)) = ? ", search.downcase) }
  scope :by_name, ->(search) {
    where("(LOWER(#{Contact.table_name}.first_name) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.last_name) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.middle_name) LIKE LOWER(:p))",
          p: '%' + search.downcase + '%')
  }

  scope :live_search, ->(search) {
    where("(LOWER(#{Contact.table_name}.first_name) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.last_name) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.middle_name) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.company) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.email) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.phone) LIKE LOWER(:p) OR
            LOWER(#{Contact.table_name}.job_title) LIKE LOWER(:p))",
          p: '%' + search.downcase + '%')
  }

  validates_presence_of :first_name, :project
  validate :emails_format
  # validates_uniqueness_of :first_name, scope: [:last_name, :middle_name], message: :contact_already_exists

  safe_attributes 'first_name', 'middle_name', 'last_name', 'job_title', 'company',
                  'phone', 'email', 'homepage', 'background', 'skype', 'linkedin',
                  'twitter', 'facebook', 'vat', 'assigned_to_id', 'project_id',
                  'visibility', 'is_company', 'tags', 'created_on', 'updated_on',
                  'address_attributes', 'contact_custom_field_values',
                  'company_ids', 'watcher_user_ids'

  before_save :clear_empty_emails
  after_create :send_notification
  after_create :update_company_contacts

  def self.fields_for_order_statement
    case Setting.plugin_redmine_contacts['contacts_sort_by']
    when 'firstname'
      "LOWER(#{Contact.table_name}.first_name), LOWER(#{Contact.table_name}.last_name), LOWER(#{Contact.table_name}.middle_name)"
    when 'lastname'
      "LOWER(#{Contact.table_name}.last_name), LOWER(#{Contact.table_name}.first_name), LOWER(#{Contact.table_name}.middle_name)"
    else
      "LOWER(#{Contact.table_name}.last_name), LOWER(#{Contact.table_name}.first_name), LOWER(#{Contact.table_name}.middle_name)"
    end
  end

  def self.visible_condition(user, options = {})
    project = options[:project]
    if user.admin?
      "#{Contact.table_name}.id > 0"
    elsif project
      # contacts visible if project member and contact visibility is project or public
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC} OR " \
      "(#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PROJECT} AND " \
      "#{Contact.table_name}.project_id = #{project.id})"
    else
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC}"
    end
  end

  def self.deletable_condition(user, options = {})
    project = options[:project]
    if user.admin?
      "#{Contact.table_name}.id > 0"
    elsif project
      # contacts deletable if project member and contact visibility is project or public
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC} OR " \
      "(#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PROJECT} AND " \
      "#{Contact.table_name}.project_id = #{project.id})"
    else
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC}"
    end
  end

  def self.editable_condition(user, options = {})
    project = options[:project]
    if user.admin?
      "#{Contact.table_name}.id > 0"
    elsif project
      # contacts editable if project member and contact visibility is project or public
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC} OR " \
      "(#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PROJECT} AND " \
      "#{Contact.table_name}.project_id = #{project.id})"
    else
      "#{Contact.table_name}.visibility = #{Contact::VISIBILITY_PUBLIC}"
    end
  end

  def self.by_company(company_id)
    joins(:projects).where("#{Contact.table_name}.company_id = ?", company_id)
  end

  def self.project_allowed_to_condition(project, permission)
    # Returns condition to check if user has permission to perform action on contact in project
    if project
      "#{Contact.table_name}.project_id = #{project.id} AND " \
      "EXISTS (SELECT 1 FROM members m WHERE m.user_id = #{User.current.id} AND m.project_id = #{project.id} AND " \
      "m.roles_mask & #{Role.permission_mask(permission)} > 0)"
    else
      '1=1'
    end
  end

  def self.all_with_email
    where.not(email: [nil, ''])
  end

  def self.all_for_projects(projects)
    joins(:projects).where("#{Project.table_name}.id IN (?)", projects).distinct
  end

  def all_deals
    Deal.where(id: deals.pluck(:id) + related_deals.pluck(:id))
  end

  def duplicates
    self.class.where(first_name: first_name, last_name: last_name, middle_name: middle_name).where.not(id: id)
  end

  def company_contacts
    Contact.where(company: company)
  end

  def name(format = nil, html = false)
    format ||= Setting.plugin_redmine_contacts['contact_name_format'].to_sym

    string = CONTACT_FORMATS[format][:string] rescue CONTACT_FORMATS[:firstname_lastname][:string]
    name = eval('"' + string + '"')

    html ? ERB::Util.html_escape(name) : name
  end

  def address_or_default
    address || build_address
  end

  def visible?(user = User.current)
    return true if user.admin?
    return false if visibility == VISIBILITY_PRIVATE && user != author

    projects.any? { |p| p.users.include?(user) } || visibility == VISIBILITY_PUBLIC
  end

  def editable?(user = User.current)
    user.admin? || (projects.any? { |p| p.users.include?(user) } && visibility != VISIBILITY_PRIVATE)
  end

  def deletable?(user = User.current)
    editable?(user)
  end

  def recipients
    notified_users.map(&:mail)
  end

  def notified_users
    watchers.select(&:active?).map(&:user)
  end

  def author_name
    author.try(:name)
  end

  def author_mail
    author.try(:mail)
  end

  def has_avatar?
    avatar.present?
  end

  def emails
    email.to_s.split(/, ?/)
  end

  def phones
    phone.to_s.split(/, ?/)
  end

  def emails_format
    emails.each do |email|
      errors.add(:email, :invalid) unless email =~ /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
    end
  end

  def clear_empty_emails
    self.email = emails.reject(&:blank?).join(', ')
  end

  def send_notification
    # Add notification logic here
  end

  def update_company_contacts
    # Add logic to update contacts associated with the company here
  end

  def self.export_contacts(contacts)
    contacts.map do |c|
      {
        first_name: c.first_name,
        middle_name: c.middle_name,
        last_name: c.last_name,
        email: c.email,
        phone: c.phone,
        company: c.company,
        job_title: c.job_title,
        address: c.address.try(:full_address)
      }
    end
  end

  def to_s
    name
  end

end
