class Battle
  include Mongoid::Document
  extend Enumerize
  field :format, type: String
  field :battled_on, type: Date
  field :number, type: Integer
  enumerize :format, in: [:rotation, :unlimited], default: :rotation, scope: true
  belongs_to :tournament
  belongs_to :match
  belongs_to :won_player, class_name: 'Player'
  belongs_to :lost_player, class_name: 'Player'
  belongs_to :won_archetype, class_name: 'Archetype'
  belongs_to :lost_archetype, class_name: 'Archetype'
  belongs_to :won_clan, class_name: 'Clan'
  belongs_to :lost_clan, class_name: 'Clan'
end
