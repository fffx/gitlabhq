class NotifyPreview < ActionMailer::Preview
  def note_merge_request_email_for_individual_note
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is an individual note on a merge request :smiley:

        In this notification email, we expect to see:

        - The note contents (that's what you're looking at)
        - A link to view this note on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, note: note)
    end
  end

  def note_merge_request_email_for_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion
        - The note contents (that's what you're looking at)
        - A link to view this discussion on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiscussionNote', note: note)
    end
  end

  def note_merge_request_email_for_diff_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion and on what file
        - The diff
        - The note contents (that's what you're looking at)
        - A link to view this discussion on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: merge_request.diff_refs
      )

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiffNote', position: position, note: note)
    end
  end

  private

  def project
    @project ||= Project.find_by_full_path('gitlab-org/gitlab-test')
  end

  def issue
    @issue ||= project.issues.last
  end

  def merge_request
    @merge_request ||= project.merge_requests.find_by(source_branch: 'master', target_branch: 'feature')
  end

  def commit
    @commit ||= project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
  end

  def user
    @user ||= User.last
  end

  def note_body
    <<-MD.strip_heredoc
      Hello :smiley:

      We expect a blank line between:
      - The heading ("Adminstrator started...")
      - The diff
    MD
  end

  def create_note(params)
    Notes::CreateService.new(project, user, params).execute
  end

  def note_email(method)
    cleanup do
      note = yield

      Notify.public_send(method, user.id, note)
    end
  end

  def cleanup
    email = nil

    ActiveRecord::Base.transaction do
      email = yield
      raise ActiveRecord::Rollback
    end

    email
  end
end
