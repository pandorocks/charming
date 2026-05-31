# frozen_string_literal: true

require "active_model"

module Charming
  # ApplicationState is the base for session-backed TUI state. It includes
  # `ActiveModel::Model` (validation, initialisation) and `ActiveModel::Attributes` (typed attributes
  # with defaults via `attribute :name, :type, default: ...`), making it suitable for screen/form state.
  class ApplicationState
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end
