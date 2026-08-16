# frozen_string_literal: true

require 'rails_helper'

# concern を確かめるための入れ物です。
class TestAuthenticationController < ApplicationController
  include Authentication

  def public_action
    render plain: 'public'
  end

  def protected_action
    render plain: 'protected'
  end
end

RSpec.describe Authentication, type: :controller do
  controller(TestAuthenticationController) do
    before_action :require_authentication, only: [:protected_action]

    def public_action
      render plain: 'public'
    end

    def protected_action
      render plain: "protected for #{current_operator.email}"
    end
  end

  let(:operator) { create(:operator, password: 'Password123', password_confirmation: 'Password123') }
  let(:request_ip) { '192.168.1.1' }

  before do
    routes.draw do
      get 'public_action' => 'test_authentication#public_action'
      get 'protected_action' => 'test_authentication#protected_action'
    end

    allow(controller.request).to receive(:remote_ip).and_return(request_ip)
  end

  describe '#authenticate_operator' do
    context 'when 正しい資格情報のとき' do
      it '運用者を返す' do
        expect(controller.authenticate_operator(operator.email, 'Password123')).to eq(operator)
      end

      it 'メールアドレスの表記ゆれを吸収する' do
        expect(controller.authenticate_operator("  #{operator.email.upcase} ", 'Password123')).to eq(operator)
      end

      it '失敗の記録を消す' do
        operator.update!(failed_logins_count: 3)

        controller.authenticate_operator(operator.email, 'Password123')

        expect(operator.reload.failed_logins_count).to eq(0)
      end

      it '成功したことを記録する' do
        allow(PrometheusMetrics).to receive(:track_authentication)

        controller.authenticate_operator(operator.email, 'Password123')

        expect(PrometheusMetrics).to have_received(:track_authentication)
          .with(:success, reason: nil, duration: kind_of(Float))
      end
    end

    context 'when 運用者が見つからないとき' do
      it 'nil を返す' do
        expect(controller.authenticate_operator('unknown@example.com', 'Password123')).to be_nil
      end

      it '理由を添えて記録する' do
        allow(PrometheusMetrics).to receive(:track_authentication)

        controller.authenticate_operator('unknown@example.com', 'Password123')

        expect(PrometheusMetrics).to have_received(:track_authentication)
          .with(:failed, reason: :user_not_found, duration: kind_of(Float))
      end
    end

    context 'when パスワードが違うとき' do
      it 'nil を返す' do
        expect(controller.authenticate_operator(operator.email, 'WrongPassword1')).to be_nil
      end

      it '失敗した回数を数える' do
        expect { controller.authenticate_operator(operator.email, 'WrongPassword1') }
          .to change { operator.reload.failed_logins_count }.by(1)
      end

      it '理由を添えて記録する' do
        allow(PrometheusMetrics).to receive(:track_authentication)

        controller.authenticate_operator(operator.email, 'WrongPassword1')

        expect(PrometheusMetrics).to have_received(:track_authentication)
          .with(:failed, reason: :invalid_credentials, duration: kind_of(Float))
      end
    end

    context 'when アカウントがロックされているとき' do
      let(:operator) { create(:operator, :locked, password: 'Password123', password_confirmation: 'Password123') }

      it 'nil を返す' do
        expect(controller.authenticate_operator(operator.email, 'Password123')).to be_nil
      end

      it '本人へ通知する' do
        expect { controller.authenticate_operator(operator.email, 'Password123') }
          .to have_enqueued_mail(SessionMailer, :notice)
      end

      it '理由を添えて記録する' do
        allow(PrometheusMetrics).to receive(:track_authentication)

        controller.authenticate_operator(operator.email, 'Password123')

        expect(PrometheusMetrics).to have_received(:track_authentication)
          .with(:failed, reason: :account_locked, duration: kind_of(Float))
      end
    end

    it '試行した内容をログへ残す' do
      allow(Rails.logger).to receive(:info)

      controller.authenticate_operator(operator.email, 'Password123')

      expect(Rails.logger).to have_received(:info).with(
        hash_including(event: 'authentication_attempt', result: :success, operator_id: operator.id, ip: request_ip)
      )
    end
  end

  describe '#login' do
    it 'セッションへ運用者を記録する' do
      controller.login(operator)

      expect(controller.session[:operator_id]).to eq(operator.id)
    end

    it 'ログイン中の運用者を返す' do
      expect(controller.login(operator)).to eq(operator)
    end

    it 'セッションを作り直して固定化攻撃を防ぐ' do
      controller.session[:malicious_data] = 'hacker_value'

      controller.login(operator)

      expect(controller.session[:malicious_data]).to be_nil
      expect(controller.session[:operator_id]).to eq(operator.id)
    end
  end

  describe '#logout' do
    before { controller.login(operator) }

    it 'セッションを破棄する' do
      controller.logout

      expect(controller.session[:operator_id]).to be_nil
    end

    it 'ログイン中の運用者を忘れる' do
      expect(controller.logout).to be_nil
      expect(controller.current_operator).to be_nil
    end
  end

  describe '#current_operator' do
    it 'ログインしていれば運用者を返す' do
      controller.session[:operator_id] = operator.id
      controller.send(:set_current_operator)

      expect(controller.current_operator).to eq(operator)
    end

    it 'ログインしていなければ nil を返す' do
      expect(controller.current_operator).to be_nil
    end
  end

  describe '#operator_signed_in?' do
    it 'ログインしていれば true を返す' do
      controller.session[:operator_id] = operator.id
      controller.send(:set_current_operator)

      expect(controller.operator_signed_in?).to be true
    end

    it 'ログインしていなければ false を返す' do
      expect(controller.operator_signed_in?).to be false
    end
  end

  describe '#require_authentication' do
    it 'ログインしていれば通す' do
      controller.session[:operator_id] = operator.id

      get :protected_action

      expect(response.body).to eq("protected for #{operator.email}")
    end

    it 'ログインしていなければログイン画面へ促す' do
      get :protected_action

      expect(response).to redirect_to(operator_cat_in_path)
      expect(flash[:alert]).to eq('セッションが切れました。再度ログインしてください。')
    end

    context 'when 文言を差し替えたとき' do
      before do
        I18n.backend.store_translations(:ja, authentication: { errors: { session_expired: 'カスタムメッセージ' } })
      end

      after { I18n.backend.reload! }

      it '差し替えた文言を使う' do
        get :protected_action

        expect(flash[:alert]).to eq('カスタムメッセージ')
      end
    end
  end

  describe '#set_current_operator' do
    it 'セッションから運用者を復元する' do
      controller.session[:operator_id] = operator.id

      expect(controller.send(:set_current_operator)).to eq(operator)
    end

    it '一度読み込んだ運用者は問い合わせ直さない' do
      controller.session[:operator_id] = operator.id
      controller.send(:set_current_operator)

      expect(Operator).not_to receive(:find_by)
      controller.send(:set_current_operator)
    end

    it 'セッションが空なら何もしない' do
      expect(controller.send(:set_current_operator)).to be_nil
    end

    it '見つからない運用者のセッションは破棄する' do
      controller.session[:operator_id] = 99_999

      expect(controller.send(:set_current_operator)).to be_nil
      expect(controller.session[:operator_id]).to be_nil
    end

    it 'アクションの前に呼ばれる' do
      controller.session[:operator_id] = operator.id

      get :public_action

      expect(controller.current_operator).to eq(operator)
    end
  end

  describe 'ビューへ公開するメソッド' do
    it 'current_operator を使える' do
      expect(controller.class._helper_methods).to include(:current_operator)
    end

    it 'operator_signed_in? を使える' do
      expect(controller.class._helper_methods).to include(:operator_signed_in?)
    end
  end
end
