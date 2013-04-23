class PageQueue < ActiveRecord::Base

  self.per_page = 50

  STEPS = [:scrape, :parse, :screenshot, :evaulate]

  RETRY_INTERVAL = 15.minutes
  MAX_RETRY_COUNT = 10


  # --- Associations ----------------------------------------------------------

  belongs_to :web_page


  # --- Validations -----------------------------------------------------------


  # --- Scopes ----------------------------------------------------------------

  # Generate scopes for each step, require previous step in example
  PageQueue::STEPS.each_with_index do |v,i|
    opts = {}
    PageQueue::STEPS.each_with_index {|vv,ii| (opts)[vv] = (i > ii)}
    scope v, where(opts)
  end

  # Work priority first, by first added at. Skip if pending for a retry or locked
  default_scope lambda { where(:locked => false).where("retry_at IS NULL OR retry_at < ?", Time.now).order('priority DESC, created_at ASC') }


  # --- Methods ---------------------------------------------------------------

  def lock!; self.update_attributes(:locked => true, :locked_at => Time.now); end
  def unlock!; self.update_attributes(:locked => false, :locked_at => nil); end

  def step!(s)
    if PageQueue::STEPS.index(s) == PageQueue::STEPS.last # If completed, then destroy
      self.destroy
    else
      self.update_attribute(s, true)
    end
  end

  def retry!
    if self.error_count >= PageQueue::MAX_RETRY_COUNT
      self.destroy
    else
      self.error_count += 1
      self.retry_at = Time.now + (PageQueue::RETRY_INTERVAL * self.error_count)
    end
  end


protected



end