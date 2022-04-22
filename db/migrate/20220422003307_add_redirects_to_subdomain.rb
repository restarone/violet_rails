class AddRedirectsToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      # to use a URL first redirect to a CMS page and then use JS to redirect to the external site
      t.string :after_sign_up_path, default: nil
      t.string :after_sign_in_path, default: nil
    end
  end
end
