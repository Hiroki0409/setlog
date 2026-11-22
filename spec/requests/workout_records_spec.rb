require "rails_helper"

RSpec.describe "トレーニング記録の登録", type: :request do
  let(:user) { create(:user) }
  let(:exercise) { user.exercises.create!(name: "ベンチプレス") }
  let(:other_exercise) { create(:user).exercises.create!(name: "スクワット") }
  let(:performed_on) { "2026-11-18" }
  let(:attributes) do
    { exercise_id: exercise.id, performed_on: performed_on, weight: "60.25", reps: "10", set_count: "2" }
  end
  let(:entry_path) { new_workout_record_path(exercise_id: exercise.id, performed_on: performed_on) }

  it "種目一覧に種目と実施日の選択フォームがある" do
    exercise
    other_exercise
    sign_in user

    get exercises_path

    expect(response.body).to include(%(action="#{new_workout_record_path}"), 'name="exercise_id"', 'name="performed_on"')
    expect(response.body).to include("ベンチプレス")
    expect(response.body).not_to include("スクワット")
  end

  it "選んだ種目と実施日で入力画面を開ける" do
    sign_in user

    get entry_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ベンチプレス", %(value="#{performed_on}"), 'name="workout_record[weight]"')
  end

  it "未ログインで入力画面を開くとログイン画面へ移動する" do
    get entry_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログインでの保存を拒否する" do
    expect {
      post workout_records_path, params: { workout_record: attributes }
    }.not_to change(WorkoutRecord, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "他人の種目で入力画面を開けない" do
    sign_in user

    get new_workout_record_path(exercise_id: other_exercise.id, performed_on: performed_on)

    expect(response).to have_http_status(:not_found)
    expect(response.body.b).to eq(Rails.root.join("public/404.html").binread)
  end

  it "他人の種目IDを指定した保存を拒否する" do
    sign_in user

    expect {
      post workout_records_path, params: { workout_record: attributes.merge(exercise_id: other_exercise.id) }
    }.not_to change(WorkoutRecord, :count)

    expect(response).to have_http_status(:not_found)
    expect(response.body.b).to eq(Rails.root.join("public/404.html").binread)
  end

  it "過去日の記録を保存し、同じ種目と実施日の画面に戻る" do
    sign_in user

    expect {
      post workout_records_path, params: { workout_record: attributes }
    }.to change { exercise.workout_records.count }.by(1)

    expect(response).to redirect_to(entry_path)
    expect(exercise.workout_records.sole).to have_attributes(
      performed_on: Date.iso8601(performed_on), weight: BigDecimal("60.25"), reps: 10, set_count: 2
    )
    follow_redirect!
    expect(response.body).to include("記録を保存しました。", "ベンチプレス", %(value="#{performed_on}"))
  end

  it "同じ種目・同じ日に内容の違う記録を追加できる" do
    sign_in user

    post workout_records_path, params: { workout_record: attributes }
    post workout_records_path, params: { workout_record: attributes.merge(weight: "65", reps: "8") }

    expect(response).to redirect_to(entry_path)
    expect(exercise.workout_records.pluck(:reps)).to contain_exactly(10, 8)
  end

  it "入力エラー時は入力値を残し、修正して保存できる" do
    sign_in user

    expect {
      post workout_records_path, params: { workout_record: attributes.merge(weight: "60kg", reps: "1.5") }
    }.not_to change(WorkoutRecord, :count)

    expect(response).to have_http_status(422)
    expect(response.body).to include("小数第2位まで", "回数は1〜2147483647の整数", "ベンチプレス")
    expect(response.body).to include('value="60kg"', 'value="1.5"', 'value="2"', %(value="#{performed_on}"))

    expect {
      post workout_records_path, params: { workout_record: attributes }
    }.to change { exercise.workout_records.count }.by(1)

    expect(response).to redirect_to(entry_path)
  end
end
