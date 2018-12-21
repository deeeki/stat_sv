class Battle
  include Mongoid::Document
  extend Enumerize
  field :format, type: String
  field :battled_on, type: Date
  field :number, type: Integer
  enumerize :format, in: [:rotation, :unlimited], default: :rotation, scope: true
  belongs_to :tournament
  belongs_to :match
  belongs_to :won_player, class_name: 'Player', inverse_of: :won_battles
  belongs_to :lost_player, class_name: 'Player', inverse_of: :lost_battles
  belongs_to :won_archetype, class_name: 'Archetype', optional: true
  belongs_to :lost_archetype, class_name: 'Archetype', optional: true
  belongs_to :won_clan, class_name: 'Clan'
  belongs_to :lost_clan, class_name: 'Clan'

  class << self
    def stats format: :rotation, period: Period.current
      archetypes = period.archetypes.with_format(format)
      inner_hash = Hash[archetypes.map{|a| [a.name, 0] }]
      outer_hash = Hash[archetypes.map{|a| [a.name, inner_hash.deep_dup] }]
      wins, battles, rates, formula_rates = 4.times.map{ outer_hash.deep_dup }

      Battle.with_format(format).gte(battled_on: period.started_on).each do |b|
        next if !b.won_archetype || !b.lost_archetype
        battles[b.won_archetype.name][b.lost_archetype.name] += 1
        battles[b.lost_archetype.name][b.won_archetype.name] += 1
        wins[b.won_archetype.name][b.lost_archetype.name] += 1
      end

      archetype_names = archetypes.map(&:name)
      archetype_names.each do |a1|
        archetype_names.each do |a2|
          win = wins[a1][a2]
          battle = battles[a1][a2]
          rates[a1][a2] = battle.zero? ? 'N/A' : (win.to_f / battle * 100).round(2)
          formula_rates[a1][a2] = battle.zero? ? 'N/A' : "=ROUND(#{win}/#{battle}*100, 2)"
        end
      end

      OpenStruct.new(wins: wins, battles: battles, rates: rates, formula_rates: formula_rates)
    end
  end
end
