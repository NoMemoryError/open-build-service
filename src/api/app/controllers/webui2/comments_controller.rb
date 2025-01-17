module Webui2::CommentsController
  def webui2_create
    comment = @commented.comments.new(permitted_params)
    User.session!.comments << comment
    @commentable = comment.commentable

    respond_to do |format|
      if comment.save
        flash.now[:success] = 'Comment created successfully.'
        status = :ok
      else
        flash.now[:error] = "Failed to create comment: #{comment.errors.full_messages.to_sentence}."
        status = :unprocessable_entity
      end
      format.html do
        render(partial: 'webui2/webui/comment/comment_list', locals: { commentable: @commentable }, status: status)
      end
    end
  end

  def webui2_update
    comment = Comment.find(params[:id])
    authorize comment, :update?
    @commentable = comment.commentable
    respond_to do |format|
      if comment.update(permitted_params)
        flash.now[:success] = 'Comment updated successfully.'
        status = :ok
      else
        flash.now[:error] = 'Failed to update comment.'
        status = :unprocessable_entity
      end
      format.html do
        render(partial: 'webui2/webui/comment/comment_list', locals: { commentable: @commentable }, status: status)
      end
    end
  end

  def webui2_destroy
    comment = Comment.find(params[:id])
    authorize comment, :destroy?
    @commentable = comment.commentable

    respond_to do |format|
      if comment.blank_or_destroy
        flash.now[:success] = 'Comment deleted successfully.'
        status = :ok
      else
        flash.now[:error] = "Failed to delete comment: #{comment.errors.full_messages.to_sentence}."
        status = :unprocessable_entity
      end
      format.html do
        render(partial: 'webui2/webui/comment/comment_list', locals: { commentable: @commentable }, status: status)
      end
    end
  end
end
