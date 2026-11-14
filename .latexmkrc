# Build with LuaLaTeX; all intermediate and output files go to build/
$pdf_mode = 4;
$lualatex = 'lualatex -interaction=nonstopmode -file-line-error -synctex=1 %O %S';
$out_dir  = 'build';
@default_files = ('main.tex');
