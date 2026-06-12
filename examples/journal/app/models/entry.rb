# frozen_string_literal: true

module Journal
  class Entry < ApplicationRecord
    MOODS = %w[good meh rough].freeze
    MOOD_EMOJI = {"good" => "😄", "meh" => "😐", "rough" => "😞"}.freeze

    validates :title, presence: true
    validates :mood, inclusion: {in: MOODS}

    scope :recent_first, -> { order(created_at: :desc) }
    scope :favorites, -> { where(favorite: true) }

    def mood_emoji
      MOOD_EMOJI.fetch(mood, "❓")
    end

    # The label shown in the journal list: date, mood, title, favorite star.
    def list_label
      star = favorite? ? " ★" : ""
      "#{created_at.strftime("%b %d")}  #{mood_emoji}  #{title}#{star}"
    end
  end
end
