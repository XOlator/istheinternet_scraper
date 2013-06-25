class CreateColorPalettes < ActiveRecord::Migration

  def change
    create_table :color_palettes do |t|
      t.integer       :web_page_id

      t.string        :dominant_color
      t.string        :dominant_color_hex,    :limit => 6
      t.integer       :dominant_color_red,    :length => 3
      t.integer       :dominant_color_green,  :length => 3
      t.integer       :dominant_color_blue,    :length => 3

      t.string        :color_palette

      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :color_palettes, [:web_page_id], :unique => true
  end

end