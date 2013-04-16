class WebPage < ActiveRecord::Base

  self.per_page = 50


  belongs_to :web_site





protected


end