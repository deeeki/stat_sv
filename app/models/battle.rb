class Battle
  include Mongoid::Document
  field :battled_on, type: Date
  field :number, type: Integer
  belongs_to :tournament
  belongs_to :match
  belongs_to :won_player, class_name: 'Player'
  belongs_to :lost_player, class_name: 'Player'
  belongs_to :won_archetype, class_name: 'Archetype'
  belongs_to :lost_archetype, class_name: 'Archetype'
end
