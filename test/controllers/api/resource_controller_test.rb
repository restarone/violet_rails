require "test_helper"

class Api::ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = Subdomain.current
    @api_namespace = api_namespaces(:one)
    @users_namespace = api_namespaces(:users)

    @api_resource_1 = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { 
        name: 'John Doe',
        age: 35,
        interests: ['software', 'web', 'games'],
        object: { foo: 'bar', baz: { a: 'b' } }
      })

    @api_resource_2 = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { 
        name: 'Jack D',
        age: 90,
        interests: ['movies'],
        object: { x: 'y', z: 'a'}
      })

    @api_resource_3 = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { 
        name: 'John Cena',
        age: 50,
        interests: ['random', 'text'],
        object: {}
      })
  end

  test 'describe resource name and version: get #index as json with no ahoy-visit being tracked when tracking is disabled' do
    @subdomain.update(tracking_enabled: false)
    assert_no_difference "Ahoy::Visit.count" do
      get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), as: :json
    end
    assert_response :success
  end

  test 'describe resource name and version: get #index with no ahoy-visit being tracked when tracking is enabled but cookie consent is rejected' do
    @subdomain.update(tracking_enabled: true)
    assert_no_difference "Ahoy::Visit.count" do
      get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
    end
    assert_response :success
  end

  test 'describe resource name and version: get #index with ahoy-visit being tracked when tracking is enabled and cookie consent is accepted' do
    @subdomain.update(tracking_enabled: true)
    assert_difference "Ahoy::Visit.count", +1 do
      get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
    end
    assert_response :success
  end

  test 'describe resource name, version and ID: get #show as json' do
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug, id: '1'), as: :json
    assert_response :success
  end

  test 'does not render resource that requires authentication' do
    @api_namespace.update(requires_authentication: true)
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), as: :json
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test 'nonexistant resource results in 404' do
    get api_url(version: '1', api_namespace: 'usersd'), as: :json
    assert_equal({ status: 'not found', code: 404 }, response.parsed_body.symbolize_keys)
  end

  test 'describes resource' do
    get api_describe_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_equal response.parsed_body['data']['attributes'].symbolize_keys.keys.sort, [:created_at, :id, :name, :namespace_type, :properties, :requires_authentication, :slug, :updated_at, :version, :non_primitive_properties].sort 
  end

  test 'index users resource' do
    get api_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), as: :json
    sample_user = response.parsed_body['data'][0]['attributes'].symbolize_keys!
    assert_equal(
      [:id, :created_at, :non_primitive_properties, :properties, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal sample_user[:properties].symbolize_keys!.keys.sort, api_resources(:user).properties.symbolize_keys!.keys.sort
  end

  test 'query users resource' do
    payload = {
      attribute: 'first_name',
      value: "Don"
    }
    post api_query_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, params: payload)
    sample_user = response.parsed_body["data"][0]["attributes"].symbolize_keys!
    assert_equal(
      [:id, :created_at, :non_primitive_properties, :properties, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal sample_user[:properties].symbolize_keys!.keys.sort, api_resources(:user).properties.symbolize_keys!.keys.sort
  end

  test '#show users resource' do
    get api_show_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal response.parsed_body["data"]["attributes"].symbolize_keys.keys.sort, [:id, :created_at, :updated_at, :non_primitive_properties, :properties].sort
    assert_response :success
  end

  test '#create access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#create access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test '#create access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_key = api_keys(:for_users)
    payload = {
      data: {
        first_name: 'Don',
        last_name: 'Restarone'
      }
    }
    assert_difference "@users_namespace.api_resources.count", +1 do
      post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), params: payload, headers: { 'Authorization': "Bearer #{api_key.token}" }
    end
    assert_equal [:status, :code, :object].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal payload[:data].keys.sort, response.parsed_body["object"]["data"]["attributes"]["properties"].symbolize_keys.keys.sort

    assert_no_difference "@users_namespace.api_resources.count", +1 do
      post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), headers: { 'Authorization': "Bearer #{api_key.token}" }
    end
    assert_equal [:status, :code].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal response.parsed_body["status"], "Please make sure that your parameters are provided under a data: {} top-level key"
  end

  test 'doesnot create allow #create if required property is missing' do
    @users_namespace.update(requires_authentication: true)
    api_key = api_keys(:for_users)
    ApiForm.create(api_namespace_id: @users_namespace.id, properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input', 'required': '1' }})
    payload = {
      data: {
        name: ''
      }
    }
    assert_no_difference "@users_namespace.api_resources.count" do
      post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), params: payload, headers: { 'Authorization': "Bearer #{api_key.token}" }
    end

    assert_equal response.parsed_body["code"], 400
    assert_equal response.parsed_body["status"], "Properties name is required"
  end

  test '#update access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_key = api_keys(:for_users)
    payload = {
      data: {
        first_name: 'Don!',
        last_name: 'Restarone!'
      }
    }
    api_resource = @users_namespace.api_resources.first
    assert_not_equal api_resource.properties["first_name"], payload[:data][:first_name]
    cloned_before_state = api_resource.dup
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: api_resource.id), params: payload, headers: { 'Authorization': "Bearer #{api_key.token}" }
    assert_equal [:status, :code, :object, :before].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal api_resource.reload.properties["first_name"], response.parsed_body["object"]["data"]["attributes"]["properties"]["first_name"]
    assert_equal cloned_before_state.properties["first_name"], response.parsed_body["before"]["data"]["attributes"]["properties"]["first_name"]
    assert_equal payload[:data].keys.sort, response.parsed_body["object"]["data"]["attributes"]["properties"].symbolize_keys.keys.sort

    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: api_resource.id), headers: { 'Authorization': "Bearer #{api_key.token}" }
    assert_equal response.parsed_body["status"], "Please make sure that your parameters are provided under a data: {} top-level key"
  end

  test '#destroy access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_key = api_keys(:for_users)
    assert_difference "@users_namespace.api_resources.count", -1 do
      delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id), headers: { 'Authorization': "Bearer #{api_key.token}" }
    end
    assert_equal [:status, :code, :object].sort, response.parsed_body.symbolize_keys.keys.sort

    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: 42), headers: { 'Authorization': "Bearer #{api_key.token}" }
    assert_equal response.parsed_body["code"], 404
  end

  test '#index search jsonb field - string - simple query - exact' do
    payload = { 
      properties: { 
        name: @api_resource_1.properties['name'] 
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id"), [@api_resource_1.id.to_s]
  end

  test '#index search jsonb field - string - simple query - exact (unhappy)' do
    payload = { 
      properties: { 
        name: @api_resource_1.properties['name'].split(' ')[0] 
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - string - extened query - exact' do
    payload = { 
      properties: { 
        name: { 
          value: @api_resource_1.properties['name'],
          option: 'EXACT'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id"), [@api_resource_1.id.to_s]
  end

  test '#index search jsonb field - string - extened query - exact - case insensitive' do
    payload = { 
      properties: { 
        name: { 
          value: @api_resource_1.properties['name'].downcase,
          option: 'EXACT'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id"), [@api_resource_1.id.to_s]
  end

  test '#index search jsonb field - string - partial' do
    payload = { 
      properties: { 
        name: { 
          value: 'john',
          option: 'PARTIAL'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id, @api_resource_3.id].sort
  end

  test '#index search jsonb field - string - partial (unhappy)' do
    payload = { 
      properties: { 
        name: { 
          value: 'not a name',
          option: 'PARTIAL'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - string - KEYWORDS: multi word string' do
    @api_resource_1.update(properties: {name: 'Professional Writer'})
    @api_resource_2.update(properties: {name: 'Physical Development'})
    @api_resource_3.update(properties: {name: 'Professional Development'})

    payload = { 
      properties: { 
        name: { 
          value: 'professional development',
          option: 'KEYWORDS'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id, @api_resource_2.id, @api_resource_3.id].sort
  end

  test '#index search jsonb field - string - KEYWORDS: multi word string (unhappy)' do
    @api_resource_1.update(properties: {name: 'Professional Writer'})
    @api_resource_2.update(properties: {name: 'Physical Development'})
    @api_resource_3.update(properties: {name: 'Professional Development'})

    payload = { 
      properties: { 
        name: { 
          value: 'hello world',
          option: 'KEYWORDS'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - Array - KEYWORDS: match ALL' do
    @api_resource_1.update(properties: {tags: ['Professional Writer', 'zebra']})
    @api_resource_2.update(properties: {tags: ['Physical Development', 'cow']})
    @api_resource_3.update(properties: {tags: ['Professional Development', 'animal']})

    payload = { 
      properties: { 
        tags: { 
          value: ['professional development'],
          option: 'KEYWORDS'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_3.id].sort
  end

  test '#index search jsonb field - Array - KEYWORDS: match ALL (unhappy)' do
    @api_resource_1.update(properties: {tags: ['Professional Writer', 'zebra']})
    @api_resource_2.update(properties: {tags: ['Physical Development', 'cow']})
    @api_resource_3.update(properties: {tags: ['Professional Development', 'animal']})

    payload = { 
      properties: { 
        tags: { 
          value: ['hello world'],
          option: 'KEYWORDS'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - Array - KEYWORDS: match ANY' do
    @api_resource_1.update(properties: {tags: ['Professional Writer', 'zebra']})
    @api_resource_2.update(properties: {tags: ['Physical Development', 'cow']})
    @api_resource_3.update(properties: {tags: ['Professional Development', 'animal']})

    payload = { 
      properties: { 
        tags: { 
          value: ['professional development'],
          option: 'KEYWORDS',
          match: 'ANY'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id, @api_resource_2.id, @api_resource_3.id].sort
  end

  test '#index search jsonb field - Array - KEYWORDS: match ANY (unhappy)' do
    @api_resource_1.update(properties: {tags: ['Professional Writer', 'zebra']})
    @api_resource_2.update(properties: {tags: ['Physical Development', 'cow']})
    @api_resource_3.update(properties: {tags: ['Professional Development', 'animal']})

    payload = { 
      properties: { 
        tags: { 
          value: ['hello world'],
          option: 'KEYWORDS',
          match: 'ANY'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - nested string' do
    payload = { 
      properties: { 
        object: { 
          foo: 'bar'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort

    payload = { 
      properties: { 
        object: { 
          x: 'y',
          z: 'a'
        }
      }
    }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_2.id].sort
  end

  test '#index search jsonb field - nested string (two level) - partial' do
    payload = { 
        properties: { 
          object: { 
            baz: {
              a: 'b'
            }
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort
  end

  test '#index search jsonb field - integer' do
    payload = { 
        properties: { 
          age: 35
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort
  end

  test '#index search jsonb field - integer (unhappy path)' do
    payload = { 
        properties: { 
          age: 800
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - hash - exact match' do
    payload = { 
        properties: { 
          object: {
            value: { x: 'y', z: 'a'},
            option: 'EXACT'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_2.id].sort
  end

  test '#index search jsonb field - hash - exact match(unhappy path)' do
    payload = { 
        properties: { 
          object: {
            value: { x: 'y'},
            option: 'EXACT'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_response :success
    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - hash - partial match' do
    payload = { 
        properties: { 
          object: {
            value: { x: 'y' },
            option: 'PARTIAL'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
    assert_response :success

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_2.id].sort
  end

  test '#index search jsonb field - array - exact match' do
    payload = { 
        properties: { 
          interests: ['software', 'web', 'games']
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort

    # array match should be independent of order 
    payload = { 
        properties: { 
          interests: [ 'web', 'software', 'games']
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort

    # extended query
    payload = { 
        properties: { 
          interests: { 
            value:[ 'web', 'software', 'games'],
            option: 'EXACT'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json
  
    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort
  end

  test '#index search jsonb field - array - exact match (unhappy)' do
    payload = { 
        properties: { 
          interests: [ 'web', 'software']
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - array - partial match' do
    payload = { 
        properties: { 
          interests: {
            value: [ 'web', 'software'],
            option: 'PARTIAL'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id].sort
  end

  test '#index search jsonb field - array - partial match (unhappy)' do
    payload = { 
        properties: { 
          interests: {
            value: [ 'web', 'not a member'],
            option: 'PARTIAL'
          }
        }
      }
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_empty response.parsed_body["data"]
  end

  test '#index search jsonb field - array - KEYWORDS match ALL' do
    @api_resource_2.update(properties: {interests: ['hello world', 'foo', 'bar']})
    payload = { 
        properties: { 
          interests: {
            value: ['hello world', 'foo'],
            option: 'KEYWORDS'
          }
        }
      }

    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_2.id].sort
  end

  test '#index search jsonb field - array - KEYWORDS match ANY' do
    @api_resource_1.update(properties: {interests: ['hello']})
    @api_resource_2.update(properties: {interests: ['hello world', 'foo', 'bar']})

    payload = { 
        properties: { 
          interests: {
            value: ['hello world', 'foo'],
            option: 'KEYWORDS',
            match: 'ANY'
          }
        }
      }

    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), params: payload, as: :json

    assert_equal response.parsed_body["data"].pluck("id").map(&:to_i).sort, [@api_resource_1.id, @api_resource_2.id].sort
  end
end
