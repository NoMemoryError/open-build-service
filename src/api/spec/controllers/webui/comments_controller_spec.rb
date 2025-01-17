require 'rails_helper'

RSpec.describe Webui::CommentsController, type: :controller do
  let(:user) { create(:confirmed_user, login: 'luck') }

  before do
    login user
  end

  describe 'POST #create' do
    let(:project) { create(:project) }
    let(:package) { create(:package, project: project) }
    let(:bs_request) { create(:set_bugowner_request) }

    context 'with a valid comment' do
      RSpec.shared_examples 'saving a comment' do
        before do
          params = { comment: { body: "This #{commentable.model_name.singular} is AWESOME!" },
                     commentable_type: commentable.class, commentable_id: commentable.id }
          post :create, params: params
        end

        it { expect(flash[:success]).to eq('Comment was successfully created.') }
        it { expect(commentable.comments.first.body).to eq("This #{commentable.model_name.singular} is AWESOME!") }
      end

      context 'of a project' do
        let(:commentable) { project }
        include_examples 'saving a comment'
      end

      context 'of a package' do
        let(:commentable) { package }
        include_examples 'saving a comment'
      end

      context 'of a bs_request' do
        let(:commentable) { bs_request }
        include_examples 'saving a comment'
      end
    end

    context 'saving a comment without body' do
      before do
        params = { comment: { body: '' }, commentable_type: package.class, commentable_id: package.id }
        post :create, params: params
      end

      it { expect(flash[:error]).to eq("Comment can't be saved: Body can't be blank.") }
      it { expect(package.comments.count).to eq(0) }
    end

    context 'saving a comment of a non-commentable class' do
      let(:distribution) { create(:distribution) }

      it 'should not created' do
        params = { comment: { body: 'Wonderful Package' }, commentable_type: distribution.class, commentable_id: distribution.id }
        expect { post :create, params: params }.to raise_error(NoMethodError)
      end
    end

    context "does not allow to overwrite the comment's user" do
      it 'should not created' do
        params = { comment: { body: 'This project is AWESOME!', user_id: user }, commentable_type: project.class, commentable_id: project.id }
        expect { post :create, params: params }.to raise_error(ActionController::UnpermittedParameters)
      end
    end
  end

  describe 'PUT/PATCH #update' do
    let(:comment) { create(:comment_project, user: user) }
    let(:updated_body) { 'Updated body' }

    before { patch :update, params: { id: comment.id, comment: { body: updated_body } } }

    context 'comments update with empty body' do
      let(:updated_body) { '' }

      it { expect(flash[:error]).to eq('Failed to update comment.') }
      it { expect(comment.reload.body).not_to(eq(updated_body)) }
    end

    context 'user updates their own comments' do
      it { expect(flash[:success]).to eq('Comment updated successfully.') }
      it { expect(comment.reload.body).to eq(updated_body) }
    end

    context 'cannot update another user comments' do
      let(:comment) { create(:comment_project) }

      it { expect(flash[:error]).to eq('Sorry, you are not authorized to update this Comment.') }
      it { expect(comment.reload.body).not_to(eq(updated_body)) }
    end

    context 'admin user can update all comments' do
      let(:user) { create(:admin_user, login: 'Admin') }

      it { expect(flash[:success]).to eq('Comment updated successfully.') }
      it { expect(comment.reload.body).to eq(updated_body) }
    end
  end

  describe 'DELETE #destroy' do
    let(:admin) { create(:admin_user, login: 'Admin') }
    let(:comment) { create(:comment_project, user: user) }
    let(:other_comment) { create(:comment_project) }

    context 'can destroy own comments' do
      before do
        delete :destroy, params: { id: comment.id }
      end

      it { expect(flash[:success]).to eq('Comment deleted successfully.') }
      it { expect(Comment.where(id: comment.id)).to eq([]) }
    end

    context 'cannot destroy comment of somebody else' do
      before do
        delete :destroy, params: { id: other_comment.id }
      end

      it { expect(flash[:success]).to eq(nil) }
      it { expect(Comment.where(id: comment.id)).to eq([comment]) }
    end

    context 'admin can destroy comments not owned by him' do
      before do
        login admin
        delete :destroy, params: { id: other_comment.id }
      end

      it { expect(flash[:success]).to eq('Comment deleted successfully.') }
      it { expect(Comment.where(id: other_comment.id)).to eq([]) }
    end
  end
end
