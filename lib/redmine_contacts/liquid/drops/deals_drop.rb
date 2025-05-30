module RedmineContacts
  module Liquid
    module Drops

class DealsDrop < ::Liquid::Drop

  def initialize(deals)
    @deals = deals
  end

  def before_method(id)
    deal = @deals.where(:id => id).first || Deal.new
    DealDrop.new deal
  end

  def all
    @all ||= @deals.map do |deal|
      DealDrop.new deal
    end
  end

  def visible
    @visible ||= @deals.visible.map do |deal|
      DealDrop.new deal
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class DealDrop < ::Liquid::Drop

  delegate :id, :name, :created_on, :due_date, :price, :price_type, :currency, :background, :probability, :to => :@deal

  def initialize(deal)
    @deal = deal
  end

  def notes
    @deal.notes.map{|n| NoteDrop.new(n) }
  end

  def category
    @deal.category.name if @deal.category
  end

  def contact
    ContactDrop.new @deal.contact if @deal.contact
  end

  def status
    @deal.status.name if @deal.status
  end

  def custom_field_values
    @deal.custom_field_values
  end
end
    end
  end
end