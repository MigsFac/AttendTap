# AttendTap
## 内容
項目をタップして出勤・退勤の記録ができる個人用の出勤簿記録アプリです。

## 概要
あの日何時まで働いてたっけ、とならないように出勤・退勤時間を簡単に記録できます。

超過勤務などの理由を事前に項目として作っておき、タップで選択。  
任意の時間に設定したり、後から編集もできます。

項目は追加・編集・削除可能。順番を入れ替えることもできます。  
勤務の一覧をリスト表示とカレンダーで表示します。

テーマカラーとフォントも選択可能。  
英語圏にも対応。
![図1](https://github.com/user-attachments/assets/d2082487-5c2e-4469-a722-e468b77d532f)
![図３](https://github.com/user-attachments/assets/0076bcbc-22c9-46e7-b6b1-038711f374b8)
![図2](https://github.com/user-attachments/assets/f8627142-1237-4e1e-baf2-9eef71799653)
![fig4](https://github.com/user-attachments/assets/6f37bf17-ec91-4ce0-a49e-edb01e8757c1)

## その他
androidとiOSと対応させるならflutterを使ってみようと思い作成開始。  
flutter初めてでしたが、htmlやcssで作るのと似たような感覚で作りやすかったのですが、構造上ネストがすごくてカッコ閉じれない　;か,か分からない問題が頻発。  
補助ツールないと無理でした。ChatGPTと喧嘩しながら感謝しながら作成。  
いまいちどこでファイルを分けたらいいのか分からず冗長なコードになってしまっていますが、いずれリファクタリングします。  
せっかくならadMobも搭載して、ひとまず英語のみで世界にも対応しようとするもGDPRなどの規制対応にも追われました。  
現在google playの審査待ち。iOSは途中からビルドできない問題が発生し、登録料も高いため保留中。（flutterの意味..）  

## 使用技術
・flutter  
・SQLite

## 連絡先
migsfactory[アット]gmail.com  
&copy; 2024 Mig's Factory
