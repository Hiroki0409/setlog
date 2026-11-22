# D24 コントローラーとモデルの構成確認

## 確認結果

| 対象 | 責務と処理の流れ |
| --- | --- |
| 認証 | [`routes.rb`](../config/routes.rb) で登録・ログインをDeviseに接続する。[`ApplicationController`](../app/controllers/application_controller.rb) はログイン後の戻り先を選び、[`User`](../app/models/user.rb) は認証設定と関連を定義する。 |
| 種目一覧・登録 | [`ExercisesController`](../app/controllers/exercises_controller.rb) は `current_user.exercises` から一覧と登録対象を取得し、保存結果に応じて遷移する。種目名の妥当性は [`Exercise`](../app/models/exercise.rb) が検証する。 |
| 記録の作成・一覧・編集・削除 | [`WorkoutRecordsController`](../app/controllers/workout_records_controller.rb) は本人の種目・記録を取得し、保存後の遷移や入力エラーの再表示を扱う。[`WorkoutRecord`](../app/models/workout_record.rb) は実施日・重量・回数・セット数を検証する。 |
| 前回の記録 | コントローラーは入力日が有効なときに `Exercise#previous_workout_records` を呼ぶ。モデルは同じ種目について、入力対象日より前の最新実施日を求め、その日の全記録を取得する。 |

## 整理の判断

- 編集・更新・削除で使う記録の取得は `set_workout_record` に集約されている。本人の種目に限定する条件は、記録の新規作成と種目の付け替えでも確認した。
- 記録の新規画面と保存失敗時は `load_previous_workout` を共有している。日付の妥当性と前回分の取得条件は、それぞれのモデルから再利用している。
- 編集画面と更新失敗時には同じ種目取得が1行ずつある。どちらも画面表示に必要なデータをその場で読み込む処理で、現状は各アクションで確認できる形が読みやすい。
- 保存成功時は遷移し、入力エラー時は入力値とエラーを再表示する。分岐はアクションごとに追えるため、現時点の構成が妥当と判断した。

## 挙動の確認方法

- リクエストスペックで、ログイン制限、本人のデータに限定した操作、入力エラー時の再表示、前回分の表示を確認する。
- モデルスペックで、入力値の検証と前回分の取得条件を確認する。
- システムスペックで、登録から記録の保存・振り返り・編集・削除・ログアウトまでを確認する。

関連 Issue #27（D24）
