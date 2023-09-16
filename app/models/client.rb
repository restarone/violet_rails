class Client
  attr_reader :id

  attr_accessor :user_id, :visit_id, :visitor_id


  def initialize(id:)
    @id = id
  end

   def to_param
     id
   end
end