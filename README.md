# board.ps1

`board.ps1` is a Windows PowerShell port of `esp32/tools/muse/board.sh`, the ESP32 build-and-flash script included in Meta's [muse-gadget-sdk](https://github.com/facebookincubator/muse-gadget-sdk).

It takes the same arguments and behaves the same way as the original board.sh, so building and flashing firmware for the supported boards can be done entirely on Windows (the only board not supported is ESP-Mosaico).

## Status

- Ported from board.sh in muse-gadget-sdk `main` @ 9d8cca1 (checked 2026-11-11), targeting ESP-IDF v6.0.3
- Not yet verified on real Windows hardware. This section will be updated after testing

## Background

This script exists for the following reasons:

- I wanted to use an M5Stack Core2 as a Muse Gadget
- The official web flasher does not support the Core2, so I had to build the firmware myself
- Building requires running board.sh, but my machine runs Windows only
- The official instructions assume macOS or Linux, and doing it from Windows would have meant setting up WSL2, which is a hassle
- So I ported board.sh to PowerShell, so that everything from build to flash works on Windows alone

## Requirements

- Windows + PowerShell
- ESP-IDF v6.0.3 (the Windows edition, which includes `export.ps1` for activation)
- A checkout of muse-gadget-sdk
- An SDK token (issued at [gadgets.muse.ai](https://gadgets.muse.ai) under Account > SDK tokens; required for pairing, and set via menuconfig as described below)
- A USB cable that supports data transfer

### Installing ESP-IDF v6.0.3

On Windows, clone ESP-IDF and install it with its PowerShell scripts (Git and Python are required). This mirrors the SDK's macOS/Linux instructions, with the `.ps1` versions in place of the `.sh` ones:

```powershell
git clone -b v6.0.3 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
.\install.ps1 esp32c5,esp32s3,esp32c6,esp32
.\export.ps1
```

- The `install.ps1` arguments limit the download to the toolchains for the chips you use (the last one, `esp32`, is what the M5Stack Core2 needs)
- Run `.\export.ps1` in every new PowerShell session before building; it makes `idf.py` available (board.ps1 also looks for it automatically)

Espressif's GUI installer (EIM) can install v6.0.3 as well; see the [Windows setup guide](https://docs.espressif.com/projects/esp-idf/en/v6.0.3/esp32/get-started/windows-setup.html).

## Usage

Place `board.ps1` in the SDK's `esp32\tools\muse\` folder (next to the original board.sh), and run it from a PowerShell session with ESP-IDF activated.

```powershell
# Build (example: M5Stack Core2)
.\board.ps1 build core2

# Flash (the port is detected automatically)
.\board.ps1 flash core2

# Flash with an explicit port
.\board.ps1 flash core2 COM7
```

- If several boards of the same kind are connected, pass the board's USB serial number as the third argument to tell them apart
- The build log is written to `%TEMP%\muse_build_<board>.log`
- The `MUSE_VIDEO` / `MUSE_BENCH` environment variables work just like they do with board.sh
- If script execution is blocked by policy, run `Set-ExecutionPolicy -Scope Process Bypass` in that PowerShell session
- As with board.sh, this script does not handle the SDK token. Set it via `idf.py -B build-muse-<profile> menuconfig` (under "ESP32 Device SDK > Muse Gadgets SDK token"), or send it over serial after flashing

## After flashing

Open the Muse app and turn on **Settings > Devices > Developer mode**, then add the device from **Settings > Devices > Add Device**. The board shows up as `MuseGadget-XXXXXX`; on display boards, follow the on-screen prompt to confirm pairing. See the SDK's [setup instructions](https://github.com/facebookincubator/muse-gadget-sdk/blob/main/esp32/README.md#4-set-it-up-with-muse) for details.

## Supported boards

The board table from the original board.sh is carried over as-is (40 boards).

k10 / s3 / s3n / s3-18 / s3-216 / s3-206 / 185b / 185c / 143c / 143 / 146 / aipi / atk-box / box3 / c6 / c6-206 / watcher / cardputer-adv / sticks3 / crowpanel-43 / stopwatch / xiao147 / cores3 / core2 / fnk0104b / jc3248w535 / lcd7 / lcd128 / lcd349 / spotpear / vn183 / p4lcd35 / rorolee / smartring-plus / lcd19 / s3lcd35 / plus2 / ai-passport / echoear

ESP-Mosaico is not supported: it requires the development version of ESP-IDF and the ESP-Iris tooling, both of which assume a Unix environment. If you specify it, the script explains this and exits.

## Changes from board.sh

- ESP-IDF activation: looks for and dot-sources `export.ps1` instead of `export.sh`
- Port argument: a COM port such as `COM7` can be passed directly (automatic port detection still uses the original `ports.py` unchanged)
- Build log location: `%TEMP%` instead of `/tmp`
- The ESP-Mosaico code path is not implemented

## Notes

- Flashing custom firmware carries risks, such as the board no longer booting. As with the original project, please proceed at your own risk
- There is no guarantee this script will keep up with updates to muse-gadget-sdk. If board.sh changes, compare the diff and adjust this port yourself

## Disclaimer

- This is an unofficial port made by an individual. It is not a product of Meta Platforms, Inc., and it is not affiliated with, endorsed by, or supported by Meta
- Please do not contact Meta about this script. Questions and bug reports about this script should go to the author of this repository, not to Meta or to the maintainers of muse-gadget-sdk
- This script is provided "as is", without warranty of any kind (see also Section 7 of the Apache License, Version 2.0)

## License and attribution

This script is a Windows PowerShell port of `esp32/tools/muse/board.sh` from Meta Platforms, Inc.'s muse-gadget-sdk, which is licensed under the Apache License, Version 2.0 (ESP-Mosaico is the only part not ported). The original is here: https://github.com/facebookincubator/muse-gadget-sdk

This script is also released under the Apache License, Version 2.0 (see the LICENSE file).

---

# board.ps1（日本語）

Meta の [muse-gadget-sdk](https://github.com/facebookincubator/muse-gadget-sdk) に含まれる ESP32 向けビルド／書き込みスクリプト `esp32/tools/muse/board.sh` を、Windows PowerShell に移植したものです。

元の board.sh と同じ引数・同じ挙動で、対応ボード向けファームウェアのビルドと書き込みが Windows だけで完結します（ESP-Mosaico のみ未対応）。

## 状況

- 土台は muse-gadget-sdk の `main` @ 9d8cca1（2026-11-11 確認）の board.sh で、対象は ESP-IDF v6.0.3 です
- Windows 実機での動作確認はまだです。確認できたら、この欄を更新します

## 経緯

このスクリプトを作った理由は、次のとおりです。

- M5Stack Core2 を Muse Gadget として使いたかった
- 公式の Web フラッシャーは Core2 に対応しておらず、ファームウェアを自分でビルドする必要があった
- ビルドには board.sh の実行が必要だが、手元の環境は Windows しかない
- 公式の手順は macOS / Linux 前提で、Windows でやるには WSL2 を用意しなければならず、面倒だった
- そこで board.sh を PowerShell に移植し、Windows だけでビルドから書き込みまでできるようにした

## 動作環境

- Windows + PowerShell
- ESP-IDF v6.0.3（Windows 版。有効化に使う `export.ps1` が含まれています）
- muse-gadget-sdk のチェックアウト
- SDK トークン（[gadgets.muse.ai](https://gadgets.muse.ai) の Account > SDK tokens で発行。ペアリングに必要で、設定は後述の menuconfig で行います）
- データ転送に対応した USB ケーブル

### ESP-IDF v6.0.3 のインストール

Windows では、ESP-IDF を clone して、付属の PowerShell スクリプトでインストールします（Git と Python が必要です）。SDK の Mac/Linux 向け手順の、`.sh` を `.ps1` に置き換えた形です。

```powershell
git clone -b v6.0.3 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
.\install.ps1 esp32c5,esp32s3,esp32c6,esp32
.\export.ps1
```

- `install.ps1` の引数は、使うチップの分だけツールを入れる指定です（最後の `esp32` が M5Stack Core2 用です）
- `.\export.ps1` は、PowerShell を開くたびに実行します。`idf.py` が使えるようになります（board.ps1 も自動で探します）

GUI インストーラ（EIM）で v6.0.3 を入れる方法もあります。Espressif の [Windows セットアップガイド](https://docs.espressif.com/projects/esp-idf/en/v6.0.3/esp32/get-started/windows-setup.html) を参照してください。

## 使い方

`board.ps1` を、SDK の `esp32\tools\muse\` フォルダに置きます（元の board.sh の隣です）。ESP-IDF を有効化した PowerShell で実行してください。

```powershell
# ビルド（例: M5Stack Core2）
.\board.ps1 build core2

# 書き込み（ポートは自動で検出されます）
.\board.ps1 flash core2

# ポートを明示する場合
.\board.ps1 flash core2 COM7
```

- 同じ種類のボードが複数つながっている場合は、3 つ目の引数にボードの USB シリアル番号を渡して区別します
- ビルドログは `%TEMP%\muse_build_<board>.log` に出力されます
- `MUSE_VIDEO` / `MUSE_BENCH` 環境変数も、元の board.sh と同様に使えます
- スクリプトの実行がポリシーで止まる場合は、その PowerShell でのみ `Set-ExecutionPolicy -Scope Process Bypass` を実行してください
- SDK トークンの設定は元の board.sh と同様に、このスクリプトでは扱いません。`idf.py -B build-muse-<profile> menuconfig` の「ESP32 Device SDK > Muse Gadgets SDK token」で設定するか、書き込み後にシリアル経由で送ります

## 書き込みのあと

Muse アプリで **Settings > Devices > Developer mode** をオンにし、**Settings > Devices > Add Device** からデバイスを追加します。ボードは `MuseGadget-XXXXXX` という名前で現れます。ディスプレイ付きボードでは、画面の案内に従ってペアリングを確定してください。詳しくは SDK の[セットアップ手順](https://github.com/facebookincubator/muse-gadget-sdk/blob/main/esp32/README.md#4-set-it-up-with-muse)を見てください。

## 対応ボード

元の board.sh の対応表をそのまま移植しています（40 ボード）。

k10 / s3 / s3n / s3-18 / s3-216 / s3-206 / 185b / 185c / 143c / 143 / 146 / aipi / atk-box / box3 / c6 / c6-206 / watcher / cardputer-adv / sticks3 / crowpanel-43 / stopwatch / xiao147 / cores3 / core2 / fnk0104b / jc3248w535 / lcd7 / lcd128 / lcd349 / spotpear / vn183 / p4lcd35 / rorolee / smartring-plus / lcd19 / s3lcd35 / plus2 / ai-passport / echoear

ESP-Mosaico は未対応です。ESP-IDF の開発版と ESP-Iris ツールが Unix 環境を前提としているためで、指定した場合は理由を表示して終了します。

## board.sh からの変更点

- ESP-IDF の有効化: `export.sh` の代わりに `export.ps1` を探して読み込む
- ポート指定: `COM7` のような COM ポートを直接渡せるようにした（ポートの自動検出には元の `ports.py` をそのまま使っています）
- ビルドログの出力先: `/tmp` の代わりに `%TEMP%`
- ESP-Mosaico 用の分岐は未実装

## 注意

- カスタムファームウェアの書き込みには、ボードが起動しなくなるなどのリスクがあります。元のプロジェクトの注意書きと同様、自己責任でお願いします
- 本スクリプトは muse-gadget-sdk の更新に追随する保証はありません。元の board.sh が変わった場合は、差分を見て手元で直してください

## 免責事項

- 本スクリプトは個人による非公式の移植です。Meta Platforms, Inc. の製品ではなく、同社との提携・推奨・サポートの対象ではありません
- 本スクリプトについて、Meta 社に問い合わせをしないでください。質問や不具合の報告は、Meta 社や muse-gadget-sdk の開発者ではなく、本リポジトリの作者宛にお願いします
- 本スクリプトは現状のまま提供され、いかなる保証もありません（Apache License, Version 2.0 の第 7 条も参照）

## ライセンスと出典

このスクリプトは、Meta Platforms, Inc. の muse-gadget-sdk に含まれる `esp32/tools/muse/board.sh`（Apache License, Version 2.0）を Windows PowerShell へ移植したものです（ESP-Mosaico のみ未対応）。オリジナルはこちら: https://github.com/facebookincubator/muse-gadget-sdk

本スクリプトも Apache License, Version 2.0 のもとで公開します（LICENSE ファイルを参照）。
