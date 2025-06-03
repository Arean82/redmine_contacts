# Unified version of ContactsProjectsController combining paid (RedmineUP) and extended free functionality

class ContactsProjectsController < ApplicationController
  unloadable

  before_action :find_optional_project, :find_contact
  before_action :find_related_projects, only: [:destroy, :create]
  before_action :check_count, only: :destroy
  before_action :uniqlize_projects, only: [:destroy, :create]

  accept_api_auth :create, :destroy

  helper :contacts

  def new
    @show_form = "true"
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  rescue ::ActionController::RedirectBackError
    render plain: 'Project added.', layout: true
  end

  def create
    @related_projects.each do |project|
      @contact.projects << project unless @contact.projects.include?(project)
    end

    if @contact.save
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render action: 'new' }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render action: 'new' }
        format.api { render_validation_errors(@contact) }
      end
    end
  end

  def destroy
    @related_projects.each do |project|
      @contact.projects.delete(project)
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render action: 'new' }
      format.api { render_api_ok }
    end
  end

  private

  def find_related_projects
    raw_ids = Array(params.dig(:project, :id) || params[:id] || params[:project_id])
    @related_projects = Project.where(id: raw_ids).or(Project.where(identifier: raw_ids)).to_a

    raise ActiveRecord::RecordNotFound if @related_projects.blank?
    unless @related_projects.all? { |p| User.current.allowed_to?(:edit_contacts, p) }
      raise Unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_count
    deny_access if @contact.projects.size <= 1
  end

  def find_contact
    @contact = Contact.find(params[:contact_id])
    raise Unauthorized unless @contact.editable?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def uniqlize_projects
    @contact.projects = @contact.projects.uniq
  end
end
