class AddCustomizableColumnsToCallToAction < ActiveRecord::Migration[6.1]
  def change
    change_table :call_to_actions do |t|
      t.string :success_message, default: "Thank you for your inquiry!"
      t.string :failure_message, default: "Some fields were invalid, please double check the recapcha and try again"
      t.string :name_label, default: "Name"
      t.string :name_placeholder, default: "John AppleSeed"
      t.string :email_label, default: "Email Address"
      t.string :email_placeholder, default: "john@apple.seed"
      t.string :phone_placeholder, default: "+1123456789"
      t.string :phone_label, default: "Phone Number"
      t.string :message_label, default: "Message"
      t.string :message_placeholder, default: "Your message here"
    end
  end
end
