# RenkuOS for VAIO P

Sony VAIO P（VGN-P70H_G）向けの、32 ビット版（x86_gcc2 ハイブリッド）[RenkuOS](https://github.com/RenkuOS/Source) のインストール用 ISO です。日本語入力（Mozc）が最初から入っています。

VAIO P の Atom Z520 は 64 ビットモードを持たないため、RenkuOS が配布している x86_64 版は動きません。この ISO は同じソースから 32 ビット版をビルドしたものです。

## ダウンロード
[Releases](https://github.com/wainohito/renkuos-vaio-p/releases) から `renku-vaio-p-ja-x86_gcc2h.iso` をダウンロードし、USB メモリに書き込んでください。

    sudo dd if=renku-vaio-p-ja-x86_gcc2h.iso of=/dev/sdX bs=4M

## 中身
- **RenkuOS** main（[`3187bee87f`](https://github.com/RenkuOS/Source/commit/3187bee87f8695c74acff7227a1d34bbfc78f6fd)、2026-11-18）
- **VAIO P 用パッチ**（[rainygirl/renkuos-sony-vaio-p-patch](https://github.com/rainygirl/renkuos-sony-vaio-p-patch) `3ccbdea`）。2 つ目の CPU の起動、USB、無線 LAN、Sony EC（輝度キーと無線スイッチ）、GMA500 のハードウェアカーソル、CPU の周波数制御、Web カメラ、録音などです。RenkuOS 側で取り込み済みのものは RenkuOS の版を使っています（下記）。
- **日本語入力**
  - [Mozc 3.35.6354](https://github.com/wainohito/mozc/releases/tag/renkuos-3.35.6354-2-x86_gcc2)（32 ビット版）
  - [TerminalJ+](https://github.com/wainohito/terminalj-plus/releases/tag/v1.0.0-x86_gcc2)（カーソル位置で変換できるターミナル）
  - 日本語フォント（Noto Sans CJK JP）
  - デスクトップの「Mozc-Qt」フォルダ: Qt 6 / Qt 5 アプリでもカーソル位置で変換できるようにするパッケージとインストーラー。Qt のアプリを入れたあとで使ってください。

## 日本語入力
- Command+Space（通常は Alt+Space）で Roman と Mozc を切り替えます。入力モードと設定は Deskbar のアイコンから選べます。
- **Mozc が自動で起動するのは、日本語設定で起動したときだけです。** 言語の設定（ようこそ画面または「ロケール」）が日本語の状態で起動したときだけ、起動時に Mozc が立ち上がります。それ以外の言語では、Mozc に切り替えたときに初めて起動します。ようこそ画面で日本語を選んだ場合は、次に起動したときから自動で立ち上がります。

## 注意
- **電源を入れると何度か再起動することがありますが、正常です。** 2 つ目の CPU が応答しないとき、ブートローダーがわざと再起動してやり直します（最大 8 回、合わせて 4〜5 分ほど）。詳しくは [元のパッチの README](https://github.com/rainygirl/renkuos-sony-vaio-p-patch#repeated-reboots-at-power-on-are-expected) を見てください。
- **`pkgman update`（HaikuDepot の「更新」）はしないでください。** システムのパッケージがオンラインの版に置き換わり、VAIO P 用の修正が消えて起動しなくなることがあります。更新するには、新しい ISO で入れ直してください。
- 動作は QEMU（Atom N270 相当、2 CPU）で確認しました。起動、日本語のデスクトップ、StyledEdit での変換、日本語設定のときだけ Mozc が自動起動することです。**VAIO P の実機ではまだ確認していません。** VAIO P 固有の修正は、元のパッチの作者が実機で確認したものです。

## 元のパッチからの変更
最新の RenkuOS に当てるにあたり、次のように扱いました（`patches/commits/0001-*`）。

| ファイル | 扱い |
|---|---|
| `build/jam/images/definitions/regular` | RenkuOS が追加した axp288 と sony_ec の両方を残す |
| `ehci_hardware.h` | RenkuOS `d92c5560ef` が同じ確認をビルド時に行うので外す |
| `MediaRecorder.cpp` | Start()/Stop() は RenkuOS `fe463c423e` の版（録音を止めても再生用のノードは止めない）。Disconnect() の修正だけ残す |
| `vm_page_writer.cpp` | RenkuOS `597aeed64f` の待機者の確認と、パッチ側のアイドル時の再計算を両方入れる |

そのほかの変更:
- `0002`: input_server。システムに入っている入力メソッドが Deskbar より先に読み込まれると、Deskbar に入力メソッドのアイコンが出ないままになっていたのを直しました。
- `0003`: 日本語入力のパッケージとフォントをイメージに入れます。

## ビルド
`patches/renku-vaio-p-ja.diff` は RenkuOS `3187bee87f` からの変更の全部で、`patches/commits/` はそれをコミットごとに分けたものです（`git am` で当てられます）。`build-renku32-ja.sh` はこの ISO を作った手順をまとめたスクリプトです。前提として、次のものを同じディレクトリに並べてください。
- `Renku/`: パッチを当てた RenkuOS
- `buildtools/`: haiku/buildtools
- `mozc/`: wainohito/mozc のブランチ `renkuos-x86_gcc2h`
- `terminalj-plus/`: wainohito/terminalj-plus のブランチ `x86_gcc2h`
- `vaio-p-packages/`: [元のビルドスクリプト](https://github.com/rainygirl/renkuos-sony-vaio-p-patch/blob/main/build-vaio-p-iso.sh)が取得する追加パッケージ

Linux（amd64）が必要です。

## ライセンス
- RenkuOS は MIT（Haiku 由来の部分はそれぞれのライセンス）です。
- VAIO P 用パッチは MIT です（[licenses/vaio-p-patches.LICENSE](licenses/vaio-p-patches.LICENSE)）。
- Mozc は BSD 3 条項、TerminalJ+ は MIT です。Qt 6 / Qt 5 のパッケージは LGPL / GPL で、変更点のパッチはそれぞれのパッケージに入っています。
- このリポジトリの README とスクリプトは MIT です。

## AI について
このイメージとパッチは、人が Claude と一緒に作りました。元の VAIO P パッチの作者の注記を、そのまま引き継ぎます。

> These patches were produced by a human working with Claude. [...] **The Haiku project does not accept AI-assisted contributions, and none of this has been or should be submitted upstream.** It is a personal patch set for one machine, published in that spirit under the same MIT terms as the code it modifies. If you reuse any of it, please carry this notice with it.
