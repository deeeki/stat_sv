class Archetype
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :detection_order, type: Integer
  field :conditions, type: Array
  belongs_to :clan
end
