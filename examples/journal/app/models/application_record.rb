# frozen_string_literal: true

module Journal
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
