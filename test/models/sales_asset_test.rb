require "test_helper"

class SalesAssetTest < ActiveSupport::TestCase
  def setup
    @sales_asset = SalesAsset.new(
      name: "Test Sales Asset",
      width: 800,
      height: 600,
      html: "<div><h1>Test Content</h1></div>"
    )
  end

  test "should be valid with all attributes" do
    assert @sales_asset.valid?
  end

  test "should validate presence of name" do
    @sales_asset.name = nil
    assert_not @sales_asset.valid?
    assert_includes @sales_asset.errors[:name], "can't be blank"
  end

  test "should validate presence of width" do
    @sales_asset.width = nil
    assert_not @sales_asset.valid?
    assert_includes @sales_asset.errors[:width], "can't be blank"
  end

  test "should validate presence of height" do
    @sales_asset.height = nil
    assert_not @sales_asset.valid?
    assert_includes @sales_asset.errors[:height], "can't be blank"
  end

  test "should validate presence of html" do
    @sales_asset.html = nil
    assert_not @sales_asset.valid?
    assert_includes @sales_asset.errors[:html], "can't be blank"
  end

  test "should generate friendly slug from name" do
    @sales_asset.save!
    assert_equal "test-sales-asset", @sales_asset.slug
  end

  test "should have render method" do
    assert_respond_to @sales_asset, :render
  end
end
