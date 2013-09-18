class AddStepIndexToWebPages < ActiveRecord::Migration

  def change
    add_column :web_pages, :step_index, :integer, default: 0, after: :slug
  end

end