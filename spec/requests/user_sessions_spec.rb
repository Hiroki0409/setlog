require "rails_helper"

RSpec.describe "ログインとログアウト", type: :request do
  let(:password) { "session-test-password" }
  let(:user) { create(:user, password: password) }
  let(:credentials) { { email: user.email, password: password } }

  it "TOPからログイン画面へ進める" do
    get root_path
    expect(response.body).to include(%(href="#{new_user_session_path}"))

    get new_user_session_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[email]"', 'name="user[password]"')
  end

  it "正しい認証情報でログインして種目一覧へ進む" do
    post user_session_path, params: { user: credentials }

    expect(response).to redirect_to(exercises_path)
    follow_redirect!
    expect(response.body).to include("種目一覧", "ログアウト")
  end

  it "誤ったパスワードではエラーを表示し、ログインできない" do
    post user_session_path, params: { user: credentials.merge(password: "wrong-password") }

    expect(response).to have_http_status(422)
    expect(response.body).to include("メールアドレスとパスワードを確認して、ログインしてください。")

    get root_path
    expect(response.body).to include(%(href="#{new_user_session_path}"))
    expect(response.body).not_to include("ログイン中です。")
  end

  it "ログアウトしてTOPへ戻ると認証が解除されている" do
    post user_session_path, params: { user: credentials }
    follow_redirect!
    expect(response.body).to include("種目一覧", "ログアウト")

    delete destroy_user_session_path

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include(%(href="#{new_user_session_path}"))
    expect(response.body).not_to include("ログイン中です。")
  end
end
