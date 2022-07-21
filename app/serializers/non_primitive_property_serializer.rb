class NonPrimitivePropertySerializer
    include JSONAPI::Serializer
  
    attributes :label, :field_type

    attribute :url, if: Proc.new { |record| record.file? } do |object|  object.file_url end

    attribute :content, if: Proc.new { |record| record.richtext? } do |object| object.content.body end 
end
  