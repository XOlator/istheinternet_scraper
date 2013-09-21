class AddHsvToColorPalettes < ActiveRecord::Migration

  def up
    add_column :color_palettes, :dominant_color_hue, :decimal, :after => :dominant_color_blue
    add_column :color_palettes, :dominant_color_saturation, :decimal, :after => :dominant_color_hue
    add_column :color_palettes, :dominant_color_value, :integer, :decimal => :dominant_color_saturation

    ColorPalette.all.each do |c|
      next if c.dominant_color_hue.present?
      c.convert_rgb_to_hsl
      c.save
    end

    # puts ColorPalette.hex_color.inspect
    # puts ColorPalette.hsl_hex_color.inspect
  end

  def down
    remove_column :color_palettes, :dominant_color_hue
    remove_column :color_palettes, :dominant_color_saturation
    remove_column :color_palettes, :dominant_color_value
  end

end