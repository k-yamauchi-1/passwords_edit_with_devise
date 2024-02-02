# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :assert_reset_token_passed, if: :user_signed_in?
  skip_before_action :require_no_authentication, if: :user_signed_in?
  # ▲ only: が効かない（if: と併用不可? 詳細不明）ため ▼ を別途指定
  before_action :require_no_authentication, only: [:new]  # skip~ より前だと効かない

  # PUT /resource/password
  def update
    return super unless user_signed_in?

    if current_user.update_with_password(update_pw_params)
      bypass_sign_in(current_user)  # PW変更時の強制ログアウト回避のため bypass_~ を使用
      flash[:success] = "Password changed!"
      redirect_to root_path
    else
      flash[:danger] = "Failed to change password"
      render 'users/passwords/edit', status: :unprocessable_entity
    end
  end

  protected
    def update_pw_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
end
