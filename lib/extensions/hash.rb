class Hash
  def nilify_blanks!
    self.each_with_object({}) { |(k,v),g|
      g[k] = (Hash === v) ?  v.nilify_blanks! : (v == '') ? nil : v }
  end

  def strip_strings!
    each do |k,v|
      if v.is_a?(String)
        v.strip!
      end
    end
  end
end
