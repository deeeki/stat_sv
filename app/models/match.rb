class Match
  include Mongoid::Document
  include Mongoid::Timestamps
  field :group, type: String
  field :round, type: String
  field :scores, type: Array
  belongs_to :tournament
  belongs_to :won_player, class_name: 'Player'
  belongs_to :lost_player, class_name: 'Player'
end
