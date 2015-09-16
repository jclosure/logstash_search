require 'csv'

# MONKEY PATCH EXTENSIONS
class Hash
  def without(*keys)
    dup.without!(*keys)
  end

  def without!(*keys)
    reject! { |key| keys.include?(key) }
  end

  def with(*keys)
    dup.with!(*keys)
  end
  
  def with!(*keys)
    select! { |key| keys.include?(key) }
  end
end

class ::Hash
  def method_missing(name)
    return self[name] if key? name
    self.each { |k,v| return v if k.to_s.to_sym == name }
    super.method_missing name
  end
end



class Array
  def to_hashed_csv
    hashes = self
    if hashes.any?
      column_names = hashes.first.keys
      s=CSV.generate do |csv|
        csv << column_names
        hashes.each do |x|
          csv << x.values
        end
      end
    else
      ""
    end
  end
end
