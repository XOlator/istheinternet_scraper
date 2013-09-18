class AddPixelColors < ActiveRecord::Migration

  def change
    rename_column :web_pages, :screenshot_file_updated_at, :screenshot_updated_at

    add_column :color_palettes, :pixel_color, :string, after: :web_page_id
    add_column :color_palettes, :pixel_color_red, :integer, limit: 3, after: :web_page_id
    add_column :color_palettes, :pixel_color_green, :integer, limit: 3, after: :pixel_color_red
    add_column :color_palettes, :pixel_color_blue, :integer, limit: 3, after: :pixel_color_green
    add_column :color_palettes, :pixel_color_hue, :decimal, :after => :pixel_color_blue
    add_column :color_palettes, :pixel_color_saturation, :decimal, :after => :pixel_color_hue
    add_column :color_palettes, :pixel_color_value, :integer, :decimal => :pixel_color_saturation
  end

end