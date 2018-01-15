CARD_ID_FILE = Rails.root.join('tmp/clan_card_ids.yml')
CARDS_URL = 'https://shadowverse-portal.com/cards'
API_URL = 'https://shadowverse-portal.com/api/v1/deck?format=json&hash='

namespace :portal do
  task card_ids: :environment do
    AGENT = Mechanize.new

    clan_card_ids = {}
    Clan.pluck(:id).each do |clan_id|
      url = "#{CARDS_URL}?clan[]=#{clan_id}"
      ids = []
      loop do
        puts url
        page = AGENT.get(url)
        ids << page.search('a.el-card-visual-content').map{|a| a['href'].scan(/\d+/).first.to_i }

        break unless next_link = page.at('span.bl-pagination-item.is-next > a')
        url = next_link['href']
      end
      clan_card_ids[clan_id] = ids.flatten
      File.write(CARD_ID_FILE, clan_card_ids.to_yaml)
    end
  end

  task cards: :environment do
    Card.delete_all

    clan_card_ids = YAML.load_file(CARD_ID_FILE)
    neut_ids = clan_card_ids.values.first
    clan_decks = {}
    Clan.pluck(:id).each do |clan_id|
      additional_count = 40 - (clan_card_ids[clan_id].size % 40)
      additional_ids = additional_count.times.map{|i| neut_ids[i] }
      clan_decks[clan_id] = (clan_card_ids[clan_id] + additional_ids).each_slice(40).to_a.sort
    end

    clan_decks.each do |clan_id, decks|
      decks.each do |deck|
        hash_str = "1.#{clan_id.zero? ? 1 : clan_id}.#{deck.map{|card_id| B64.encode(card_id) }.join('.')}"
        url = API_URL + hash_str
        json = JSON.parse(open(url).read)
        json['data']['deck']['cards'].each do |card|
          next if Card.find_by(id: card['card_id'])
          puts card['card_name']
          Card.create(card.merge(id: card['card_id'], code: B64.encode(card['card_id'])))
        end
      end
    end
  end
end
