# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operator::LineGroupsController, type: :controller do
  let(:operator) { create(:operator) }

  before { session[:operator_id] = operator.id }

  describe 'DELETE #destroy' do
    it 'destroys the line group' do
      group = create(:line_group)

      expect do
        delete :destroy, params: { id: group.id }
      end.to change(LineGroup, :count).by(-1)
    end

    it 'redirects to the line groups index with a success message' do
      group = create(:line_group)

      delete :destroy, params: { id: group.id }

      expect(response).to redirect_to(operator_line_groups_path)
      expect(flash[:success]).to eq('LINEグループ情報を削除しました。')
    end
  end

  describe 'authentication with an invalid session' do
    it 'resets the session and redirects to login when the operator lookup raises RecordNotFound' do
      session[:operator_id] = 999
      allow(Operator).to receive(:find_by).and_raise(ActiveRecord::RecordNotFound)

      delete :destroy, params: { id: 1 }

      expect(response).to redirect_to(operator_cat_in_path)
    end
  end
end
