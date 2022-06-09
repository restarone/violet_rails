class AddShowRecaptchaV3ToApiForms < ActiveRecord::Migration[6.1]
  def change
    add_column :api_forms, :show_recaptcha_v3, :boolean, default: false
  end
end
