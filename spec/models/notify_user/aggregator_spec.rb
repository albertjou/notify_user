require 'spec_helper'

module NotifyUser
  describe Aggregator do
    def create_notification_for_user(user, options = {})
      NewPostNotification.create({ target: user }.merge(options))
    end

    describe '#has_pending_deliveries?' do
      before :each do
        @user = create(:user)
      end

      context 'with grouping' do
        before :each do
          NewPostNotification.class_eval do
            channel :apns, aggregate_per: [0, 3, 10, 30, 60]
            self.aggregate_grouping = true
          end
        end

        it 'returns true for a pending notification' do
          notification = create_notification_for_user(@user, { group_id: '1' })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { group_id: '1' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq true
        end

        it 'returns false for a pending notification of another group' do
          notification = create_notification_for_user(@user, { group_id: '1' })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { group_id: '2' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is no other grouped notification' do
          new_notification = create_notification_for_user(@user, { group_id: '1' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is no current pending notiifcation' do
          notification = create_notification_for_user(@user, { group_id: '1' })
          delivery = create(:delivery, notification: notification, sent_at: Time.zone.now)

          new_notification = create_notification_for_user(@user, { group_id: '1' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is pending notifications have been read' do
          notification = create_notification_for_user(@user, { group_id: '1', read_at: Time.zone.now })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { group_id: '1' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is pending notifications for another user' do
          notification = create_notification_for_user(create(:user), { group_id: '1' })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { group_id: '1' })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end
      end

      context 'without grouping' do
        before :each do
          NewPostNotification.class_eval do
            channel :apns, aggregate_per: [0, 3, 10, 30, 60]
            self.aggregate_grouping = false
          end
        end

        it 'returns true for a pending notification' do
          notification = create_notification_for_user(@user, { })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq true
        end

        it 'returns false if there is no other grouped notification' do
          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is no current pending notiifcation' do
          notification = create_notification_for_user(@user, { })
          delivery = create(:delivery, notification: notification, sent_at: Time.zone.now)

          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is pending notifications have been read' do
          notification = create_notification_for_user(@user, { read_at: Time.zone.now })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end

        it 'returns false if there is pending notifications for another user' do
          notification = create_notification_for_user(create(:user), { })
          delivery = create(:delivery, notification: notification)

          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.has_pending_deliveries?).to eq false
        end
      end
    end

    describe '#delay_time' do
      before :each do
        @user = create(:user)
      end

      context 'without grouping' do
        before :each do
          NewPostNotification.class_eval do
            channel :apns, aggregate_per: [0, 3, 10, 30, 60]
            self.aggregate_grouping = false
          end
        end

        it 'returns the first interval in seconds if there are no previous unread notifications' do
          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.delay_time_in_seconds).to eq 0
        end

        it 'returns the third interval in seconds if there are two previous unread notifications' do
          create_notification_for_user(@user, { })
          create_notification_for_user(@user, { })
          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.delay_time_in_seconds).to eq 600 # 10 * 60
        end

        it 'returns the first interval in seconds if the previous notifications have been read' do
          create_notification_for_user(@user, { read_at: Time.zone.now })
          create_notification_for_user(@user, { read_at: Time.zone.now })
          new_notification = create_notification_for_user(@user, { })

          aggregator = described_class.new(new_notification, new_notification.class.channels[:apns][:aggregate_per])
          expect(aggregator.delay_time_in_seconds).to eq 0
        end
      end
    end
  end
end
