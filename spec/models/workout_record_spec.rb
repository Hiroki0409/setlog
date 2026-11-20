require "rails_helper"

RSpec.describe WorkoutRecord, type: :model do
  let(:exercise) { create(:user).exercises.create!(name: "ベンチプレス") }
  let(:attributes) do
    { performed_on: "2026-11-19", weight: "60.25", reps: "10", set_count: "2" }
  end

  it "フォームの文字列から記録を保存できる" do
    record = exercise.workout_records.create!(attributes).reload

    expect(record).to have_attributes(
      exercise: exercise, performed_on: Date.new(2026, 11, 19),
      weight: BigDecimal("60.25"), reps: 10, set_count: 2
    )
  end

  it "重量0・回数1・セット数1を保存できる" do
    record = exercise.workout_records.create!(attributes.merge(weight: "0", reps: "1", set_count: "1"))

    expect(record.reload).to have_attributes(weight: BigDecimal("0"), reps: 1, set_count: 1)
  end

  it "重量と回数・セット数の上限を保存できる" do
    record = exercise.workout_records.create!(
      attributes.merge(weight: "9999.99", reps: "2147483647", set_count: "2147483647")
    )

    expect(record.reload).to have_attributes(
      weight: BigDecimal("9999.99"), reps: 2_147_483_647, set_count: 2_147_483_647
    )
  end

  it "範囲外・小数3桁以上・単位付きや不正な重量を保存しない" do
    [ "-0.01", "10000", "1.005", "1.000", "60kg", "abc", "" ].each do |weight|
      record = exercise.workout_records.build(attributes.merge(weight: weight))

      expect(record.save).to be(false), "重量 #{weight.inspect} が保存されました"
      expect(record.errors[:weight]).not_to be_empty
    end
  end

  it "不正な回数とセット数を丸めて保存しない" do
    %i[ reps set_count ].each do |field|
      [ "0", "-1", "1.5", 1.5, "12回", "abc", "2147483648", "" ].each do |value|
        record = exercise.workout_records.build(attributes.merge(field => value))

        expect(record.save).to be(false), "#{field} の #{value.inspect} が保存されました"
        expect(record.errors[field]).not_to be_empty
      end
    end
  end

  it "空欄・存在しない日付・余分な文字を含む日付を保存しない" do
    [ "", "2026-02-30", "2026-11-19abc", "0999-12-31" ].each do |date|
      record = exercise.workout_records.build(attributes.merge(performed_on: date))

      expect(record.save).to be(false), "日付 #{date.inspect} が保存されました"
      expect(record.errors[:performed_on]).not_to be_empty
    end
  end

  it "同じ種目・同じ実施日に内容の違う記録を複数保存できる" do
    exercise.workout_records.create!(attributes)
    exercise.workout_records.create!(attributes.merge(weight: "65.00", reps: "8"))

    expect(exercise.workout_records.where(performed_on: attributes[:performed_on]).pluck(:weight, :reps))
      .to contain_exactly([ BigDecimal("60.25"), 10 ], [ BigDecimal("65.00"), 8 ])
  end

  it "存在しない種目への紐付けをDBが拒否する" do
    record = described_class.new(attributes.merge(exercise_id: -1))

    expect { record.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "記録を持つ種目の削除をDBが拒否する" do
    exercise.workout_records.create!(attributes)

    expect { exercise.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
