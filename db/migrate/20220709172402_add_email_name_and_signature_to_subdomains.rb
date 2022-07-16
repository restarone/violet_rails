class AddEmailNameAndSignatureToSubdomains < ActiveRecord::Migration[6.1]
  def change
    add_column :subdomains, :email_name, :string
    add_column :subdomains, :email_signature, :text
  end
end
