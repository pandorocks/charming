# frozen_string_literal: true

module Journal
  class EntryState < ApplicationState
    attribute :scroll_offset, :integer, default: 0
    attribute :pending_delete, :boolean, default: false
  end
end
