class ColorPalette < ActiveRecord::Base


  # --- Associations ----------------------------------------------------------

  belongs_to :web_page

  serialize :dominant_color, Array
  serialize :color_palette


  # --- Validations -----------------------------------------------------------

  validates :dominant_color_red,    :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}
  validates :dominant_color_green,  :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}
  validates :dominant_color_blue,   :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 256}


  # --- Scopes ----------------------------------------------------------------


  # --- Methods ---------------------------------------------------------------



protected



end