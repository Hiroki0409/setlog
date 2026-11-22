require "rails_helper"

RSpec.describe "本人の記録の削除", type: :request do
  let(:user) { create(:user) }
  let(:exercise) { user.exercises.create!(name: "ベンチプレス") }
  let(:record) { record_on("2026-11-19", "60.25") }
  let(:foreign_record) do
    foreign_exercise = create(:user).exercises.create!(name: "スクワット")
    foreign_exercise.workout_records.create!(performed_on: "2026-11-19", weight: 100, reps: 10, set_count: 2)
  end

  def record_on(date, weight)
    exercise.workout_records.create!(performed_on: date, weight: weight, reps: 8, set_count: 2)
  end

  it "一覧から削除確認へ進み、対象の値と削除ボタンを確認できる" do
    record
    sign_in user

    get workout_records_path
    expect(response.body).to include(%(href="#{confirm_delete_workout_record_path(record)}"))

    get confirm_delete_workout_record_path(record)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("記録の削除確認", "ベンチプレス", 'datetime="2026-11-19"')
    document = Nokogiri::HTML(response.body)
    expect(document.css(".workout-record-values dd").map(&:text)).to eq([ "60.25", "8", "2" ])
    form = document.at_css("form")
    expect(form["action"]).to eq(workout_record_path(record))
    expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
  end

  it "キャンセルで一覧へ戻っても記録が残る" do
    record
    sign_in user
    get confirm_delete_workout_record_path(record)
    cancel = Nokogiri::HTML(response.body).css("a").find { |link| link.text == "キャンセル" }

    expect(cancel["href"]).to eq(workout_records_path)
    expect { get cancel["href"] }.not_to change(WorkoutRecord, :count)
    expect(response.body).to include("60.25")
  end

  it "確定した記録だけを削除して一覧へ戻る" do
    record
    remaining_record = record_on("2026-11-19", 70)
    sign_in user

    expect { delete workout_record_path(record) }.to change(WorkoutRecord, :count).by(-1)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(workout_records_path)
    expect(exercise.workout_records).to contain_exactly(remaining_record)
    follow_redirect!
    expect(response.body).to include("記録を削除しました。")
  end

  it "最後の記録を削除すると一覧に記録0件の案内が出る" do
    sign_in user

    delete workout_record_path(record)
    follow_redirect!

    expect(response.body).to include("記録を削除しました。", "まだ記録がありません。")
  end

  it "他人の記録の削除確認を開けない" do
    sign_in user

    get confirm_delete_workout_record_path(foreign_record)

    expect(response).to have_http_status(:not_found)
    expect(response.body.b).to eq(Rails.root.join("public/404.html").binread)
  end

  it "他人の記録を削除できない" do
    foreign_record
    sign_in user

    expect { delete workout_record_path(foreign_record) }.not_to change(WorkoutRecord, :count)

    expect(response).to have_http_status(:not_found)
    expect(response.body.b).to eq(Rails.root.join("public/404.html").binread)
  end

  it "未ログインでは削除確認も削除もできない" do
    record
    get confirm_delete_workout_record_path(record)
    expect(response).to redirect_to(new_user_session_path)

    expect { delete workout_record_path(record) }.not_to change(WorkoutRecord, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "前回の実施日の最後の記録を削除すると、さらに前の日か前回なしに切り替わる" do
    older = record_on("2026-11-18", 40)
    record
    sign_in user
    entry_path = new_workout_record_path(exercise_id: exercise.id, performed_on: "2026-11-20")

    delete workout_record_path(record)
    get entry_path
    previous = Nokogiri::HTML(response.body).at_css(".previous-workout")
    expect(previous.at_css("time")["datetime"]).to eq("2026-11-18")
    expect(previous.css("tbody td").map(&:text)).to eq([ "40", "8", "2" ])

    delete workout_record_path(older)
    get entry_path
    expect(response.body).to include("この実施日より前の記録はありません。")
  end
end
