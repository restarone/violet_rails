module ContentHelper
  def login_helper(if_identifier, else_identifier = nil)
    if current_user
        cms_snippet_render(if_identifier)
    elsif identifier_2
        cms_snippet_render(else_identifier)
    end
  end
end
