class CreateUrlBlacklists < ActiveRecord::Migration

  def change
    create_table :url_blacklists do |t|
      t.string        :url
      t.integer       :port
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :url_blacklists, [:url], :unique => true
  end

end