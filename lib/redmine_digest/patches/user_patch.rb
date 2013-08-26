require 'project'
require 'principal'
require 'user'

module RedmineDigest
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        has_many :digest_rules
      end

      def receive_digest_on_issue_created?(issue)
        digest_rules.active.inject(false) do |res, rule|
          res || rule.apply_for_created_issue?(issue)
        end
      end

      def receive_digest_on_journal_updated?(journal)
        digest_rules.active.inject(false) do |res, rule|
          res || rule.apply_for_updated_issue?(journal)
        end
      end

      def involved_in?(issue)
        issue.author == self ||
            is_or_belongs_to?(issue.assigned_to) ||
            is_or_belongs_to?(issue.assigned_to_was)
      end
    end
  end
end

unless User.included_modules.include?(RedmineDigest::Patches::UserPatch)
  User.send :include, RedmineDigest::Patches::UserPatch
end
