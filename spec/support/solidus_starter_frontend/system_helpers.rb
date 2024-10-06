module SystemHelpers
  def checkout_as_guest
    click_button "Checkout"

    within '#guest_checkout' do
      fill_in 'Email', with: 'test@example.com'
    end

    click_on 'Continue'
  end
end
