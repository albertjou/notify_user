module NotifyUser
  class PubNub

    #sends push notification
    def self.push_notification(notification)
      pubnub = Pubnub.new(
        :origin => ENV['PN_ORIGIN'],
        :publish_key   => ENV['PN_PUBLISH_KEY'],
        :subscribe_key => ENV['PN_SUBSCRIBE_KEY'],
        :secret_key => ENV['PN_SECRET_KEY'],
        :logger => Logger.new(STDOUT)
      )

      pubnub.grant( auth_key: ENV['PN_SECRET_KEY'],
                    :read => true,
                    :write => true,
                    :ttl => 525600,
                    :http_sync => true
                  )

      pn_apns = {
        aps: {
          alert: notification.mobile_message,
          badge: notification.count_for_target,
          type: notification.type
        }
      }

      pn_apns[:aps][:action_id] = notification.params[:action_id] if notification.params[:action_id]
      pn_apns[:aps]['content-available'] = notification.params['content-available'] if notification.params['content-available']

      pn_fcm = {
        data: {
          notification_id: notification.id,
          message: notification.mobile_message,
          type: notification.type,
          unread_count: notification.count_for_target
        }
      }

      pn_fcm[:data][:action_id] = notification.params[:action_id] if notification.params[:action_id]

      pubnub.publish(
        channel: notification.target.uuid,
        http_sync: true,
        message: {
          pn_apns: pn_apns,
          pn_fcm: pn_fcm
        }
      )
    end
  end
end
