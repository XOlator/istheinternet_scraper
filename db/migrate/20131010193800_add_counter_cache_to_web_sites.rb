class AddCounterCacheToWebSites < ActiveRecord::Migration

  def change
    add_column :web_sites, :web_pages_count, :integer, :default => 0, :after => :server_geo_city
    add_column :web_sites, :completed_web_pages_count, :integer, :default => 0, :after => :web_pages_count
  end

end