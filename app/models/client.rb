class Client
  attr_reader :id

  def initialize(id:)
    @id = id
  end

   def to_param
     id
   end
end