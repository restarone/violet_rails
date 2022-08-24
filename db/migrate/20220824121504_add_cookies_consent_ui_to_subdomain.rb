class AddCookiesConsentUiToSubdomain < ActiveRecord::Migration[6.1]
  COOKIE_CONSENT_UI = 
  "<div class=\"py-2 px-3 bg-white w-100 position-fixed\" style=\"bottom: 0; box-shadow: 1px 7px 14px 5px rgb(0 0 0 / 15%); z-index: 9000;\">
    By using our website, you agree to use the cookies.
    <a href=\"/cookies?cookies=true\">Accept</a>
    <a href=\"/cookies?cookies=false\">Reject</a>
  </div>"

  def change
    add_column :subdomains, :cookies_consent_ui, :text, default: COOKIE_CONSENT_UI
  end
end
