# frozen_string_literal: true

module Journal
  class EntriesState < ApplicationState
    attribute :selected_index, :integer, default: 0
    attribute :pending_delete_id, :integer
  end
end
