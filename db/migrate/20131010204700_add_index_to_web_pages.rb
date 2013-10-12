class AddIndexToWebPages < ActiveRecord::Migration

  def change
    add_index :web_pages, [:web_site_id]
  end

end