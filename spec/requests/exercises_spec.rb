require "rails_helper"

RSpec.describe "種目一覧と登録", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  it "未ログインでは一覧を表示できない" do
    get exercises_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログインの登録を拒否する" do
    expect {
      post exercises_path, params: { exercise: { name: "ベンチプレス", user_id: user.id } }
    }.not_to change { user.exercises.count }

    expect(response).to redirect_to(new_user_session_path)
  end

  it "本人の種目だけを一覧に表示する" do
    user.exercises.create!(name: "ベンチプレス")
    other_user.exercises.create!(name: "スクワット")
    sign_in user

    get exercises_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ベンチプレス")
    expect(response.body).not_to include("スクワット")
  end

  it "種目が0件なら案内と登録フォームを表示する" do
    sign_in user

    get exercises_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("まだ種目が登録されていません", 'name="exercise[name]"')
  end

  it "他人のユーザーIDが送られてもログイン中の本人に登録する" do
    sign_in user

    expect {
      post exercises_path, params: { exercise: { name: "ベンチプレス", user_id: other_user.id } }
    }.to change { user.exercises.count }.by(1)

    expect(response).to redirect_to(exercises_path)
    expect(user.exercises.exists?(name: "ベンチプレス")).to be(true)
    expect(other_user.exercises.exists?(name: "ベンチプレス")).to be(false)
  end

  it "空白だけの名前を拒否し、エラーと既存の種目を表示する" do
    user.exercises.create!(name: "ベンチプレス")
    sign_in user

    expect {
      post exercises_path, params: { exercise: { name: "　" } }
    }.not_to change(Exercise, :count)

    expect(response).to have_http_status(422)
    expect(response.body).to include("種目名を入力してください。", "ベンチプレス")
  end

  it "本人の重複名を拒否し、理由と入力値を表示する" do
    user.exercises.create!(name: "ベンチプレス")
    sign_in user

    expect {
      post exercises_path, params: { exercise: { name: "ベンチプレス" } }
    }.not_to change(Exercise, :count)

    expect(response).to have_http_status(422)
    expect(response.body).to include("この種目名はすでに登録されています。", 'value="ベンチプレス"')
  end
end
