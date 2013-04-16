class CreateWebSites < ActiveRecord::Migration

  def change
    create_table :web_sites do |t|
      # Base URL information
      t.integer       :parent_id
      t.string        :url
      t.string        :host_url

      # Robots.txt -- store in db, faster calls
      t.text          :robots_txt
      t.datetime      :robots_txt_updated_at

      # DNS record information -- store as text file with key info in db
      t.string        :whois_record_file_name
      t.datetime      :whois_record_updated_at
      t.string        :nameservers
      t.datetime      :domain_created_on
      t.datetime      :domain_updated_on
      t.datetime      :domain_expires_on

      # Server information
      t.string        :server_ip_address,                   :length => 15
      t.string        :server_geo_country,                  :length => 2
      t.string        :server_geo_region
      t.string        :server_geo_city

      # Miscellaneous info
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :web_sites, [:url], :unique => true
  end

end