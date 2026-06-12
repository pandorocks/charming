# frozen_string_literal: true

class AddFavoriteToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :favorite, :boolean
  end
end
