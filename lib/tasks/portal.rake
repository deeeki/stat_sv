API_URL = 'https://shadowverse-portal.com/api/v1/cards?format=json&lang=ja'

namespace :portal do
  namespace :cards do
    task import: :environment do
      Card.delete_all

      json = JSON.parse(open(API_URL).read)
      json['data']['cards'].each do |card|
        next if Card.find_by(id: card['card_id'])
        Card.create(card.merge(id: card['card_id'], code: B64.encode(card['card_id'])))
      end

      puts "#{Card.count} cards are imported."
    end

    task alternatives: :environment do
      alt_cards = Card.where('this.base_card_id != this.card_id').order(clan_id: :asc, cost: :asc).map do |alt|
        base = Card.find(alt.base_card_id)
        %[#{alt.code}: #{base.code} # #{alt.card_name}]
      end
      File.write('config/alt_cards.yml', alt_cards.join("\n"))
    end
  end
end
