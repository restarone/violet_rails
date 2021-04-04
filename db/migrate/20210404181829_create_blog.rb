class CreateBlog < ActiveRecord::Migration[5.2]

  LIMIT = 16777215

  def change
    create_table :comfy_blog_posts do |t|
      t.integer   :site_id,       null: false
      t.string    :title,         null: false
      t.string    :slug,          null: false
      t.integer   :layout_id
      t.text      :content_cache, limit: LIMIT
      t.integer   :year,          null: false, limit: 4
      t.integer   :month,         null: false, limit: 2
      t.boolean   :is_published,  null: false, default: true
      t.datetime  :published_at,  null: false
      t.timestamps

      t.index [:site_id, :is_published]
      t.index [:year, :month, :slug]
      t.index [:created_at]
    end

  end
end
