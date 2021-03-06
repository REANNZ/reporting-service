# frozen_string_literal: true

class CreateServiceProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :service_providers do |t|
      t.string :entity_id, :name, null: false
      t.timestamps null: false
    end
  end
end
