def page_module_for_step(step)
  case step.to_sym
    when :evaulate
      IsTheInternet::Page::Evaulate
    when :parse
      IsTheInternet::Page::Parse
    when :screenshot
      IsTheInternet::Page::Screenshot
    when :scrape
      IsTheInternet::Page::Scrape
    else
      nil
  end
end


def page_module_attrs_for_step(step,i)
  case step
    # when :evaluate
    #   {}
    # when :parse
    #   {}
    when :screenshot
      {:display => i}
    # when :scrape
    #   {}
    else
      {}
  end
end