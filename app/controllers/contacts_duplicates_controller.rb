# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2025 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsDuplicatesController < ApplicationController
  unloadable
  helper :contacts

  before_action :find_project_by_project_id, :authorize, :except => :search
  before_action :find_contact, :except => :duplicates
  before_action :find_duplicate, :only => :merge

  helper :contacts

  def index
    @contacts = @contact.duplicates
  end

  def duplicates
    @contact = Contact.find_by(id: params[:contact_id].presence) || Contact.new
    @contact.first_name = params.dig(:contact, :first_name).to_s
    @contact.last_name = params.dig(:contact, :last_name).to_s
    @contact.middle_name = params.dig(:contact, :middle_name).to_s
    respond_to do |format|
      format.html { render :partial => 'duplicates', :layout => false if request.xhr? }
    end
  end

  def merge
	@duplicate.notes += @contact.notes
	@duplicate.deals += @contact.deals
	@duplicate.related_deals += @contact.related_deals
	@duplicate.issues += @contact.issues
	@duplicate.projects += @contact.projects

	@duplicate.email = (@duplicate.emails | @contact.emails).join(', ')
	@duplicate.phone = (@duplicate.phones | @contact.phones).join(', ')

    call_hook(:controller_contacts_duplicates_merge, { :params => params, :duplicate => @duplicate, :contact => @contact })
    @duplicate.tag_list = @duplicate.tag_list | @contact.tag_list
    begin
      Contact.transaction do
        @duplicate.save!
        @duplicate.reload
        @contact.reload
        @contact.destroy
        flash[:notice] = l(:notice_successful_merged)
        redirect_to :controller => 'contacts', :action => 'show', :project_id => @project, :id => @duplicate
      end
    rescue
      redirect_to :action => 'duplicates', :contact_id => @contact, :project_id => @project
    end
  end

  def search
    @contacts = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      scope = Contact.where({})
      scope = scope.limit(params[:limit] || 10)
      scope = scope.companies if params[:is_company]
      scope = scope.where(["#{Contact.table_name}.id <> ?", params[:contact_id].to_i]) if params[:contact_id]
      @contacts = scope.visible.by_project(@project).live_search(q).to_a.sort!{|x, y| x.name <=> y.name }
    else
      @contacts = @contact.duplicates
    end
    render :layout => false, :partial => 'list'
  end

  private

  def find_duplicate
    @duplicate = Contact.find(params[:duplicate_id])
    render_403 unless @duplicate.editable?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_contact
    @contact = Contact.find(params[:contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404 if !request.xhr?
  end
end
