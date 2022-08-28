class AddCookiesConsentUiToSubdomain < ActiveRecord::Migration[6.1]
  COOKIE_CONSENT_UI = 
  "<div class=\"cookies-consent\">
    <h2 class=\"cookies-consent__title\">We Value Your Privacy</h2>
    <p>
      We use cookies to enhance your browsing experience, serve personalized ads or content, and analyze our traffic. By clicking \"Accept All\", you consent to our use of cookies.
    </p>
    <a class=\"btn btn-primary mr-2 mb-2 mb-sm-0\" href=\"/cookies?cookies=true\">Accept All</a>
    <a class=\"btn btn-outline-primary mb-2 mb-sm-0\" href=\"/cookies?cookies=false\">Reject All</a>
  </div>"

  def change
    add_column :subdomains, :cookies_consent_ui, :text, default: COOKIE_CONSENT_UI
  end
end
