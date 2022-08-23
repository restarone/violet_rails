# frozen_string_literal: true

class Comfy::Admin::Cms::CategoriesController < Comfy::Admin::Cms::BaseController

  before_action :load_category, only: %i[edit update destroy]
  before_action :authorize

  def edit
    render
  end

  def create
    @category = if Comfy::Cms::Category::NON_SITE_ENTITIES.include?(category_params[:categorized_type])
      Comfy::Cms::Category.create!(category_params)
    else
      @site.categories.create!(category_params)
    end
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def create_for_non_site_entities
    @category = Comfy::Cms::Category.create!(category_params)
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def update
    @category.update!(category_params)
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def destroy
    @category.destroy
  end

protected

  def load_category
    @category = if Comfy::Cms::Category::NON_SITE_ENTITIES.include?(category_params[:categorized_type])
      Comfy::Cms::Category.of_type(category_params[:categorized_type]).find(params[:id])
    else
      @site.categories.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    head :ok
  end

  def category_params
    params.require(:category).permit(:site_id, :label, :categorized_type)
  end

end
  