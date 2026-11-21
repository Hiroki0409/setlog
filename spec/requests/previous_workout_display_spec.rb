require "rails_helper"

RSpec.describe "記録入力画面の前回記録", type: :request do
  let(:user) { create(:user) }
  let(:exercise) { user.exercises.create!(name: "ベンチプレス") }
  let(:input_date) { "2026-11-20" }
  let(:entry_path) { new_workout_record_path(exercise_id: exercise.id, performed_on: input_date) }
  let(:attributes) do
    { exercise_id: exercise.id, performed_on: input_date, weight: "40", reps: "10", set_count: "1" }
  end

  before { sign_in user }

  def record_on(date, weight:, reps:, set_count: 1, for_exercise: exercise)
    for_exercise.workout_records.create!(performed_on: date, weight: weight, reps: reps, set_count: set_count)
  end

  def previous_rows
    Nokogiri::HTML(response.body).css("#previous-workout-records tbody tr").map do |row|
      row.css("td").map(&:text)
    end
  end

  it "前回の実施日と3件すべての重量・回数・セット数を表示する" do
    record_on("2026-11-18", weight: 40, reps: 10)
    record_on("2026-11-18", weight: 60, reps: 10, set_count: 2)
    record_on("2026-11-18", weight: 60, reps: 8)
    record_on("2026-11-17", weight: 30, reps: 10)

    get entry_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('datetime="2026-11-18"')
    expect(previous_rows).to eq([ [ "40", "10", "1" ], [ "60", "10", "2" ], [ "60", "8", "1" ] ])
  end

  it "選び直した種目と入力対象日に応じて前回の記録を表示する" do
    other_exercise = user.exercises.create!(name: "スクワット")
    record_on("2026-11-16", weight: 30, reps: 10)
    record_on("2026-11-18", weight: 60, reps: 8)
    record_on("2026-11-17", weight: 80, reps: 6, for_exercise: other_exercise)

    get new_workout_record_path(exercise_id: exercise.id, performed_on: "2026-11-18")
    expect(previous_rows).to eq([ [ "30", "10", "1" ] ])

    get new_workout_record_path(exercise_id: other_exercise.id, performed_on: "2026-11-18")
    expect(previous_rows).to eq([ [ "80", "6", "1" ] ])
  end

  it "今回の記録を保存したあとも前回の全記録を表示する" do
    record_on("2026-11-18", weight: 60, reps: 10, set_count: 2)
    record_on("2026-11-18", weight: 60, reps: 8)

    expect {
      post workout_records_path, params: { workout_record: attributes }
    }.to change { exercise.workout_records.count }.by(1)

    expect(response).to redirect_to(entry_path)
    follow_redirect!
    expect(response.body).to include("記録を保存しました。")
    expect(previous_rows).to eq([ [ "60", "10", "2" ], [ "60", "8", "1" ] ])
  end

  it "前回がなければ案内が表示され、今回の記録を保存できる" do
    get entry_path
    expect(response.body).to include("この実施日より前の記録はありません。")

    expect {
      post workout_records_path, params: { workout_record: attributes }
    }.to change { exercise.workout_records.count }.by(1)

    follow_redirect!
    expect(response.body).to include("記録を保存しました。", "この実施日より前の記録はありません。")
  end

  it "入力エラー後も前回の記録と今回の入力値を表示する" do
    record_on("2026-11-18", weight: "60.25", reps: 8, set_count: 2)

    post workout_records_path, params: { workout_record: attributes.merge(reps: "1.5") }

    expect(response).to have_http_status(422)
    expect(response.body).to include("入力内容を確認してください。", 'value="1.5"', %(value="#{input_date}"))
    expect(previous_rows).to eq([ [ "60.25", "8", "2" ] ])
  end

  it "実施日が不正なら前回を表示せず、日付を入力できる" do
    record_on("2026-11-18", weight: 60, reps: 8)

    get new_workout_record_path(exercise_id: exercise.id, performed_on: "2026-11-20abc")

    expect(response.body).to include("実施日を選ぶと前回の記録が表示されます。")
    expect(previous_rows).to be_empty
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('input[type="date"][name="workout_record[performed_on]"]')).to be_present
  end
end
