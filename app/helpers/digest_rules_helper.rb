module DigestRulesHelper
  def project_selector_options_for_select
    DigestRule::PROJECT_SELECTOR_VALUES.map do |v|
      [ l(v, :scope => 'project_selector'), v ]
    end
  end

  def project_ids_options_for_select
    root_projects = Project.visible.active.roots.has_module(:issue_tracking).order(:name)
    projects_tree(root_projects)
  end

  def projects_tree(projects)
    result = []
    projects.each do |project|
      result << {
          :text => project.name,
          :id => project.id
      }
      children = project.children.active.has_module(:issue_tracking).order(:name)
      if children.any?
        result << {
            :text => project.name,
            :children => projects_tree(children)
        }
      end
    end
    result
  end

  def recurrent_options_for_select
    DigestRule::RECURRENT_TYPES.map do |v|
      [ l(v, :scope => 'recurrent_types'), v ]
    end
  end

  def find_select2_js_locale(lang)
    url = "select2/select2_locale_#{lang}"
    file_path = File.join(Rails.root, "/plugin_assets/redmine_digest/#{url}")
    url if File.exists?(file_path)
  end

  def event_type_id(event_type)
    "digest_rule_event_type_#{event_type}"
  end

  def link_to_digest_issue(di)
    link_to digest_issue_text(di),
            {
                :host => Setting.host_name,
                :protocol => Setting.protocol,
                :controller => 'issues',
                :action => 'show',
                :id => di.id
            },
            :title => digest_issue_title(di)
  end

  def digest_issue_text(di)
    "##{di.id} [#{di.project_name}] #{di.subject}"
  end

  def digest_issue_title(di)
    [
        di.new_issue? ?
            "#{l(:label_issue_added)} #{di.created_on.to_s(:short)}" : nil,
        di.changes_event_types.any? ?
            "#{l(:label_issue_updated)} #{di.last_updated_on.to_s(:short)}" : nil
    ].compact.join(', ')
  end
end
