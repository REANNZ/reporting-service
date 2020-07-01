# frozen_string_literal: true

class ChangeUniqueConstraintsOnDsEvents < ActiveRecord::Migration[4.2]
  def change
    add_index :discovery_service_events,
              %i[unique_id timestamp phase],
              unique: true,
              # set shorter name - default would be too long
              name: 'index_ds_events_on_unique_id_and_timestamp_and_phase'
    remove_index :discovery_service_events,
                 column: %i[unique_id phase],
                 unique: true
  end
end
