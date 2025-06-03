module RedmineContacts
  module Hooks
    class ViewsProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_left, :partial => "projects/contacts"
    end
  end
end
