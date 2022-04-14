class AddDomainToOrganisation < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :domain, :string
    add_index :organizations, :domain, unique: true
  end
end
