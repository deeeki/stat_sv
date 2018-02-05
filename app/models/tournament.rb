class Tournament
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize
  field :name, type: String
  field :format, type: String
  field :held_on, type: Date
  field :round, type: String
  enumerize :format, in: [:rotation, :unlimited], default: :rotation, scope: true
  has_many :players, dependent: :delete
  has_many :matches, dependent: :delete
  has_many :battles, dependent: :delete
end
