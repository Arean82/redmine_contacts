
module RedmineContacts
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_body_bottom, :partial => 'common/contacts_select2_data'
      render_on :view_layouts_base_html_head, :partial => 'common/additional_assets'
    end
  end
end
