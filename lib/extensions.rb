class Object
  def hash_from_methods(*methods)
    methods = methods.flatten
    methods.inject({}) do |hash,method|
      value = send method
      hash.merge(method => value)
    end
  end
end

class String
  def words
    strip.split /\s+/
  end

  def urlencode
    CGI.escape(self).gsub("+", "%20").gsub("%7E", "~")
  end
end

class Array
  def to_disjunctive_sentence
    to_sentence two_words_connector: " or ", last_word_connector: ", or "
  end
end

class Hash
  def subhash(*keys)
    keys = keys.flatten
    keys.inject({}) {|h,k| h.merge(k => self[k])}
  end

  def subhash_without(*keys)
    keys = keys.flatten
    keys.inject(dup) {|h,k| h.delete k; h}
  end

  def to_query_string(options = {})
    keylist = keys
    keylist = keylist.sort if options[:sorted]
    pairs = keylist.map {|key| key.to_s.urlencode + "=" + self[key].to_s.urlencode}
    pairs.join "&"
  end

  def self.from_keymap(*keys, &block)
    keys.inject({}) {|hash,key| hash.merge(key => (yield key))}
  end
end

class Time
  def self.since(datetime)
    Time.now - datetime
  end

  def self.until(datetime)
    datetime - Time.now
  end
end

# to_bool

class TrueClass
  def to_bool
    self
  end
end

class FalseClass
  def to_bool
    self
  end
end

class NilClass
  def to_bool
    false
  end
end

class String
  def to_bool
    downcase.in? %w{true t yes y 1}
  end
end

class Integer
  def to_bool
    self != 0
  end
end
