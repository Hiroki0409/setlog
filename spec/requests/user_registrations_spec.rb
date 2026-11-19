require "rails_helper"

RSpec.describe "新規登録", type: :request do
  let(:attributes) do
    {
      email: "new-user@example.com",
      password: "example-password",
      password_confirmation: "example-password"
    }
  end

  it "TOPページから登録画面へ移動できる" do
    get root_path

    expect(response.body).to include(%(href="#{new_user_registration_path}"))
  end

  it "登録画面にメールとパスワードの入力欄が表示される" do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[email]"',
                                     'name="user[password]"',
                                     'name="user[password_confirmation]"')
  end

  it "登録に成功するとログインした状態でTOPページへ戻る" do
    expect {
      post user_registration_path, params: { user: attributes }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("ログイン中です。")
  end

  it "メールアドレスが不正なら登録画面に理由を表示する" do
    expect {
      post user_registration_path, params: { user: attributes.merge(email: "invalid-email") }
    }.not_to change(User, :count)

    expect(response).to have_http_status(422)
    expect(response.body).to include("メールアドレスの形式を確認してください。")
    expect(response.body).to include('value="invalid-email"')
  end

  it "メールアドレスが重複していれば登録画面に理由を表示する" do
    create(:user, email: attributes.fetch(:email))

    expect {
      post user_registration_path, params: { user: attributes }
    }.not_to change(User, :count)

    expect(response).to have_http_status(422)
    expect(response.body).to include("このメールアドレスはすでに登録されています。")
  end
end
