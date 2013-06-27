module RedmineDigest
  class Digest
    # batch size for fetching issues
    ISSUE_BATCH_SIZE = 300

    attr_reader :digest_rule, :time_to

    delegate :name, :user, :recurrent, :project_selector,
             :to => :digest_rule, :allow_nil => true

    def initialize(digest_rule, time_to = nil)
      @digest_rule = digest_rule
      @time_to_base = time_to
    end

    def issues
      @issues ||= use_user_time_zone do
        fetch_issues
      end
    end

    def time_to
      @time_to ||= use_user_time_zone do
        get_time_to
      end
    end

    def time_from
      @time_from ||= use_user_time_zone do
        digest_rule.calculate_time_from(time_to)
      end
    end

    def sorted_digest_issues
      @sorted_digest_issues ||= get_sorted_digest_issues
    end

    def projects_count
      @projects_count ||= issues.map(&:project_id).uniq.count
    end

    def many_projects?
      projects_count > 1
    end

    def project_names
      @projects_names ||= issues.map(&:project_name).uniq
    end

    private

    def fetch_issues
      raise 'DigestRule#user must be filled' if user.nil?

      all_issue_ids = get_changed_issue_ids
      all_issue_ids += get_created_issue_ids if wants_created?
      all_issue_ids.uniq!

      d_issues = []

      all_issue_ids.in_groups_of(ISSUE_BATCH_SIZE) do |issue_ids|

        get_issues_scope(issue_ids.compact).each do |issue|

          d_issue = DigestIssue.new(
              :id => issue.id,
              :subject => issue.subject,
              :status_id => issue.status_id,
              :project_id => issue.project_id,
              :project_name => issue.project.name,
              :created_on => issue.created_on,
              :last_updated_on => issue.created_on
          )

          if issue.created_on >= time_from && issue.created_on < time_to
            event = DigestEvent.new(DigestEvent::ISSUE_CREATED,
                                    issue.id,
                                    issue.created_on,
                                    issue.author.to_s)
            d_issue.events[DigestEvent::ISSUE_CREATED] << event
          end

          # read all journal updates, add indice and remove private_notes
          journals = issue.journals
          journals.sort_by(&:id).each_with_index { |j, i| j.indice = i + 1 }

          journals.each do |journal|
            next if journal.created_on < time_from || journal.created_on >= time_to

            # get status_id from change history
            status_id_change = DigestEvent.detect_journal_detail(journal, 'status_id')
            d_issue.status_id = status_id_change.value if status_id_change

            next if journal.private_notes? &&
                    !user.allowed_to?(:view_private_notes, issue.project)

            digest_rule.event_types.each do |event_type|
              event = DigestEvent.detect_change_event(event_type,
                                                      issue.id,
                                                      journal.created_on,
                                                      journal.user.to_s,
                                                      journal)
              if event
                d_issue.last_updated_on = journal.created_on
                d_issue.events[event_type] << event
              end
            end
          end

          if wants_created?
            d_issues << d_issue if d_issue.any_events?
          else
            d_issues << d_issue if d_issue.any_changes_events?
          end

        end

      end

      d_issues
    end

    def wants_created?
      digest_rule.event_type_enabled?(DigestEvent::ISSUE_CREATED)
    end

    def get_sorted_digest_issues
      result = ActiveSupport::OrderedHash.new
      IssueStatus.sorted.each do |status|
        iss = issues.find_all { |i| i.status_id.to_i == status.id }.sort_by(&:last_updated_on)
        result[status] = iss
      end
      result
    end

    def get_time_to
      @time_to_base ||= Date.current.midnight
    end

    def get_changed_issue_ids
      Journal.joins(:issue).where('issues.project_id in (?)', project_ids).
          where('journals.created_on >= ? and journals.created_on < ?', time_from, time_to).
          uniq.pluck(:journalized_id)
    end

    def get_created_issue_ids
      Issue.where('issues.project_id in (?)', project_ids).
          where('issues.created_on >= ? and issues.created_on < ?', time_from, time_to).
          uniq.pluck(:id)
    end

    def get_issues_scope(issue_ids)
      Issue.includes(:author, :project, :journals => [:user, :details]).
          where('issues.id in (?)', issue_ids).
          where(Issue.visible_condition(user))
    end

    def project_ids
      @project_ids ||= digest_rule.affected_project_ids
    end

    def use_user_time_zone(&block)
      Time.use_zone(user.time_zone, &block)
    end
  end
end
