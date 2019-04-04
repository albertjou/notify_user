require 'spec_helper'
require 'support/test_gcm_connection'

module NotifyUser
  describe Fcm, type: :model do
    let(:user) { create(:user) }
    let(:notification) { create(:notify_user_notification, target: user) }
    let(:user_tokens) { ['a_token'] }

    before :each do
      allow_any_instance_of(Fcm).to receive(:device_tokens) { user_tokens }
      @client = TestFCMConnection.new
      allow_any_instance_of(Fcm).to receive(:client).and_return(@client)
    end

    describe 'initialisation' do
      it 'initialises the correct push options' do
        @fcm = Fcm.new([notification], [], {})

        expect(@fcm.push_options).to include(
          data: {
            notification_id: notification.id,
            message: notification.mobile_message,
            type: notification.class.name,
            unread_count: 1,
            custom_data: notification.sendable_params
          }
        )
      end
    end

    describe 'push' do
      before :each do
        @fcm = Fcm.new([notification], [], {})
      end

      context 'without errors' do
        before :each do
          # Stub out send method with a successful response object, or maybe,
          # initialize TestFCMConnection with new(:success)
          # This would keep the spec file clean...
        end

        it 'returns true if no error' do
          expect(@fcm.push).to eq true
        end

        it 'sends to the device token of the notification target' do
          expect(@client).to receive(:send).with(user_tokens, kind_of(Hash))
          @fcm.push
        end

        it 'does not try to send to an empty token' do
          user_tokens = []
          allow_any_instance_of(Fcm).to receive(:device_tokens) { user_tokens }
          expect_any_instance_of(FCM).not_to receive(:send)
          @fcm.push
        end

        it 'sends multiple notifications' do
          multiple_tokens = %w(token_1 token_2 token_3)
          allow(@fcm).to receive(:device_tokens) { multiple_tokens }
          expect(@client).to receive(:send).once
            .with(multiple_tokens, kind_of(Hash))
          @fcm.push
        end
      end
    end
  end
end
