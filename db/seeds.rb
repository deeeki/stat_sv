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
Period.find_or_create_by(card_set_code: :bos, sequence: 1, started_on: Date.new(2018, 6, 28), ended_on: Date.new(2018, 7, 17))
Period.find_or_create_by(card_set_code: :bos, sequence: 2, started_on: Date.new(2018, 7, 18), ended_on: Date.new(2018, 8, 20))
Period.find_or_create_by(card_set_code: :bos, sequence: 3, started_on: Date.new(2018, 8, 21), ended_on: Date.new(2018, 9, 26))
Period.find_or_create_by(card_set_code: :oot, sequence: 1, started_on: Date.new(2018, 9, 27), ended_on: Date.new(2018, 10, 29))
Period.find_or_create_by(card_set_code: :oot, sequence: 2, started_on: Date.new(2018, 10, 30), ended_on: Date.new(2018, 11, 25))
Period.find_or_create_by(card_set_code: :oot, sequence: 3, started_on: Date.new(2018, 11, 26), ended_on: Date.new(2018, 12, 26))
Period.find_or_create_by(card_set_code: :alt, sequence: 1, started_on: Date.new(2018, 12, 27), ended_on: Date.new(2019, 1, 16))
Period.find_or_create_by(card_set_code: :alt, sequence: 2, started_on: Date.new(2019, 1, 17), ended_on: Date.new(2019, 2, 18))
Period.find_or_create_by(card_set_code: :alt, sequence: 3, started_on: Date.new(2019, 2, 19), ended_on: Date.new(2019, 3, 27))
Period.find_or_create_by(card_set_code: :str, sequence: 1, started_on: Date.new(2019, 3, 28), ended_on: Date.new(2019, 5, 20))
Period.find_or_create_by(card_set_code: :str, sequence: 2, started_on: Date.new(2019, 5, 21), ended_on: Date.new(2019, 6, 26))
Period.find_or_create_by(card_set_code: :rog, sequence: 1, started_on: Date.new(2019, 6, 27), ended_on: Date.new(2019, 7, 10))
Period.find_or_create_by(card_set_code: :rog, sequence: 2, started_on: Date.new(2019, 7, 11), ended_on: Date.new(2019, 7, 29))
Period.find_or_create_by(card_set_code: :rog, sequence: 3, started_on: Date.new(2019, 7, 30), ended_on: Date.new(2019, 8, 21))
Period.find_or_create_by(card_set_code: :rog, sequence: 4, started_on: Date.new(2019, 8, 22), ended_on: Date.new(2019, 9, 25))
Period.find_or_create_by(card_set_code: :vec, sequence: 1, started_on: Date.new(2019, 9, 26), ended_on: Date.new(2019, 10, 28))
