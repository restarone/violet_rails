module ApiResourcesHelper

  def serialize_resource(collection)
    collection.map{|n| { created_at: n.created_at, updated_at: n.updated_at, properties: JSON.parse(n.properties) } }.to_json
  end
end
