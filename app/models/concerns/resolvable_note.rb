module ResolvableNote
  extend ActiveSupport::Concern

  RESOLVABLE_TYPES = %w(DiffNote DiscussionNote).freeze

  included do
    belongs_to :resolved_by, class_name: "User"

    validates :resolved_by, presence: true, if: :resolved?

    # Keep this scope in sync with the logic in `#potentially_resolvable?` in subclasses of `Discussion` that are resolvable.
    # `RESOLVABLE_TYPES` should include names of all subclasses that are resolvable (where the method can return true), and
    # the scope should also match the criteria `ResolvableDiscussion#potentially_resolvable?` puts on resolvability.
    scope :potentially_resolvable, -> { where(type: RESOLVABLE_TYPES).where(noteable_type: 'MergeRequest') }
    # Keep this scope in sync with `#resolvable?`
    scope :resolvable, -> { potentially_resolvable.user }

    scope :resolved, -> { resolvable.where.not(resolved_at: nil) }
    scope :unresolved, -> { resolvable.where(resolved_at: nil) }
  end

  module ClassMethods
    # This method must be kept in sync with `#resolve!`
    def resolve!(current_user)
      unresolved.update_all(resolved_at: Time.now, resolved_by_id: current_user.id)
    end

    # This method must be kept in sync with `#unresolve!`
    def unresolve!
      resolved.update_all(resolved_at: nil, resolved_by_id: nil)
    end
  end

  delegate :potentially_resolvable?, to: :to_discussion

  # Keep this method in sync with the `resolvable` scope
  def resolvable?
    potentially_resolvable? && !system?
  end

  def resolved?
    return false unless resolvable?

    self.resolved_at.present?
  end

  def to_be_resolved?
    resolvable? && !resolved?
  end

  # If you update this method remember to also update `.resolve!`
  def resolve!(current_user)
    return unless resolvable?
    return if resolved?

    self.resolved_at = Time.now
    self.resolved_by = current_user
    save!
  end

  # If you update this method remember to also update `.unresolve!`
  def unresolve!
    return unless resolvable?
    return unless resolved?

    self.resolved_at = nil
    self.resolved_by = nil
    save!
  end
end
