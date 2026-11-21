require "rails_helper"

RSpec.describe "本人の記録一覧", type: :request do
  let(:user) { create(:user) }
  let(:bench_press) { user.exercises.create!(name: "ベンチプレス") }
  let(:squat) { user.exercises.create!(name: "スクワット") }

  def record_on(exercise, date, weight, **overrides)
    attributes = {
      performed_on: date, weight: weight, reps: 10, set_count: 1,
      created_at: Time.utc(2026, 11, 19, 8)
    }
    exercise.workout_records.create!(attributes.merge(overrides))
  end

  it "未ログインでは記録一覧を開けない" do
    get workout_records_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "本人の記録だけを実施日・作成日時・IDの降順で表示する" do
    record_on(bench_press, "2026-11-19", "60.25", set_count: 2)
    record_on(squat, "2026-11-19", 80, reps: 6)
    record_on(bench_press, "2026-11-19", 65, reps: 8, created_at: Time.utc(2026, 11, 19, 9))
    record_on(bench_press, "2026-11-18", 40, created_at: Time.utc(2026, 11, 21, 8))
    foreign_exercise = create(:user).exercises.create!(name: "レッグプレス")
    record_on(foreign_exercise, "2026-11-20", 100)
    sign_in user

    get workout_records_path(exercise_id: foreign_exercise.id, performed_on: "2026-11-20")

    expect(response).to have_http_status(:ok)
    rows = Nokogiri::HTML(response.body).css(".workout-record-list > li").map do |item|
      [ item.at_css("time")["datetime"], item.at_css("strong").text, *item.css("dd").map(&:text) ]
    end

    expect(rows).to eq([
      [ "2026-11-19", "ベンチプレス", "65", "8", "1" ],
      [ "2026-11-19", "スクワット", "80", "6", "1" ],
      [ "2026-11-19", "ベンチプレス", "60.25", "10", "2" ],
      [ "2026-11-18", "ベンチプレス", "40", "10", "1" ]
    ])
    expect(response.body).not_to include("レッグプレス", "記録入力に戻る")
  end

  it "記録0件のときに案内と種目一覧へのリンクを表示する" do
    sign_in user

    get workout_records_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("まだ記録がありません。", %(href="#{exercises_path}"))
  end

  it "種目一覧・記録入力画面から一覧へ移動し、元の入力画面へ戻れる" do
    sign_in user

    get exercises_path
    expect(response.body).to include(%(href="#{workout_records_path}"))

    entry_path = new_workout_record_path(exercise_id: bench_press.id, performed_on: "2026-11-20")
    get entry_path
    links = Nokogiri::HTML(response.body).css("a")
    list_link = links.find { |link| link.text == "記録一覧" }
    expect(list_link["href"]).to eq(workout_records_path(exercise_id: bench_press.id, performed_on: "2026-11-20"))

    get list_link["href"]
    links = Nokogiri::HTML(response.body).css("a")
    return_link = links.find { |link| link.text == "記録入力に戻る" }
    expect(return_link["href"]).to eq(entry_path)
  end
end
