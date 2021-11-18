class MigrateCallToActionsToApi < ActiveRecord::Migration[6.1]
  def change
    files = Dir[Rails.root + 'app/models/*.rb']
    models = files.map{ |m| File.basename(m, '.rb').camelize }

    if models.include?("CallToAction")
      CallToAction.where(cta_type: 'contact-us').each do |cta|
      p 'Creating api namespace'

      params = {
          name: 'inquiries',
          requires_authentication: false,
          version: 1,
          properties: {
              "name": cta.name_placeholder,
              "email": cta.email_placeholder,
              "phone_number": cta.phone_placeholder,
              "message": cta.message_placeholder
          }.to_json
      }

      p 'Creating api form'
      api_namespace = ApiNamespace.create(params)
      api_form_params =  { 
          properties: { 
              "name": {
                  "label": cta.name_label,
                  "pattern": "",
                  "required": "0",
                  "field_type": "input",
                  "prepopulate": "0",
                  "type_validation": "free text"
              },
              "email": {
                  "label": cta.email_label,
                  "pattern": "",
                  "required": "1",
                  "field_type": "input",
                  "prepopulate": "0",
                  "type_validation": "email"
                },
              "message": {
                  "label": cta.message_label,
                  "pattern": "",
                  "required": "1",
                  "field_type": "textarea",
                  "prepopulate": "0",
                  "type_validation": "free text"
              },
              "phone_number": {
                  "label": cta.phone_label,
                  "pattern": "",
                  "required": "0",
                  "field_type": "input",
                  "prepopulate": "0",
                  "type_validation": "number"
              }
          },
          api_namespace_id: api_namespace.id,
          success_message: cta.success_message,
          failure_message: cta.failure_message,
          submit_button_label: cta.submit_button_label,
          title: cta.title,
          show_recaptcha: false,
      }

      ApiForm.create(api_form_params)

      p 'creating api resources'

      cta.call_to_action_responses.each do |cta_response|
          cta_response_params = {
                  api_namespace_id: api_namespace.id,
                  properties: cta_response.properties,
                  created_at: cta_response.created_at,
                  updated_at: cta_response.updated_at
              }

          api_resource =  ApiResource.create(cta_response_params)
      end
      end

      CallToAction.where(cta_type: 'collect-email').each do |cta|
      p 'Creating api namespace'

      params = {
          name: 'emails',
          requires_authentication: false,
          version: 1,
          properties: {
              "email": cta.email_placeholder
          }.to_json
      }

      p 'Creating api form'
      api_namespace = ApiNamespace.create(params)
      api_form_params =  { 
          properties: { 
              "email": {
                  "label": cta.email_label,
                  "pattern": "",
                  "required": "1",
                  "field_type": "input",
                  "prepopulate": "0",
                  "type_validation": "email"
                }
          },
          api_namespace_id: api_namespace.id,
          success_message: cta.success_message,
          failure_message: cta.failure_message,
          submit_button_label: cta.submit_button_label,
          title: cta.title,
          show_recaptcha: false,
      }

      ApiForm.create(api_form_params)

      p 'creating api resources'

      cta.call_to_action_responses.each do |cta_response|
          cta_response_params = {
                  api_namespace_id: api_namespace.id,
                  properties: cta_response.properties,
                  created_at: cta_response.created_at,
                  updated_at: cta_response.updated_at
              }

          api_resource =  ApiResource.create(cta_response_params)
      end
      end
    end

  end
end
