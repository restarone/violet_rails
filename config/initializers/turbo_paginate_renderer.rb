class TurboPaginateRenderer < WillPaginate::ActionView::LinkRenderer
  def previous_or_next_page(page, text, classname)
    if page
      link(text, page, :class => classname, "data-turbo" => true, "data-turbo-action" => "advance")
    else
      tag(:span, text, :class => classname + ' disabled')
    end
  end
end