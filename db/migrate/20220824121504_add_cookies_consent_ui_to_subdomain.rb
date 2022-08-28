class AddCookiesConsentUiToSubdomain < ActiveRecord::Migration[6.1]
  COOKIE_CONSENT_UI = 
  "<div class=\"cookies-consent\">
    <div class=\"cookies-consent__text-content\">
      <h2 class=\"cookies-consent__title\">We Value Your Privacy</h2>
      <p class=\"mb-4 mb-md-0\">
        We use cookies to enhance your browsing experience, serve personalized ads or content, and analyze our traffic. By clicking \"Accept All\", you consent to our use of cookies.
      </p>
    </div>
    <div class=\"cookies-consent__buttons-container\">
      <a class=\"btn btn-primary mb-3\" href=\"/cookies?cookies=true\">Accept All</a>
      <a class=\"btn btn-outline-primary\" href=\"/cookies?cookies=false\">Reject All</a>
    </div>  
  </div>"

  def change
    add_column :subdomains, :cookies_consent_ui, :text, default: COOKIE_CONSENT_UI
  end
end
