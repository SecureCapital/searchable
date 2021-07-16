class Date::Infinity
  def <=>(other)
    if other.is_a?(Date) || other.is_a?(DateTime) || other.is_a?(Date::Infinity)
      return self.to_f <=> other.to_f
    end
    x = super(other)
    return x unless x.nil?
    if other.respond_to?(:<=>)
      return other <=> self
    end
  end
end
