require 'spec_helper'

feature 'Users', %q{
In order to using app
As an user
I want to see other users
} do


  context 'As an admin' do

    before do
      User.create!(username: 'admin', email: 'admin@gmail,com', password: '1', admin: true)
      User.create!(username: 'duong', email: 'duong@gmail,com', password: '1', admin: false)
      logged_as_admin
      visit root_path
    end


    scenario 'See all users in system' do
      expect(page).to have_content 'duong'
      expect(page).to have_content 'admin'
      expect(page).to have_content 'New User'
    end

    scenario 'Add new user' do
      click_link('New User')

      fill_in 'user[username]', with: 'ngoc'
      fill_in 'user[email]', with: 'ngoc@yahoo.com'
      fill_in 'user[password]', with: '1'

      click_button 'Create User'

      expect(page).to have_content 'User Details'
      expect(page).to have_content 'ngoc'
      expect(page).to have_content 'ngoc@yahoo.com'
      expect(page).to have_content 'Is admin? No'

      expect(page).to have_link 'Back to all users'
    end

  end
end


