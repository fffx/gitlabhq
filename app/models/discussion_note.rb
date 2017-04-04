# A note in a non-diff discussion on an issue, merge request, commit, or snippet
class DiscussionNote < Note
  NOTEABLE_TYPES = %w(MergeRequest Issue Commit Snippet).freeze

  validates :noteable_type, inclusion: { in: NOTEABLE_TYPES }

  def discussion_class(*)
    Discussion
  end
end
