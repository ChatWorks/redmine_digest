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

  def notify_options_for_select
    DigestRule::NOTIFY_OPTIONS.map do |v|
      [ l(v, :scope => 'notify_options'), v ]
    end
  end

  def recurrent_options_for_select
    DigestRule::RECURRENT_TYPES.map do |v|
      [ l(v, :scope => 'recurrent_types'), v ]
    end
  end

  def templates_for_select
    DigestRule::TEMPLATES.map do |v|
      [ l(v, :scope => 'digest_template'), v ]
    end
  end

  def event_type_id(event_type)
    "digest_rule_event_type_#{event_type}"
  end

  def digest_issue_url(di)
    {
        :host => Setting.host_name,
        :protocol => Setting.protocol,
        :controller => 'issues',
        :action => 'show',
        :id => di.id
    }
  end

  def digest_issue_text(di, show_project_name = true)
    if show_project_name
      "##{di.id} [#{di.project_name}] #{di.subject}"
    else
      "##{di.id} #{di.subject}"
    end
  end

  def digest_issue_title(di)
    [
        di.new_issue? ?
            "#{l(:label_issue_added)} #{format_time(di.created_on)}" : nil,
        di.changes_event_types.any? ?
            "#{l(:label_issue_updated)} #{format_time(di.last_updated_on)}" : nil
    ].compact.join(', ')
  end

  def event_type_color(event_type)
    case event_type
      when DigestEvent::STATUS_CHANGED then '#defff1'
      when DigestEvent::PERCENT_CHANGED then '#d8d8ff'
      when DigestEvent::ASSIGNEE_CHANGED then '#fbe3ff'
      when DigestEvent::VERSION_CHANGED then '#ffe1e3'
      when DigestEvent::PROJECT_CHANGED then '#fffcde'
      when DigestEvent::SUBJECT_CHANGED then '#FF8E8E'
      when DigestEvent::OTHER_ATTR_CHANGED then '#E7E9E6'
      when DigestEvent::COMMENT_ADDED then '#e0ffe1'
      when DigestEvent::ATTACHMENT_ADDED then '#DFF3FF'
      when DigestEvent::ISSUE_CREATED then '#e1ffe3'
      else 'gray'
    end
  end
end
