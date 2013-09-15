class AddMoreIndexes < ActiveRecord::Migration

  def change
    add_index :web_pages, [:screenshot_file_name]
    add_index :web_pages, [:available]

    add_index :page_queues, [:locked]
  end

end