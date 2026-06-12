# frozen_string_literal: true

class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.string :title
      t.text :body
      t.string :mood
      t.timestamps
    end
  end
end
