require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::DigestTest < ActiveSupport::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :journals, :journal_details,
           :enabled_modules

  def test_time_from_daily
    rule = DigestRule.new :recurrent => DigestRule::DAILY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 05, 15).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_time_from_weekly
    rule = DigestRule.new :recurrent => DigestRule::WEEKLY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 05, 9).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_time_from_monthly
    rule = DigestRule.new :recurrent => DigestRule::MONTHLY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 04, 16).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_sorted_digest_issues
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [1, 2, 4, 6, 7, 8, 11, 12]
    sorted_ids = digest.sorted_digest_issues.values.flatten.map(&:id).sort
    assert_equal exp_ids, sorted_ids
  end
  
end
