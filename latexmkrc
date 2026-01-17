# ============================================================================
# ビルド開始時に .xbb を自動生成
# ============================================================================
# latexmk 起動時に、プロジェクト内の全 PNG/JPG 画像に対して .xbb を生成する。
# 既に .xbb が存在し、画像より新しい場合はスキップするため、オーバーヘッドは最小限。
#
# latexmkrc は master_thesis/ の親ディレクトリにあるため、相対パスで指定。
# カレントディレクトリは master_thesis/ なので、スクリプトは ../ にある。
my $xbb_script = "../generate_xbb.sh";
if (-x $xbb_script) {
    system($xbb_script);
}

$latex = 'platex';

# ============================================================================
# BibTeX 対策
# ============================================================================
# upBibTeX(pbibtex) は、最初に latexmk が作る「簡易 .aux」( \bibdata が無い )に対して走ると
# "I found no \bibdata command" 等でエラー終了し、ビルド全体が止まることがある。
# そこで、\bibdata が含まれているときだけ pbibtex を実行する。
$bibtex = 'sh -c \'aux=%B.aux; if [ -f "$aux" ] && grep -qF "\\\\bibdata" "$aux"; then pbibtex %O %B; else echo "latexmk: skip pbibtex (no \\\\bibdata in $aux)"; fi\'';

# ============================================================================
# PNG/JPEG 等のビットマップ画像から .xbb を自動生成
# ============================================================================
# dvipdfmx 環境では PNG/JPEG 等に BoundingBox 情報 (.xbb) が必要。
# latexmk のカスタム依存ルールで、画像ファイルから .xbb を自動生成する。
# これにより新しい画像を追加しても手動で extractbb を実行する必要がなくなる。

add_cus_dep('png', 'xbb', 0, 'xbb_from_png');
add_cus_dep('jpg', 'xbb', 0, 'xbb_from_jpg');
add_cus_dep('jpeg', 'xbb', 0, 'xbb_from_jpeg');
add_cus_dep('gif', 'xbb', 0, 'xbb_from_gif');

sub xbb_from_png  { return run_extractbb($_[0], 'png');  }
sub xbb_from_jpg  { return run_extractbb($_[0], 'jpg');  }
sub xbb_from_jpeg { return run_extractbb($_[0], 'jpeg'); }
sub xbb_from_gif  { return run_extractbb($_[0], 'gif');  }

sub run_extractbb {
    my ($base, $ext) = @_;
    my $src = "$base.$ext";
    if (-e $src) {
        # extractbb を画像ファイルのあるディレクトリで実行（セキュリティ制限回避）
        use File::Basename;
        my $dir  = dirname($src);
        my $file = basename($src);
        my $orig_dir = Cwd::getcwd();
        chdir($dir) or return 1;
        my $ret = system("extractbb", "-x", $file);
        chdir($orig_dir);
        return $ret ? 1 : 0;
    }
    return 1;
}

# ============================================================================
# その他の設定
# ============================================================================
$dvipdf = 'dvipdfmx -V 7 %O -o %D %S';
$makeindex = 'mendex %O -o %D %S';
$pdf_mode = 3; 
$ENV{TZ} = 'Asia/Tokyo';
$ENV{OPENTYPEFONTS} = '/usr/share/fonts//:';
$ENV{TTFONTS} = '/usr/share/fonts//:';

# Cwd モジュールを読み込み（run_extractbb で使用）
use Cwd;
