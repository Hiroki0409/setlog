require "rails_helper"

RSpec.describe "トレーニング記録の利用フロー", type: :system do
  it "登録から前回の振り返り、編集・削除、ログアウトまで操作できる" do
    email = "system-workout@example.com"
    password = "example-password"
    first_date = Date.new(2026, 11, 18)
    next_date = Date.new(2026, 11, 20)
    previous_rows = [ [ "60.25", "10", "2" ], [ "65", "8", "1" ] ]

    visit root_path
    click_link "新規登録"
    fill_in "メールアドレス", with: email
    fill_in "user_password", with: password
    fill_in "確認用パスワード", with: password
    click_button "登録する"
    expect(page).to have_current_path(exercises_path)

    sign_out_through_browser
    sign_in_through_browser(email: email, password: password)
    expect(page).to have_current_path(exercises_path)

    fill_in "種目名", with: "ベンチプレス"
    click_button "種目を登録する"
    open_workout_entry(on: first_date)
    save_workout(weight: "60.25", reps: "10", set_count: "2")
    save_workout(weight: "65", reps: "8", set_count: "1")

    open_workout_entry(on: next_date)
    expect_previous_workout(on: first_date, rows: previous_rows)
    save_workout(weight: "70.25", reps: "8", set_count: "1")
    expect_previous_workout(on: first_date, rows: previous_rows)

    click_link "履歴"
    within(find(".workout-record-list > li", text: "70.25")) do
      click_link "編集"
    end
    fill_in "重量（kg）", with: "72.5"
    click_button "変更を保存する"
    expect(page).to have_text("記録を更新しました。")

    within(find(".workout-record-list > li", text: "72.5")) do
      click_link "削除"
    end
    expect(page).to have_css("main h1", text: "記録の削除確認", exact_text: true)
    within("main") do
      expect(page).to have_text("72.5")
      click_button "削除する"
    end
    expect(page).to have_text("記録を削除しました。")
    expect(page).to have_no_css(".workout-record-list > li", text: "72.5")
    expect(page).to have_css(".workout-record-list > li", count: 2)

    sign_out_through_browser
    visit exercises_path
    expect(page).to have_current_path(new_user_session_path)
  end

  def open_workout_entry(on:)
    click_link "種目一覧"
    select "ベンチプレス", from: "記録する種目"
    fill_in "実施日", with: on
    click_button "記録入力へ"
    expect(page).to have_css("main h1", text: "トレーニング記録", exact_text: true)
  end

  def save_workout(weight:, reps:, set_count:)
    fill_in "重量（kg）", with: weight
    fill_in "回数", with: reps
    fill_in "セット数", with: set_count
    click_button "記録を保存する"
    expect(page).to have_text("記録を保存しました。")
  end

  def expect_previous_workout(on:, rows:)
    within(".previous-workout") do
      expect(page).to have_css("time[datetime='#{on.iso8601}']")
      expect(page).to have_css("tbody tr", count: rows.size)
      expect(all("tbody tr").map { |row| row.all("td").map(&:text) }).to eq(rows)
    end
  end
end
