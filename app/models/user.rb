class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :nicename, type: String
  has_many :players
end
