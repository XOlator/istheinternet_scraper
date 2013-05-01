class CreateWebPages < ActiveRecord::Migration

  def change
    create_table :web_pages do |t|
      # Base URL information
      t.integer       :web_site_id
      t.string        :url,                         :length => 512
      t.string        :path,                        :length => 512
      t.string        :slug,                        :length => 512

      # HTML -- store as text file with key info in db
      t.string        :html_page_file_name
      t.integer       :html_page_file_size
      t.datetime      :html_page_updated_at

      # Response information
      t.boolean       :available,                   :default => true
      t.string        :base_uri,                    :length => 512
      t.integer       :page_status
      t.text          :headers
      t.string        :charset
      t.datetime      :last_modified_at

      # Meta information
      t.string        :title,                       :length => 512
      t.text          :meta_tags

      # Screenshot
      t.string        :screenshot_file_name
      t.integer       :screenshot_file_size
      t.string        :screenshot_content_type
      t.datetime      :screenshot_file_updated_at

      # Miscellaneous info
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :web_pages, [:url], :unique => true
    add_index :web_pages, [:web_site_id, :slug], :unique => true
  end

end