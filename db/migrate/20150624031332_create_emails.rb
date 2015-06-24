class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string :domain
      t.string :email

      t.timestamps null: false
    end
  end
end
