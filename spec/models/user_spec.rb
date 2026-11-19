require "rails_helper"

RSpec.describe User, type: :model do
  it "有効な情報で保存でき、パスワードはハッシュ化される" do
    user = build(:user)
    password = user.password
    user.save!

    expect(user.reload.encrypted_password).not_to eq(password)
    expect(user.valid_password?(password)).to be(true)
  end

  it "平文と確認用のパスワードを保存するカラムを持たない" do
    expect(described_class.column_names & %w[ password password_confirmation ]).to be_empty
  end

  it "メールアドレスが空なら無効になる" do
    user = build(:user, email: nil)

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "メールアドレスの形式が不正なら無効になる" do
    user = build(:user, email: "invalid-email")

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "すでに使われているメールアドレスなら無効になる" do
    existing_user = create(:user)
    user = build(:user, email: existing_user.email)

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "パスワードが空なら無効になる" do
    user = build(:user, password: nil, password_confirmation: nil)

    expect(user).not_to be_valid
    expect(user.errors[:password]).not_to be_empty
  end

  it "パスワードが短すぎると無効になる" do
    user = build(:user, password: "short", password_confirmation: "short")

    expect(user).not_to be_valid
    expect(user.errors[:password]).not_to be_empty
  end

  it "確認用パスワードが一致しなければ無効になる" do
    user = build(:user, password_confirmation: "different-password")

    expect(user).not_to be_valid
    expect(user.errors[:password_confirmation]).not_to be_empty
  end
end
