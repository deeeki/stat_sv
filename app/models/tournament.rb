class Tournament
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :held_on, type: Date
  field :round, type: String
  has_many :players
  has_many :matches
end
