require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  test "should redirect from new when logged in" do
    login_as(users(:one))
    get new_user_registration_path
    assert_redirected_to root_path
  end

  test "should redirect from create when logged in" do
    login_as(users(:one))
    assert_no_difference 'User.count' do
      post user_registration_path, params: { user: {
        name: "MyName1", email: "em@i.l", password: "passwd"
      } }
    end
    assert_redirected_to root_path
  end

  test "user can be created when not logged in" do
    assert_difference 'User.count', 1 do
      post user_registration_path, params: { user: {
        name: "MyName1", email: "em@i.l", password: "passwd"
      } }
    end
  end

  test "should redirect from update when not logged in" do
    @user = users(:one)

    patch user_registration_path, params: { user: { job: "99999999" } }
    assert_redirected_to new_user_session_path

    actual = User.find(@user.id)
    assert_equal @user.job, actual.job
  end

  test "can be updated by right user" do
    @user = users(:one)
    login_as(@user)
    assert_no_difference 'User.count' do
      patch user_registration_path, params: { user: { name: "edited_name" } }
    end

    actual = User.find(@user.id)
    assert_equal "edited_name", actual.name
  end

  test "cannot sign in with wrong email" do
    post user_session_path, params: { user: { email: "unavail@b.le" } }
    assert_response :unprocessable_entity
  end

  test "cannot get password reset form when logged in" do
    login_as(users(:one))
    get new_user_password_path
    assert_redirected_to root_path
  end

  test "can get password edit form when logged in also" do
    login_as(users(:one))
    get edit_user_password_path
    assert_response :success
  end

  test "password cannot be changed without reset token when not logged in" do
    assert_no_difference 'User.count' do
      patch user_password_path, params: { user: {
        password: "changed_pw", password_confirmation: "changed_pw"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "password cannot be changed without current password" do
    @user = User.create({
      name: "MyName1", email: "em@i.l", password: "passwd"
    })
    login_as(@user)

    assert_no_difference 'User.count' do
      patch user_password_path, params: { user: {
        password: "changed_pw", password_confirmation: "changed_pw"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "password cannot be changed with wrong current password" do
    @user = User.create({
      name: "MyName1", email: "em@i.l", password: "passwd"
    })
    login_as(@user)

    assert_no_difference 'User.count' do
      patch user_password_path, params: { user: {
        current_password: "paswd", password: "changed_pw", password_confirmation: "changed_pw"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "password cannot be changed with wrong confirmation" do
    @user = User.create({
      name: "MyName1", email: "em@i.l", password: "passwd"
    })
    login_as(@user)

    assert_no_difference 'User.count' do
      patch user_password_path, params: { user: {
        current_password: "passwd", password: "changed_pw", password_confirmation: 'changed_psw'
      } }
    end
    assert_response :unprocessable_entity
  end

  test "password can be changed with right inputs" do
    @user = User.create({
      name: "MyName1", job: "PG", email: "em@i.l", password: "passwd"
    })
    login_as(@user)

    assert_no_difference 'User.count' do
      patch user_password_path, params: { user: {
        name: "edited_name", job: "SE", current_password: "passwd",
        password: "changed_pw", password_confirmation: "changed_pw"
      } }
    end
    assert_redirected_to root_path

    # only password should be updated
    assert_equal @user.name, User.find(@user.id).name
    assert_equal @user.job, User.find(@user.id).job

    # once signed out, then sign in with edited passwd to verify changing pw successfully
    delete destroy_user_session_path
    assert_redirected_to root_path

    post user_session_path, params: { user: {
      email: "em@i.l", password: "changed_pw"
    } }
    assert_redirected_to root_path
  end

  test "should redirect from destroy when not logged in" do
    assert_no_difference 'User.count' do
      delete user_registration_path
    end
    assert_redirected_to new_user_session_path
  end
end
