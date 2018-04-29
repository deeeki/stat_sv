class Match
  include Mongoid::Document
  include Mongoid::Timestamps
  field :group, type: String
  field :round, type: String
  field :scores, type: Array
  belongs_to :tournament
  belongs_to :won_player, class_name: 'Player', inverse_of: :won_matches
  belongs_to :lost_player, class_name: 'Player', inverse_of: :lost_matches
  has_many :battles, dependent: :delete
end
