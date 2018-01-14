module B64
  TABLE = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'.split('').freeze

  module_function

  def encode num
    num > 63 ? encode(num / 64) + TABLE[num % 64] : TABLE[num % 64]
  end

  def decode str
    chars = str.split('').map{|i| TABLE.index i }
    for i in 0...chars.size do
      return chars[i] if i == chars.size - 1
      chars[i + 1] += chars[i] * 64
    end
  end
end

