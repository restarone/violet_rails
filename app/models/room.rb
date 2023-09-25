class Room < ApplicationRecord
   def to_param
     id
   end
end