# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_11_04_133642) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "api_actions", force: :cascade do |t|
    t.string "type"
    t.integer "action_type", default: 0
    t.boolean "include_api_resource_data"
    t.jsonb "payload_mapping"
    t.string "redirect_url"
    t.string "request_url"
    t.integer "position"
    t.string "email"
    t.string "file_snippet"
    t.string "encrypted_bearer_token"
    t.string "lifecycle_message"
    t.integer "lifecycle_stage", default: 0
    t.binary "salt"
    t.bigint "api_namespace_id"
    t.bigint "api_resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "custom_headers"
    t.string "http_method"
    t.text "method_definition", default: "raise StandardError"
    t.text "email_subject"
    t.integer "redirect_type", default: 0
    t.index ["api_namespace_id"], name: "index_api_actions_on_api_namespace_id"
    t.index ["api_resource_id"], name: "index_api_actions_on_api_resource_id"
  end

  create_table "api_clients", force: :cascade do |t|
    t.bigint "api_namespace_id", null: false
    t.string "slug", null: false
    t.string "label", default: "customer_identifier_here", null: false
    t.string "authentication_strategy", default: "bearer_token", null: false
    t.string "bearer_token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["api_namespace_id"], name: "index_api_clients_on_api_namespace_id"
    t.index ["bearer_token"], name: "index_api_clients_on_bearer_token"
  end

  create_table "api_forms", force: :cascade do |t|
    t.jsonb "properties"
    t.bigint "api_namespace_id", null: false
    t.text "success_message"
    t.text "failure_message"
    t.string "submit_button_label", default: "Submit"
    t.string "title"
    t.boolean "show_recaptcha", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "show_recaptcha_v3", default: false
    t.index ["api_namespace_id"], name: "index_api_forms_on_api_namespace_id"
  end

  create_table "api_namespaces", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "version", null: false
    t.jsonb "properties"
    t.boolean "requires_authentication", default: false
    t.string "namespace_type", default: "create-read-update-delete", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "social_share_metadata"
    t.index ["properties"], name: "index_api_namespaces_on_properties", opclass: :jsonb_path_ops, using: :gin
  end

  create_table "api_resources", force: :cascade do |t|
    t.bigint "api_namespace_id", null: false
    t.jsonb "properties"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["api_namespace_id"], name: "index_api_resources_on_api_namespace_id"
    t.index ["properties"], name: "index_api_resources_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_api_resources_on_user_id"
  end

  create_table "comfy_blog_posts", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.integer "layout_id"
    t.text "content_cache"
    t.integer "year", null: false
    t.integer "month", limit: 2, null: false
    t.boolean "is_published", default: true, null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_comfy_blog_posts_on_created_at"
    t.index ["site_id", "is_published"], name: "index_comfy_blog_posts_on_site_id_and_is_published"
    t.index ["year", "month", "slug"], name: "index_comfy_blog_posts_on_year_and_month_and_slug"
  end

  create_table "comfy_cms_categories", force: :cascade do |t|
    t.integer "site_id"
    t.string "label", null: false
    t.string "categorized_type", null: false
    t.index ["site_id", "categorized_type", "label"], name: "index_cms_categories_on_site_id_and_cat_type_and_label", unique: true
  end

  create_table "comfy_cms_categorizations", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "categorized_type", null: false
    t.integer "categorized_id", null: false
    t.index ["category_id", "categorized_type", "categorized_id"], name: "index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id", unique: true
  end

  create_table "comfy_cms_files", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", default: "", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "position"], name: "index_comfy_cms_files_on_site_id_and_position"
  end

  create_table "comfy_cms_fragments", force: :cascade do |t|
    t.string "record_type"
    t.bigint "record_id"
    t.string "identifier", null: false
    t.string "tag", default: "text", null: false
    t.text "content"
    t.boolean "boolean", default: false, null: false
    t.datetime "datetime"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["boolean"], name: "index_comfy_cms_fragments_on_boolean"
    t.index ["datetime"], name: "index_comfy_cms_fragments_on_datetime"
    t.index ["identifier"], name: "index_comfy_cms_fragments_on_identifier"
    t.index ["record_type", "record_id"], name: "index_comfy_cms_fragments_on_record"
  end

  create_table "comfy_cms_layouts", force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "parent_id"
    t.string "app_layout"
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.text "css"
    t.text "js"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "position"], name: "index_comfy_cms_layouts_on_parent_id_and_position"
    t.index ["site_id", "identifier"], name: "index_comfy_cms_layouts_on_site_id_and_identifier", unique: true
  end

  create_table "comfy_cms_pages", force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "layout_id"
    t.integer "parent_id"
    t.integer "target_page_id"
    t.string "label", null: false
    t.string "slug"
    t.string "full_path", null: false
    t.text "content_cache"
    t.integer "position", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_restricted", default: false
    t.text "preview_content"
    t.index ["is_published"], name: "index_comfy_cms_pages_on_is_published"
    t.index ["parent_id", "position"], name: "index_comfy_cms_pages_on_parent_id_and_position"
    t.index ["site_id", "full_path"], name: "index_comfy_cms_pages_on_site_id_and_full_path"
  end

  create_table "comfy_cms_revisions", force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.index ["record_type", "record_id", "created_at"], name: "index_cms_revisions_on_rtype_and_rid_and_created_at"
  end

  create_table "comfy_cms_sites", force: :cascade do |t|
    t.string "label", null: false
    t.string "identifier", null: false
    t.string "hostname", null: false
    t.string "path"
    t.string "locale", default: "en", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hostname"], name: "index_comfy_cms_sites_on_hostname"
  end

  create_table "comfy_cms_snippets", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "identifier"], name: "index_comfy_cms_snippets_on_site_id_and_identifier", unique: true
    t.index ["site_id", "position"], name: "index_comfy_cms_snippets_on_site_id_and_position"
  end

  create_table "comfy_cms_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.integer "page_id", null: false
    t.integer "layout_id"
    t.string "label", null: false
    t.text "content_cache"
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_published"], name: "index_comfy_cms_translations_on_is_published"
    t.index ["locale"], name: "index_comfy_cms_translations_on_locale"
    t.index ["page_id"], name: "index_comfy_cms_translations_on_page_id"
  end

  create_table "external_api_clients", force: :cascade do |t|
    t.bigint "api_namespace_id", null: false
    t.string "slug", null: false
    t.string "label", default: "data_source_identifier_here", null: false
    t.string "status", default: "stopped", null: false
    t.boolean "enabled", default: false
    t.string "error_message"
    t.string "drive_strategy", default: "on_demand", null: false
    t.integer "max_requests_per_minute", default: 0, null: false
    t.integer "current_requests_per_minute", default: 0, null: false
    t.integer "max_workers", default: 0, null: false
    t.integer "current_workers", default: 0, null: false
    t.integer "retry_in_seconds", default: 0, null: false
    t.integer "max_retries", default: 1, null: false
    t.integer "retries", default: 0, null: false
    t.text "model_definition", default: "raise StandardError"
    t.jsonb "state_metadata"
    t.jsonb "error_metadata"
    t.jsonb "metadata"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "drive_every"
    t.datetime "last_run_at"
    t.index ["api_namespace_id"], name: "index_external_api_clients_on_api_namespace_id"
  end

  create_table "forum_categories", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "color", default: "000000"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_posts", id: :serial, force: :cascade do |t|
    t.integer "forum_thread_id"
    t.integer "user_id"
    t.text "body"
    t.boolean "solved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "forum_thread_id"
    t.integer "user_id"
    t.string "subscription_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_threads", id: :serial, force: :cascade do |t|
    t.integer "forum_category_id"
    t.integer "user_id"
    t.string "title", null: false
    t.string "slug", null: false
    t.integer "forum_posts_count", default: 0
    t.boolean "pinned", default: false
    t.boolean "solved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "mailboxes", force: :cascade do |t|
    t.boolean "unread", default: false
    t.boolean "enabled", default: false
    t.integer "threads_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "message_threads", force: :cascade do |t|
    t.boolean "unread"
    t.datetime "deleted_at"
    t.string "subject"
    t.string "recipients", default: [], array: true
    t.string "current_email_message_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["current_email_message_id"], name: "index_message_threads_on_current_email_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "from"
    t.bigint "message_thread_id", null: false
    t.string "email_message_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email_message_id"], name: "index_messages_on_email_message_id"
    t.index ["message_thread_id"], name: "index_messages_on_message_thread_id"
  end

  create_table "non_primitive_properties", force: :cascade do |t|
    t.string "label"
    t.integer "field_type", default: 0
    t.bigint "api_resource_id"
    t.bigint "api_namespace_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "allow_attachments", default: false
    t.index ["api_namespace_id"], name: "index_non_primitive_properties_on_api_namespace_id"
    t.index ["api_resource_id"], name: "index_non_primitive_properties_on_api_resource_id"
  end

  create_table "subdomain_requests", force: :cascade do |t|
    t.string "subdomain_name"
    t.string "email"
    t.boolean "approved", default: false
    t.boolean "requires_web", default: true
    t.boolean "requires_blog", default: true
    t.boolean "requires_forum", default: true
    t.datetime "deleted_at"
    t.string "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["deleted_at"], name: "index_subdomain_requests_on_deleted_at"
    t.index ["email"], name: "index_subdomain_requests_on_email"
    t.index ["slug"], name: "index_subdomain_requests_on_slug"
    t.index ["subdomain_name"], name: "index_subdomain_requests_on_subdomain_name"
  end

  create_table "subdomains", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "html_title"
    t.string "blog_title"
    t.string "blog_html_title"
    t.string "forum_title"
    t.string "forum_html_title"
    t.string "description"
    t.string "keywords"
    t.boolean "forum_enabled", default: true
    t.boolean "blog_enabled", default: true
    t.boolean "allow_user_self_signup", default: true
    t.boolean "forum_is_private", default: false
    t.string "purge_visits_every", default: "never"
    t.string "analytics_report_frequency", default: "never"
    t.datetime "analytics_report_last_sent"
    t.boolean "tracking_enabled", default: false
    t.boolean "ember_enabled", default: false
    t.boolean "graphql_enabled", default: false
    t.boolean "web_console_enabled", default: false
    t.boolean "api_plugin_events_enabled", default: false
    t.string "after_sign_up_path"
    t.string "after_sign_in_path"
    t.boolean "allow_external_analytics_query", default: false
    t.string "email_name"
    t.text "email_signature"
    t.text "cookies_consent_ui", default: "<div class=\"cookies-consent__overlay position-fixed\" style=\"top: 0; bottom: 0; left: 0; right: 0; background-color: black; opacity: 0.5; z-index: 1000;\"></div>\n  <div class=\"cookies-consent position-fixed bg-white d-md-flex justify-content-md-between\" style=\"bottom: 0; left: 0; width: 100%; padding: 2rem 1rem; z-index: 9000;\">\n    <div class=\"cookies-consent__text-content col-md-8\" style=\"max-width: 700px;\">\n      <h2 class=\"cookies-consent__title\" style=\"font-size: 1.4rem;\">We Value Your Privacy</h2>\n      <p class=\"mb-4 mb-md-0\">\n        We use cookies to enhance your browsing experience, serve personalized ads or content, and analyze our traffic. By clicking \"Accept All\", you consent to our use of cookies.\n      </p>\n    </div>\n    <div class=\"cookies-consent__buttons-container d-flex flex-column col-md-4 col-xl-3\">\n      <a class=\"btn btn-primary mb-3\" href=\"/cookies?cookies=true\">Accept All</a>\n      <a class=\"btn btn-outline-primary\" href=\"/cookies?cookies=false\">Reject All</a>\n    </div>  \n  </div>"
    t.boolean "enable_2fa", default: false
    t.string "email_notification_strategy", default: "user_email"
    t.index ["deleted_at"], name: "index_subdomains_on_deleted_at"
    t.index ["name"], name: "index_subdomains_on_name"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "global_admin", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "can_manage_web", default: false
    t.boolean "can_manage_email", default: false
    t.boolean "can_manage_users", default: false
    t.boolean "can_manage_blog", default: false
    t.string "name"
    t.boolean "moderator"
    t.boolean "can_view_restricted_pages"
    t.boolean "deliver_analytics_report", default: false
    t.boolean "can_manage_api", default: false
    t.boolean "can_manage_subdomain_settings", default: false
    t.string "session_timeoutable_in", default: "1-hour"
    t.boolean "can_access_admin", default: false
    t.boolean "deliver_error_notifications", default: false
    t.boolean "can_manage_analytics", default: false
    t.boolean "can_manage_files", default: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_actions", "api_namespaces"
  add_foreign_key "api_actions", "api_resources"
  add_foreign_key "api_clients", "api_namespaces"
  add_foreign_key "api_forms", "api_namespaces"
  add_foreign_key "api_resources", "api_namespaces"
  add_foreign_key "external_api_clients", "api_namespaces"
  add_foreign_key "forum_posts", "forum_threads"
  add_foreign_key "forum_posts", "users"
  add_foreign_key "forum_subscriptions", "forum_threads"
  add_foreign_key "forum_subscriptions", "users"
  add_foreign_key "forum_threads", "forum_categories"
  add_foreign_key "forum_threads", "users"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "non_primitive_properties", "api_namespaces"
  add_foreign_key "non_primitive_properties", "api_resources"
end
