# frozen_string_literal: true

require "active_model"

module Charming
  # ApplicationModel is the persistent state base for application data models. It includes
  # `ActiveModel::Model` (validation, initialisation) and `ActiveModel::Attributes` (typed attributes
  # with defaults via `attribute :name, :type, default: ...`), making it suitable as session-stored root objects.
  class ApplicationModel
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end
