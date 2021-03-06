# frozen_string_literal: true

class CreateRapidConnectServices < ActiveRecord::Migration[4.2]
  def change
    create_table :rapid_connect_services do |t|
      t.string :identifier, :name, :type, null: false
      t.timestamps null: false
    end
  end
end
