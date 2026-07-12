# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operator::OperatorSessionsController, type: :controller do
  describe 'GET #new' do
    it 'redirects an already signed-in operator to the operates page' do
      operator = create(:operator)
      session[:operator_id] = operator.id

      get :new

      expect(response).to redirect_to(operator_operates_path)
    end
  end
end
