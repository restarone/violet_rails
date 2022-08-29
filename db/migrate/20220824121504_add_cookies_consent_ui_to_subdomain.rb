class AddCookiesConsentUiToSubdomain < ActiveRecord::Migration[6.1]
  COOKIE_CONSENT_UI = 
  "<div class=\"cookies-consent__overlay position-fixed\" style=\"top: 0; bottom: 0; left: 0; right: 0; background-color: black; opacity: 0.5; z-index: 1000;\"></div>
  <div class=\"cookies-consent position-fixed bg-white d-md-flex justify-content-md-between\" style=\"bottom: 0; left: 0; width: 100%; padding: 2rem 1rem; z-index: 9000;\">
    <div class=\"cookies-consent__text-content col-md-8\" style=\"max-width: 700px;\">
      <h2 class=\"cookies-consent__title\" style=\"font-size: 1.4rem;\">We Value Your Privacy</h2>
      <p class=\"mb-4 mb-md-0\">
        We use cookies to enhance your browsing experience, serve personalized ads or content, and analyze our traffic. By clicking \"Accept All\", you consent to our use of cookies.
      </p>
    </div>
    <div class=\"cookies-consent__buttons-container d-flex flex-column col-md-4 col-xl-3\">
      <a class=\"btn btn-primary mb-3\" href=\"/cookies?cookies=true\">Accept All</a>
      <a class=\"btn btn-outline-primary\" href=\"/cookies?cookies=false\">Reject All</a>
    </div>  
  </div>"

  def change
    add_column :subdomains, :cookies_consent_ui, :text, default: COOKIE_CONSENT_UI
  end
end
