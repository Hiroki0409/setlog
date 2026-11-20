require "rails_helper"

RSpec.describe Exercise, type: :model do
  let(:user) { create(:user) }
  let(:name) { "ベンチプレス" }

  it "本人の種目として100文字の名前を保存できる" do
    exercise = user.exercises.create!(name: "あ" * 100)

    expect(exercise.reload.name).to eq("あ" * 100)
    expect(exercise.user).to eq(user)
  end

  it "空白だけの種目名を拒否する" do
    exercise = user.exercises.build(name: " \t\u3000")

    expect(exercise).not_to be_valid
    expect(exercise.errors.of_kind?(:name, :blank)).to be(true)
  end

  it "101文字の種目名を拒否する" do
    exercise = user.exercises.build(name: "あ" * 101)

    expect(exercise).not_to be_valid
    expect(exercise.errors.of_kind?(:name, :too_long)).to be(true)
  end

  it "同じユーザーの同名種目を拒否する" do
    user.exercises.create!(name: name)
    exercise = user.exercises.build(name: name)

    expect(exercise).not_to be_valid
    expect(exercise.errors.of_kind?(:name, :taken)).to be(true)
  end

  it "別のユーザーなら同じ種目名を保存できる" do
    user.exercises.create!(name: name)
    other_user = create(:user)

    expect(other_user.exercises.create!(name: name)).to be_persisted
  end

  it "モデル検証をスキップしてもDBが名前のNULLを拒否する" do
    exercise = user.exercises.build(name: nil)

    expect { exercise.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "モデル検証をスキップしてもDBが本人内の同名種目を拒否する" do
    user.exercises.create!(name: name)
    exercise = user.exercises.build(name: name)

    expect { exercise.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "存在しないユーザーへの紐付けをDBが拒否する" do
    exercise = described_class.new(user_id: -1, name: name)

    expect { exercise.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "種目を持つユーザーの削除をDBが拒否する" do
    user.exercises.create!(name: name)

    expect { user.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
