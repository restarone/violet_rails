module ApiResourcesHelper

  def serialize_resource(collection)
    collection.map{|n| { created_at: n.created_at, updated_at: n.updated_at, properties: n.properties ? JSON.parse(n.properties) : nil } }.to_json
  end
end
