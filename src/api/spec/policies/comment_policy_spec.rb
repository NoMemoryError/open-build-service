require 'rails_helper'

RSpec.describe CommentPolicy do
  let(:anonymous_user) { create(:user_nobody) }
  let(:comment_author) { create(:confirmed_user, login: 'burdenski') }
  let(:admin_user) { create(:admin_user, login: 'admin') }
  let(:user) { create(:confirmed_user, login: 'tom') }
  let(:other_user) { create(:confirmed_user, login: 'other_user') }
  let(:project) { create(:project, name: 'CommentableProject') }
  let(:package) { create(:package, :as_submission_source, name: 'CommentablePackage', project: project) }
  let(:comment) { create(:comment_project, commentable: project, user: comment_author) }
  let(:request) { create(:bs_request_with_submit_action, target_package: package) }
  let(:comment_on_package) { create(:comment_package, commentable: package, user: comment_author) }
  let(:comment_on_request) { create(:comment_request, commentable: request, user: comment_author) }
  let(:comment_deleted_user) { create(:comment_project, commentable: project, user: anonymous_user) }

  subject { CommentPolicy }

  shared_examples 'update/delete shared permissions' do
    it 'doesnot allow unauthenticated users to update/delete comments' do
      expect(subject).not_to permit(nil, comment)
    end

    it 'allows admin to update/delete any comment' do
      expect(subject).to permit(admin_user, comment)
    end

    it 'allow users to update/delete their own comments' do
      expect(subject).to permit(comment_author, comment)
    end

    it 'doesnot allow user to update/delete comment by other user' do
      expect(subject).not_to permit(user, comment)
    end
  end

  permissions :update? do
    it_behaves_like 'update/delete shared permissions'
  end

  permissions :destroy? do
    it_behaves_like 'update/delete shared permissions'

    it 'Logged users can destroy comments by deleted users' do
      expect(subject).to permit(comment_author, comment_deleted_user)
    end

    context 'with a comment of a Package' do
      before do
        allow(user).to receive(:has_local_permission?).with('change_package', package).and_return(true)
        allow(other_user).to receive(:has_local_permission?).with('change_package', package).and_return(false)
      end

      it { expect(subject).to permit(user, comment_on_package) }
      it { expect(subject).not_to permit(other_user, comment_on_package) }
    end

    context 'with a comment of a Project' do
      before do
        allow(user).to receive(:has_local_permission?).with('change_project', project).and_return(true)
        allow(other_user).to receive(:has_local_permission?).with('change_project', project).and_return(false)
      end

      it { expect(subject).to permit(user, comment) }
      it { expect(subject).not_to permit(other_user, comment) }
    end

    context 'with a comment of a Request' do
      before do
        allow(request).to receive(:is_target_maintainer?).with(user).and_return(true)
        allow(request).to receive(:is_target_maintainer?).with(other_user).and_return(false)
      end

      it { expect(subject).to permit(user, comment_on_request) }
      it { expect(subject).not_to permit(other_user, comment_on_request) }
    end
  end
end
