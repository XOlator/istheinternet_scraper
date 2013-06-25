class CreatePageQueues < ActiveRecord::Migration

  def change
    create_table :page_queues do |t|
      # Base URL information
      t.integer       :priority
      t.string        :url
      t.integer       :web_page_id

      # Queue checks
      t.boolean       :scrape,          :default => false
      t.boolean       :parse,           :default => false
      t.boolean       :screenshot,      :default => false
      t.boolean       :process,         :default => false

      # Locking
      t.boolean       :locked,          :default => false
      t.datetime      :locked_at

      # Miscellaneous info
      t.integer       :error_count,     :default => 0
      t.datetime      :retry_at
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :page_queues, [:url], :unique => true
  end

end