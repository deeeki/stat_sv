Clan.delete_all
{
  'ニュートラル' => 0,
  'エルフ' => 1,
  'ロイヤル' => 2,
  'ウィッチ' => 3,
  'ドラゴン' => 4,
  'ネクロマンサー' => 5,
  'ヴァンパイア' => 6,
  'ビショップ' => 7,
  'ネメシス' => 8,
}.each do |name, id|
  Clan.create(id: id, name: name)
end

Period.find_or_create_by(card_set_code: :cgs, sequence: 1, started_on: Date.new(2017, 12, 29), ended_on: Date.new(2018, 1, 29))
Period.find_or_create_by(card_set_code: :cgs, sequence: 2, started_on: Date.new(2018, 1, 30), ended_on: Date.new(2018, 3, 28))
Period.find_or_create_by(card_set_code: :dbn, sequence: 1, started_on: Date.new(2018, 3, 29), ended_on: Date.new(2018, 5, 29))
Period.find_or_create_by(card_set_code: :dbn, sequence: 2, started_on: Date.new(2018, 5, 30), ended_on: Date.new(2018, 6, 27))
Period.find_or_create_by(card_set_code: :bos, sequence: 1, started_on: Date.new(2018, 6, 28), ended_on: Date.new(2018, 9, 26))
