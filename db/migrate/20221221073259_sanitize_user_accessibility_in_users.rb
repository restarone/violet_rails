class SanitizeUserAccessibilityInUsers < ActiveRecord::Migration[6.1]
  def up
    User.all.each do |user|
      if user.api_accessibility['api_namespaces'].present?
        old_api_accessibility = user.api_accessibility
        new_api_accessibility = {'api_namespaces' => old_api_accessibility}

        user.update!(api_accessibility: new_api_accessibility)
      end
    end
  end

  def down
    User.all.each do |user|
      if user.api_accessibility['api_namespaces'].present?
        user.update!(api_accessibility: user.api_accessibility['api_namespaces'])
      end
    end
  end
end
