# frozen_string_literal: true

module DemoApp
  class TablesController < ApplicationController
    key "up",    :handle_table_key
    key "down",  :handle_table_key
    key "home",  :handle_table_key
    key "end",   :handle_table_key
    key "enter", :handle_table_key

    def show
      render_tables
    end

    def handle_table_key
      result = table.handle_key(event)
      remember_selection(result)
      render_tables
    end

    def dispatch_component_mouse
      table.handle_mouse(event)
      render_tables
      response
    end

    private

    def render_tables
      render TablesView.new(
        tables: tables,
        table: table,
        palette: command_palette,
        screen: screen
      )
    end

    def remember_selection(result)
      return unless result.is_a?(Array) && result.first == :selected

      tables.last_selected = result.last
    end

    def tables
      model(:tables, TablesModel)
    end

    def table
      session[:tables_table] ||= Charming::Components::Table.new(
        header: tables.header,
        rows: tables.rows
      )
    end
  end
end
