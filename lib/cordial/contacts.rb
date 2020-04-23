module Cordial
  # Wraps all interaction with the Contact resource.
  # @see https://api.cordial.io/docs/v1/#!/contacts
  class Contacts
    include ::HTTParty
    extend Client

    # Find a contact.
    # @example Usage
    #  Cordial::Contacts.find(email: 'hello@world.earth')
    # @example Response when the contact was found.
    #   {
    #     "_id" => "111122223334444",
    #     "channels" => {
    #       "email" => {
    #         "address" => "hello@world.earth",
    #         "subscribeStatus" => "unsubscribed",
    #         "unsubscribedAt" => "2018-05-02T23:35:38+0000"
    #       }
    #     },
    #     "lastModified" => "2018-05-16T22:57:16+0000",
    #     "createdAt" => "2018-04-25T19:55:45+0000",
    #     "lists" => ["test-list"],
    #     "lj" => {
    #       "14854" => {
    #         "sec" => 1524897139,
    #         "usec" => 0
    #        }
    #      },
    #      "listJoinDate" => {
    #        "test-list" => "2018-04-28T06:32:19+0000"
    #      }
    #    }
    #
    # @example Response when the contact was not found.
    #  {"error"=>true, "message"=>"record not found"}
    def self.find(email:)
      client.get("/contacts/#{email}")
    end

    # Create a new contact.
    #
    # If the contact already exists it will fail.
    # @example Usage.
    #  Cordial::Contacts.create(
    #    email: 'hello@world.earth',
    #    attribute_list: {
    #      some_attribute: 'your-custom-value'
    #    },
    #    subscribe_status: 'subscribed'
    #  )
    def self.create(email:, sms: nil, attribute_list: {}, subscribe_status: nil)
      client.post('/contacts', body: {
        forceSubscribe: subscribe_status == 'subscribed' || nil
      }.merge(channel_data(email, sms, subscribe_status)).compact.merge(attribute_list).to_json)
    end

    # Update an existing contact.
    #
    # If the contact doesn't exist it will fail.
    # @example Usage.
    #  Cordial::Contacts.update(
    #    email: 'hello@world.earth',
    #    attribute_list: {
    #      some_attribute: 'your-custom-value'
    #    },
    #    subscribe_status: 'subscribed'
    #  )
    def self.update(email:, sms: nil, attribute_list: {}, subscribe_status: nil)
      client.put("/contacts/email:#{email}", body: {
        forceSubscribe: subscribe_status == 'subscribed' || nil
      }.merge(channel_data(email, sms, subscribe_status)).compact.merge(attribute_list).to_json)
    end

    # Unsubscribe a contact.
    #
    # @param channel [String] The channel to unsubscribe`
    # @see https://support.cordial.com/hc/en-us/articles/115001319432-Channels-Overview
    # @param mc_id [String] The Message Contact ID
    # @see https://support.cordial.com/hc/en-us/articles/115005855508-System-Variables
    # @example Usage. Default without channel.
    #  Cordial::Contacts.unsubscribe(
    #    email: 'hello@world.earth',
    #    sms: '001800123123'
    #  )
    #
    # @example Usage. with channel and mcID.
    #  Cordial::Contacts.unsubscribe(
    #    email: 'hello@world.earth',
    #    channel: 'email'
    #    mc_id: '645:5b6a9f26esb828b63c2a7946:ot:8ama709bbb3dc2f9bc27158f:1'
    #  )
    def self.unsubscribe(email:, sms: nil, channel: '', mc_id: '')
      if channel.empty? && mc_id.empty?
        url = "/contacts/#{email}"
        body = channel_data(email, sms, 'unsubscribed')
      else
        url = "/contacts/#{email}/unsubscribe/#{channel}"
        body = { mcID: mc_id }
      end

      client.put(url, body: body.to_json)
    end

    # Create a new contact cart.
    #
    # @example Usage.
    #   Cordial::Contacts.create_cart({...})
    #
    # @return [{"success"=>true}]
    # @return [{"error"=>true, "messages"=>"..."}]
    def self.create_cart(email, options)
      cart = Cordial::Cart.new(options)
      client.post("/contacts/#{email}/cart", body: cart.to_json)
    end

    private

    def self.channel_data(email, sms, subscribe_status)
      {
        channels: {
          email: {
            address: email,
            subscribeStatus: subscribe_status
          }.compact
        }.merge(sms_attributes(sms, subscribe_status))
      }
    end

    def self.sms_attributes(sms, subscribe_status)
      return {} unless sms

      {
        sms: {
          address: sms,
          keywords: {
            undies: {
              ss: subscribe_status
            }.compact
          }
        }
      }
    end
  end
end
