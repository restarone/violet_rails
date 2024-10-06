# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.feature 'Sign Out', type: :system, js: true do
  given!(:user) do
   create(:user,
          email: 'email@person.com',
          password: 'secret',
          password_confirmation: 'secret')
  end

  background do
    visit login_path
    fill_in 'Email', with: user.email
    fill_in 'Password:', with: user.password
    # Regression test for #1257
    check 'Remember me'
    click_button 'Login'
  end

  scenario 'allow a signed in user to logout' do
    click_link 'My Account'
    click_button 'Logout'
    visit root_path
    expect(page).to have_text 'LOGIN'
    expect(page).not_to have_text 'LOGOUT'
  end
end
