
module RedmineContacts
  module Utils
    module DateUtils
      class << self
        def retrieve_date_range(period)
          from, to = nil, nil
          case period
          when 'today'
            from = to = Date.today
          when 'yesterday'
            from = to = Date.today - 1
          when 'current_week'
            from = Date.today - (Date.today.cwday - 1)%7
            to = from + 6
          when 'last_week'
            from = Date.today - 7 - (Date.today.cwday - 1)%7
            to = from + 6
          when 'last_2_weeks'
            from = Date.today - 14 - (Date.today.cwday - 1)%7
            to = from + 13
          when '7_days'
            from = Date.today - 7
            to = Date.today
          when 'last_7_days'
            from = Date.today - 14
            to = from + 7
          when 'current_month'
            from = Date.civil(Date.today.year, Date.today.month, 1)
            to = (from >> 1) - 1
          when 'last_month'
            from = Date.civil(Date.today.year, Date.today.month, 1) << 1
            to = (from >> 1) - 1
          when '30_days'
            from = Date.today - 30
            to = Date.today
          when 'current_year'
            from = Date.civil(Date.today.year, 1, 1)
            to = Date.civil(Date.today.year, 12, 31)
          when 'last_year'
            from = Date.civil(1.year.ago.year, 1, 1)
            to = Date.civil(1.year.ago.year, 12, 31)
          end

          from, to = from, to + 1 if (from && to)
          [from, to]
        end
      end
    end
  end
end
