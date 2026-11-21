require "rails_helper"

RSpec.describe "本人の記録の編集", type: :request do
  let(:user) { create(:user) }
  let(:exercise) { user.exercises.create!(name: "ベンチプレス") }
  let(:squat) { user.exercises.create!(name: "スクワット") }
  let(:foreign_exercise) { create(:user).exercises.create!(name: "レッグプレス") }
  let(:record) do
    exercise.workout_records.create!(performed_on: "2026-11-19", weight: "60.25", reps: 10, set_count: 2)
  end
  let(:foreign_record) do
    foreign_exercise.workout_records.create!(performed_on: "2026-11-19", weight: "100", reps: 10, set_count: 1)
  end
  let(:updated_attributes) do
    { exercise_id: squat.id, performed_on: "2026-11-18", weight: "77.50", reps: "8", set_count: "3" }
  end

  before { sign_in user }

  it "一覧から編集画面を開き、保存済みの値と本人の種目を表示する" do
    record
    squat
    foreign_exercise
    get workout_records_path
    expect(response.body).to include(%(href="#{edit_workout_record_path(record)}"))

    get edit_workout_record_path(record)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ベンチプレス", "スクワット", 'value="60.25"', 'value="2026-11-19"')
    expect(response.body).not_to include("レッグプレス")
    cancel = Nokogiri::HTML(response.body).css("a").find { |link| link.text == "キャンセル" }
    expect(cancel["href"]).to eq(workout_records_path)
  end

  it "種目・実施日・数値を更新して一覧へ戻る" do
    patch workout_record_path(record), params: { workout_record: updated_attributes }

    expect(response).to redirect_to(workout_records_path)
    expect(record.reload).to have_attributes(
      exercise: squat, performed_on: Date.new(2026, 11, 18),
      weight: BigDecimal("77.50"), reps: 8, set_count: 3
    )
    follow_redirect!
    expect(response.body).to include("記録を更新しました。", "スクワット", "77.5")
  end

  it "検証エラー時は保存済みの記録を保ち、入力を直して更新できる" do
    patch workout_record_path(record), params: { workout_record: updated_attributes.merge(reps: "1.5") }

    expect(response).to have_http_status(422)
    expect(response.body).to include('value="1.5"', 'value="77.50"', 'value="2026-11-18"')
    selected = Nokogiri::HTML(response.body).at_css('select[name="workout_record[exercise_id]"] option[selected]')
    expect(selected["value"]).to eq(squat.id.to_s)
    expect(record.reload).to have_attributes(exercise: exercise, weight: BigDecimal("60.25"), reps: 10)

    patch workout_record_path(record), params: { workout_record: updated_attributes }

    expect(response).to redirect_to(workout_records_path)
    expect(record.reload.reps).to eq(8)
  end

  it "他人の記録の編集画面を開けない" do
    get edit_workout_record_path(foreign_record)

    expect(response).to have_http_status(:not_found)
  end

  it "他人の記録を更新できない" do
    patch workout_record_path(foreign_record), params: { workout_record: updated_attributes }

    expect(response).to have_http_status(:not_found)
    expect(foreign_record.reload.exercise).to eq(foreign_exercise)
    expect(foreign_record.weight).to eq(BigDecimal("100"))
  end

  it "本人の記録でも他人の種目への付け替えはできない" do
    patch workout_record_path(record), params: { workout_record: updated_attributes.merge(exercise_id: foreign_exercise.id) }

    expect(response).to have_http_status(:not_found)
    expect(record.reload.exercise).to eq(exercise)
    expect(record.weight).to eq(BigDecimal("60.25"))
  end

  it "編集した数値と実施日が前回の記録表示に反映される" do
    record
    exercise.workout_records.create!(performed_on: "2026-11-18", weight: 40, reps: 10, set_count: 1)
    entry_path = new_workout_record_path(exercise_id: exercise.id, performed_on: "2026-11-20")
    same_day_update = updated_attributes.merge(exercise_id: exercise.id, performed_on: "2026-11-19")

    patch workout_record_path(record), params: { workout_record: same_day_update }
    expect(response).to redirect_to(workout_records_path)

    get entry_path
    previous = Nokogiri::HTML(response.body).at_css(".previous-workout")
    expect(previous.at_css("time")["datetime"]).to eq("2026-11-19")
    expect(previous.css("tbody td").map(&:text)).to eq([ "77.5", "8", "3" ])

    patch workout_record_path(record), params: { workout_record: same_day_update.merge(performed_on: "2026-11-20") }
    expect(response).to redirect_to(workout_records_path)

    get entry_path
    previous = Nokogiri::HTML(response.body).at_css(".previous-workout")
    expect(previous.at_css("time")["datetime"]).to eq("2026-11-18")
    expect(previous.css("tbody td").map(&:text)).to eq([ "40", "10", "1" ])
  end
end
