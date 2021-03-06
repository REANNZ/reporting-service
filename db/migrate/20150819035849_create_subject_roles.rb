# frozen_string_literal: true

class CreateSubjectRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :subject_roles do |t|
      t.belongs_to :subject, null: false
      t.belongs_to :role, null: false

      t.timestamps

      t.foreign_key :subjects
      t.foreign_key :roles
      t.index %i[subject_id role_id], unique: true
    end
  end
end
