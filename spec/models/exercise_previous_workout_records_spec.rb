require "rails_helper"

RSpec.describe Exercise, "#previous_workout_records", type: :model do
  let(:user) { create(:user) }
  let(:exercise) { user.exercises.create!(name: "ベンチプレス") }
  let(:input_date) { Date.new(2026, 11, 20) }

  def record_on(day, for_exercise: exercise, **overrides)
    attributes = { performed_on: Date.new(2026, 11, day), weight: 60, reps: 10, set_count: 1 }
    for_exercise.workout_records.create!(attributes.merge(overrides))
  end

  it "前回の実施日の3件を作成日時とIDの昇順で返す" do
    early_time = Time.utc(2026, 11, 18, 8)
    late = record_on(18, weight: 60, reps: 8, created_at: early_time + 1.hour)
    first = record_on(18, weight: 40, reps: 10, created_at: early_time)
    second = record_on(18, weight: 60, reps: 10, created_at: early_time)
    record_on(17, created_at: Time.utc(2026, 11, 19, 8))

    expect(exercise.previous_workout_records(before: input_date)).to eq([ first, second, late ])
  end

  it "入力対象日の記録を追加しても前回の結果は変わらない" do
    previous = record_on(18)

    expect {
      record_on(20, weight: 40)
    }.not_to change { exercise.previous_workout_records(before: input_date).pluck(:id) }

    expect(exercise.previous_workout_records(before: input_date)).to eq([ previous ])
  end

  it "当日・未来日・別種目・別ユーザーの記録を除く" do
    previous = record_on(16)
    other_exercise = user.exercises.create!(name: "スクワット")
    other_users_exercise = create(:user).exercises.create!(name: "ベンチプレス")
    record_on(20)
    record_on(21)
    record_on(16, for_exercise: other_exercise)
    record_on(19, for_exercise: other_exercise)
    record_on(16, for_exercise: other_users_exercise)
    record_on(18, for_exercise: other_users_exercise)

    expect(exercise.previous_workout_records(before: input_date)).to eq([ previous ])
  end

  it "過去日を入力するときも、その日より前の最新日を選ぶ" do
    previous = record_on(16)
    record_on(18)
    record_on(19)

    expect(exercise.previous_workout_records(before: Date.new(2026, 11, 18))).to eq([ previous ])
  end

  it "入力対象日より前に記録がなければ空になる" do
    record_on(20)
    record_on(21)

    expect(exercise.previous_workout_records(before: input_date)).to be_empty
  end

  it "記録を編集すると内容と実施日の変更が取得結果に反映される" do
    older = record_on(16)
    previous = record_on(18)
    previous.update!(reps: 8)

    expect(exercise.previous_workout_records(before: input_date).pluck(:reps)).to eq([ 8 ])

    previous.update!(performed_on: input_date)

    expect(exercise.previous_workout_records(before: input_date)).to eq([ older ])
  end

  it "前回の記録を削除すると、残った記録か次に新しい実施日を返す" do
    older = record_on(16)
    first = record_on(18, weight: 40)
    second = record_on(18, weight: 60)
    first.destroy!

    expect(exercise.previous_workout_records(before: input_date)).to eq([ second ])

    second.destroy!

    expect(exercise.previous_workout_records(before: input_date)).to eq([ older ])
  end
end
