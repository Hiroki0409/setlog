require "rails_helper"

RSpec.describe "TOPページ", type: :request do
  it "正常に表示される" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("今日の筋トレを記録。")
  end
end
