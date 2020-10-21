module Navigations
  class DashboardPageNavigation < ApplicationPage
    LOGOUT_BUTTON = "#nav-more-logout"
    MANAGE_OPTION = {xpath: "//li/div/a"}.freeze
    MAIN_MENU_TABS = {css: "ul.mr-auto>li>a"}.freeze
    PROFILE_DROPDOWN = "#nav-more-link"

    def click_main_menu_tab(option)
      find(MAIN_MENU_TABS[:css], text: option).click
    end

    def validate_owners_home_page
      main_menu_tabs = all_elements(MAIN_MENU_TABS)
      main_menu_tabs.each(&:visible?)
    end

    def select_manage_option(option)
      find("#nav-more-link").click
      find(option).click
    end

    def click_logout_button
      find(PROFILE_DROPDOWN).click
      find(LOGOUT_BUTTON).click
    end
  end
end
