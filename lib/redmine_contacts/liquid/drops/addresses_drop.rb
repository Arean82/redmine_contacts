module RedmineContacts
  module Liquid
    module Drops

      class AddressesDrop < ::Liquid::Drop
        def initialize(addresses)
          @addresses = addresses
        end

        def before_method(id)
          address = @addresses.where(id: id).first || Address.new
          AddressDrop.new address
        end

        def all
          @all ||= @addresses.map { |address| AddressDrop.new(address) }
        end

        def visible
          @visible ||= @addresses.visible.map { |address| AddressDrop.new(address) }
        end

        def each(&block)
          all.each(&block)
        end
      end

      class AddressDrop < ::Liquid::Drop
        delegate :id, :address_type, :street1, :street2, :city,
                 :region, :postcode, :country_code, :country,
                 :full_address, :post_address, to: :@address

        def initialize(address)
          @address = address
        end

        private

        def helpers
          Rails.application.routes.url_helpers
        end
      end

    end
  end
end
