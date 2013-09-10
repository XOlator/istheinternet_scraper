class ColorPalette < ActiveRecord::Base


  # --- Associations ----------------------------------------------------------

  belongs_to :web_page

  serialize :dominant_color, Array
  serialize :color_palette


  # --- Validations -----------------------------------------------------------

  before_save :convert_rgb_to_hsl

  validates :dominant_color_red,    :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}
  validates :dominant_color_green,  :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}
  validates :dominant_color_blue,   :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}


  # --- Scopes ----------------------------------------------------------------


  # --- Methods ---------------------------------------------------------------

  def self.hex_color
    "%02x%02x%02x" % [average(:dominant_color_red), average(:dominant_color_green), average(:dominant_color_blue)]
  end

  def self.hsl_hex_color
    h,s,l = average(:dominant_color_hue), average(:dominant_color_saturation), average(:dominant_color_value)
    rgb = Color::HSL.from_fraction(h,s,l).to_rgb
    rgb.html.gsub(/\#/, '')
  end

  def convert_rgb_to_hsl
    rgb = Color::RGB.new(self.dominant_color_red,self.dominant_color_green,self.dominant_color_blue)
    hsl = rgb.to_hsl
    self.dominant_color_hue = hsl.h
    self.dominant_color_saturation = hsl.s
    self.dominant_color_value = hsl.l
  end

protected


end