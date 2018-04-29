class Period
  include Mongoid::Document
  extend Enumerize
  field :card_set_code, type: String
  field :sequence, type: Integer
  field :started_on, type: Date
  field :ended_on, type: Date
  enumerize :card_set_code, in: [:cgs, :dbn], scope: true
  has_many :archetypes
end
