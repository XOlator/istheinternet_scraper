class ColorPalette < ActiveRecord::Base


  # --- Associations ----------------------------------------------------------

  belongs_to :web_page

  serialize :pixel_color,     Array
  serialize :dominant_color,  Array
  serialize :color_palette


  # --- Validations -----------------------------------------------------------

  before_save :convert_rgb_to_hsl

  validates :pixel_color_red,       presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}
  validates :pixel_color_green,     presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}
  validates :pixel_color_blue,      presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}
  validates :dominant_color_red,    presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}
  validates :dominant_color_green,  presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}
  validates :dominant_color_blue,   presence: true, numericality: {greater_than_or_equal_to: 0, less_than: 256}


  # --- Scopes ----------------------------------------------------------------

  scope :has_pixel_color, where("(pixel_color_red != '' AND pixel_color_red IS NOT NULL) AND (pixel_color_green != '' AND pixel_color_green IS NOT NULL) AND (pixel_color_blue != '' AND pixel_color_blue IS NOT NULL)")


  # --- Methods ---------------------------------------------------------------

  def self.color_avg(v); where("#{v} != '' AND #{v} IS NOT NULL").average(v); end

  def self.pixel_hex_color
    ("%02x%02x%02x" % [color_avg(:pixel_color_red), color_avg(:pixel_color_green), color_avg(:pixel_color_blue)]).upcase
  end

  def self.dominant_hex_color
    ("%02x%02x%02x" % [color_avg(:dominant_color_red), color_avg(:dominant_color_green), color_avg(:dominant_color_blue)]).upcase
  end

  def self.hsl_hex_color
    h,s,l = color_avg(:pixel_color_hue), color_avg(:pixel_color_saturation), color_avg(:pixel_color_value)
    # h,s,l = color_avg(:dominant_color_hue), color_avg(:dominant_color_saturation), color_avg(:dominant_color_value)
    # puts h,s,l
    # rgb = Color::HSL.from_fraction(h,s,l).to_rgb
    # rgb.html.gsub(/\#/, '').upcase
  end

  def pixel_hex_color
    ("%02x%02x%02x" % [self.pixel_color_red, self.pixel_color_green, self.pixel_color_blue]).upcase
  end

  def convert_rgb_to_hsl
    begin
      rgb = Color::RGB.new(self.pixel_color_red,self.pixel_color_green,self.pixel_color_blue)
      hsl = rgb.to_hsl
      self.pixel_color_hue = hsl.h
      self.pixel_color_saturation = hsl.s
      self.pixel_color_value = hsl.l
    rescue => err
      _debug("HSL Pixel Error: #{err}", 1, self)
    end

    begin
      rgb = Color::RGB.new(self.dominant_color_red,self.dominant_color_green,self.dominant_color_blue)
      hsl = rgb.to_hsl
      self.dominant_color_hue = hsl.h
      self.dominant_color_saturation = hsl.s
      self.dominant_color_value = hsl.l
    rescue => err
      _debug("HSL Dominant Error: #{err}", 1, self)
    end
  end


protected


end