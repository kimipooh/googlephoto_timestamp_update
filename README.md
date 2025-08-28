# Summary

このツールは、Google Takeout でエクスポートした Googleフォトのデータ（特定アルバムのみ抽出した場合もOK）のタイムスタンプ（日時）を修正する macOS 用ツールです。

利用するには、下記の２つのツール（exif, jq）を事前にインストールしておいてください。

macOS であれば、Homebrew をインストールした上で、
brew install exif
brew install jq
を実行してインストールできます。

jq コマンドでJSONファイルから必要なデータを読み取って、exiftool でファイルのタイムスタンプを修正します。

--

This tool for macOS corrects the timestamp (date and time) of Google Photos data exported with Google Takeout (even when extracting specific albums).

To use this tool, you'll need to install the following two tools("exif" and "jq") beforehand:

You install them by installing Homebrew and then running
brew install exif
brew install jq

Use the jq command to read the necessary data from the JSON file, and then use exiftool to correct the file's timestamp.

# Processing flow

このツールは以下の処理をします。
1. 特定データを指定する（スクリプトの下記で追加・削除できる。特定データは拡張子ごとに設定）
　IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "tiff" "heic" "mp4" "mov", "webp", "hevc", "avi")
2. 特定フォルダ（サブフォルダ含む）にある、特定データを探す
3. 特定データにメタ情報（特定データ名.supplemental-metadata.json）があれば、日時を抽出
4. 抽出した日時を指定したタイムゾーンにそって修正する（デフォルトは日本時間（+09:00）。引数で変更可能）
5. 修正したに日時を、ファイルの日時として修正する（下記の３つを修正）

*CreateDate: 写真ファイルが作成された日時
*MofityDate: ファイルが最後に変更された日時
*DateTimeOriginal: 写真に記録されている映像の日時（EXIF情報）

--

This tool performs the following operations:
1. Specify specific data (you can add or remove specific data using the script below. Specific data can be set for each extension).
IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "tiff" "heic" "mp4" "mov" "webp" "hevc" "avi")
2. Search for specific data in a specific folder (including subfolders).
3. Extract the date and time if the specific data contains meta information (specific_data_name.supplemental-metadata.json).
4. Modify the extracted date and time to match the specified time zone.
The default is Japan Time (+9:00). This can be changed using arguments.
5. Modify the modified date and time as the file date and time (modify the following three items).
CreateDate: Date and time the photo file was created.
ModityDate: Date and time the file was last modified.
DateTimeOriginal: Date and time of the image recorded in the photo (EXIF information).

# How to install it

ダウンロードして、
googlephoto_timestamp_update.sh
このファイルをターミナルにて
chmod +x googlephoto_timestamp_update.sh
のように実行権限をつけてください。

もし実行権限をつけない場合には
sh googlephoto_timestamp_update.sh
のように先頭に sh シェルをつけても実行できます。

--

Download it and run it as googlephoto_timestamp_update.sh.
In Terminal, grant this file executable permissions by running chmod +x googlephoto_timestamp_update.sh.

If you do not grant executable permissions, you can also run it by adding the sh shell at the beginning, such as sh googlephoto_timestamp_update.sh.

# How to use it

Usage: ./googlephoto_timestamp_update.sh [option] [file/directory]

Options:
 
 -h 
 *Displays this help message.
 
 -timezone <offset>
 * Specifies the time zone offset (e.g., +09:00, -05:00). If not specified, the default is +09:00.

Arguments:

 [file/directory]
* Specifies the directory to process. If not specified, the current directory is used.

Example:
*  ./googlephoto_timestamp_update.sh -h
*  ./googlephoto_timestamp_update.sh
* ./googlephoto_timestamp_update.sh /path/to/photos
*  ./googlephoto_timestamp_update.sh /path/to/photos/file1.jpg
*  ./googlephoto_timestamp_update.sh /path/to/photos/*.jpg
*  ./googlephoto_timestamp_update.sh --timezone -05:00
*  ./googlephoto_timestamp_update.sh --timezone +16:00 /path/to/photos
  
