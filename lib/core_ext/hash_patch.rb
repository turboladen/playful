class Hash
  def symbolize_keys!
    self.inject({}) { |result, (k, v)| result[k.to_sym] = v; result }
  end
end
