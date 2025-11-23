class SalesAsset < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  validates :name, presence: true
  validates :width, presence: true
  validates :height, presence: true
  validates :html, presence: true

  def render
    binary_output = nil

    Puppeteer.launch(headless: true, args: ['--no-sandbox', '--headless', '--disable-gpu', '--disable-dev-shm-usage']) do |browser|
      page = browser.new_page
      page.set_content(self.html)
      dimensions = page.evaluate(<<~JAVASCRIPT)
      () => {
        return {
          width: document.documentElement.scrollWidth,
          height: document.documentElement.scrollHeight,
          deviceScaleFactor: window.devicePixelRatio
        };
      }
      JAVASCRIPT
      width = self.width
      height = self.height

      page.viewport = Puppeteer::Viewport.new(width: width, height: height)
      screenshot_settings = {
        type: 'jpeg',
        quality: ENV["PUPPETEER_SCREENSHOT_QUALITY"] ? ENV["PUPPETEER_SCREENSHOT_QUALITY"].to_i : 100
      }
      screenshot = page.screenshot(**screenshot_settings)
      binary_output = screenshot
      browser.close
    end

    return binary_output
  end
end
