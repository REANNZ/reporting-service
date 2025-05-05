class AddLastSignInAtToSubjects < ActiveRecord::Migration[7.0]
  def change
    add_column :subjects, :last_sign_in_at, :datetime
  end
end
