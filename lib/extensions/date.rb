class Date
  def to_f
    to_datetime.to_f
  end

  def finite?
    true
  end
end
