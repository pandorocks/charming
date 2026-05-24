# frozen_string_literal: true

require "active_model"

module Charming
  class ApplicationModel
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end
