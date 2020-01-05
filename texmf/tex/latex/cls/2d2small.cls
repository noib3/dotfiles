\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{2d2small}[2019/11/16, v2.2]
\LoadClass[landscape]{memoir}

% Packages
% xcolor has to be put first or it causes problems
\RequirePackage[table]{xcolor}

\RequirePackage{arrayjobx}

\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage[english]{babel}

\RequirePackage{calc}
\RequirePackage[useregional=text, calc]{datetime2}
\RequirePackage{geometry}
\RequirePackage{multirow}
\RequirePackage{roboto}
\RequirePackage[many]{tcolorbox}
\RequirePackage{tikzpagenodes}
\RequirePackage{xparse}
\RequirePackage{xstring}

% Lengths

% width of the border around the page and the header
\newlength{\borderwidth}
\setlength{\borderwidth}{.25cm}

% height of the bordeaux page header
\newlength{\headerheight}
\setlength{\headerheight}{1.3cm}

% space between the top of the first row and the header border
\newlength{\headmargin}
\setlength{\headmargin}{1cm}

\newlength{\topmarginn}
\setlength{\topmarginn}{2\borderwidth + \headerheight + \headmargin}

% space between the side of the columns and the page borders
\newlength{\sidemargins}
\setlength{\sidemargins}{1.5cm}

\newlength{\leftrightmargins}
\setlength{\leftrightmargins}{\sidemargins + \borderwidth}

% space between the bottom of the last row and the page border
\newlength{\footmargin}
\setlength{\footmargin}{1.4cm}

\newlength{\bottommarginn}
\setlength{\bottommarginn}{\borderwidth + \footmargin}

% horizontal space between two columns of boxes
\newlength{\colspace}
\setlength{\colspace}{1cm}

% height of each box, obtained by using option draft in tcolorbox
\newlength{\boxheight}
\@ifpackageloaded{roboto}{
  \setlength{\boxheight}{145.10109pt}
}{
  \setlength{\boxheight}{145.33382pt} 
}

% width of the border around the boxes
\newlength{\boxborderwidth}
\setlength{\boxborderwidth}{.45mm} 

% width of the boxes vertical separation lines
\newlength{\seplinewidth}
\setlength{\seplinewidth}{1.1pt} 

% vertical space between two boxes
\newlength{\vertspace}
\setlength{\vertspace}{12.795pt}
% If the boxheight/textheight are modified I use this definition for \vertspace, show
% its value with \showthe\vertspace and then substitute it in
% \setlength{\vertspace}{(\textheight - 3\boxheight)/2 - 5pt} 

% Geometry

\geometry{paperwidth=37.33cm, paperheight=21cm,
		 headsep=\headmargin,
		 footskip=\footmargin,
		 marginparsep=0cm,
		 top=\topmarginn,
		 left=\leftrightmargins,
		 right=\leftrightmargins,
		 bottom=\bottommarginn}
		 
% Colors

% background
\definecolor{background}{RGB}{255, 248, 231}
% bordeaux header
\definecolor{header}{RGB}{129, 0, 44}
% box and page borders
\definecolor{borders}{RGB}{106, 104, 142}
% weight box
\definecolor{weightgray}{RGB}{230, 234, 242}
% text color for the measurements
\definecolor{textboxcolor}{RGB}{55, 55, 55}

\pagecolor{background}

% Headers and footers

\newcommand{\Header}{
  \begin{tikzpicture}[remember picture, overlay]
    \fill[header, rounded corners] ([yshift=-\borderwidth, xshift=\borderwidth] current page.north west) rectangle ([yshift=-(\borderwidth + \headerheight), xshift=-\borderwidth] current page.north east);
    \draw[borders, line width=2\borderwidth, rounded corners=11.12pt] (current page.south west) rectangle (current page.north east) {};
    \node[white] at ([xshift=\paperwidth/2, yshift=-(\headerheight/2 + \borderwidth)] current page.north west) {\Huge\textbf{\arabic{year}}};
  \end{tikzpicture}
}

\makepagestyle{somecreativenameforapagestyle}
\makeoddhead{somecreativenameforapagestyle}{}{\Header}{}
\makeevenhead{somecreativenameforapagestyle}{}{\Header}{}
\pagestyle{somecreativenameforapagestyle}


% Measure box

% stretch space between table rows
\@ifpackageloaded{roboto}{
  \def\arraystretch{1.23}
}{
  \def\arraystretch{1.25}
}

\tcbset{
  titlecommon/.style={
      halign=center,
      sharp corners,
      arc=2pt,
      leftrule=\boxborderwidth,
      rightrule=\boxborderwidth,
      toprule=\boxborderwidth,
      bottomrule=\boxborderwidth
  },
  toptitle/.style={
      titlecommon,
      fontupper={\color{white}},
      rounded corners=north
  },
  bottomtitle/.style={
      titlecommon,
      colframe=borders,
      colback=weightgray,
      fontupper={\color{textboxcolor}},
      rounded corners=south
  },
  boxrule=\boxborderwidth,
  enhanced,
  colframe=borders,
  notitle,
  top=-3\boxborderwidth -.09mm,
  bottom=-3\boxborderwidth -.1mm,
  colupper=textboxcolor,
  colback=white,
  left=0cm,
  right=0cm
}

\newtcolorbox{msrbox}[3][]{
  arc=2pt,
  before upper={\tcbsubtitle[toptitle]{#2}},
  after upper={\tcbsubtitle[bottomtitle]{#3}},
  #1
}

\NewDocumentCommand{\measurebox}{ m }{%
  \noindent%
  \begin{minipage}{(\textwidth - 2\colspace)/3}%
  % the phantom hy is there to make all titles the same
  % height (because of the descenders and ascenders)
  \begin{msrbox}{\vspace{-.4pt}\phantom{hy}\dates{#1}\phantom{yh}\vspace{-.4pt}}{\Weight(#1)}
  
  \vspace{-3pt}
  
  \begin{minipage}{(\textwidth - \seplinewidth)/2}
  \begin{center}
  \begin{small}
  \begin{tabular}{l l l l}
  & & nf & f \\
  \rowcolor{weightgray}
  n & & \necknf(#1) & \neckf(#1) \\
  s & & \shouldersnf(#1) & \shouldersf(#1) \\
  \rowcolor{weightgray}
  c\&b & & \chestbacknf(#1) & \chestbackf(#1) \\
  & dx & \armdxnf(#1) & \armdxf(#1) \\[-3.9pt]
  \multirow{-2}{*}{\vspace{-5pt}a}
  & sx & \armsxnf(#1) & \armsxf(#1) \\
  \rowcolor{weightgray}
  & dx & \forearmdxnf(#1) & \forearmdxf(#1) \\[-3.9pt]
  \rowcolor{weightgray}
  \multirow{-2}{*}{\vspace{-5pt}f} 
  & sx & \forearmsxnf(#1) & \forearmsxf(#1)
  \end{tabular}
  \end{small}
  \end{center}
  \end{minipage}%
  %
  {\color{borders}\vrule width \seplinewidth height 50.3pt}%
  %
  \begin{minipage}{(\textwidth - \seplinewidth)/2}
  \begin{center}
  \begin{small}
  \begin{tabular}{l l l l}
  & & nf & f \\
  \rowcolor{weightgray}
  w & & \waistnf(#1) & \waistf(#1) \\
  g & & \glutesnf(#1) & \glutesf(#1) \\
  \rowcolor{weightgray}
  & dx & \legdxnf(#1) & \legdxf(#1) \\[-3.9pt]
  \rowcolor{weightgray}
  \multirow{-2}{*}{\vspace{-5pt}l} 
  & sx & \legsxnf(#1) & \legsxf(#1) \\
  & dx & \calfdxnf(#1) & \calfdxf(#1) \\[-3.9pt]
  \multirow{-2}{*}{\vspace{-5pt}c} 
  & sx & \calfsxnf(#1) & \calfsxf(#1) \\
  \phantom{c\&b} & & &
  \end{tabular}
  \end{small}
  \end{center}
  \end{minipage}

  \vspace{.2pt}
  \end{msrbox}
  \end{minipage}%
}

% Data handling

\newcounter{nboxes}
\setcounter{nboxes}{0}

\newcommand{\neck}[1]{}
\newcommand{\shoulders}[1]{}
\newcommand{\chestback}[1]{}
\newcommand{\armdx}[1]{}
\newcommand{\armsx}[1]{}
\newcommand{\forearmdx}[1]{}
\newcommand{\forearmsx}[1]{}
\newcommand{\waist}[1]{}
\newcommand{\glutes}[1]{}
\newcommand{\legdx}[1]{}
\newcommand{\legsx}[1]{}
\newcommand{\calfdx}[1]{}
\newcommand{\calfsx}[1]{}
\newcommand{\weight}[1]{}
\newcommand{\nan}{$\boldsymbol{\times}$}

\newarray\necknf
\newarray\neckf
\newarray\shouldersnf
\newarray\shouldersf	
\newarray\chestbacknf
\newarray\chestbackf
\newarray\armdxnf
\newarray\armdxf
\newarray\armsxnf
\newarray\armsxf
\newarray\forearmdxnf
\newarray\forearmdxf
\newarray\forearmsxnf
\newarray\forearmsxf
\newarray\waistnf
\newarray\waistf
\newarray\glutesnf
\newarray\glutesf
\newarray\legdxnf
\newarray\legdxf
\newarray\legsxnf
\newarray\legsxf
\newarray\calfdxnf
\newarray\calfdxf
\newarray\calfsxnf
\newarray\calfsxf
\newarray\Weight

\ExplSyntaxOn
\NewDocumentCommand{ \splitandassign }{ m m m m }{
  #3( \value{nboxes} ) = { \IfDecimal{#1}{#1"}{\nan} }
  #4( \value{nboxes} ) = { \IfDecimal{#2}{#2"}{\nan} }
}

\NewDocumentEnvironment{ measures }{}{
  \stepcounter{nboxes}
  
  \RenewDocumentCommand{ \neck }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \necknf }{ \neckf } }
  \RenewDocumentCommand{ \shoulders }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \shouldersnf }{ \shouldersf } }
  \RenewDocumentCommand{ \chestback }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \chestbacknf }{ \chestbackf } }
  \RenewDocumentCommand{ \armdx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \armdxnf }{ \armdxf } }
  \RenewDocumentCommand{ \armsx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \armsxnf }{ \armsxf } }
  \RenewDocumentCommand{ \forearmdx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \forearmdxnf }{ \forearmdxf } }
  \RenewDocumentCommand{ \forearmsx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \forearmsxnf }{ \forearmsxf } }
  \RenewDocumentCommand{ \waist }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \waistnf }{ \waistf } }
  \RenewDocumentCommand{ \glutes }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \glutesnf }{ \glutesf } }
  \RenewDocumentCommand{ \legdx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \legdxnf }{ \legdxf } }
  \RenewDocumentCommand{ \legsx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \legsxnf }{ \legsxf } }
  \RenewDocumentCommand{ \calfdx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \calfdxnf }{ \calfdxf } }
  \RenewDocumentCommand{ \calfsx }{ >{\SplitArgument{1}{,}} m }{ \splitandassign ##1{ \calfsxnf }{ \calfsxf } }
  \renewcommand{ \weight }[ 1 ]{ \Weight( \value{nboxes} ) = { \IfDecimal{##1}{##1kg}{\nan} } }
  
  \seq_gpop_left:NNF \g_measure_seq \l_measure_date_tl {
    \tl_set:Nx \l_measure_date_tl { { \int_use:N \c_sys_year_int } \today }
    \prop_get:NfNF \g_measure_years_prop { \int_use:N \c_sys_year_int } \l_tmpa_tl {
      \tl_set:Nn \l_tmpa_tl { 0 }
    }
    \prop_gput:Nff \g_measure_years_prop { \int_use:N \c_sys_year_int } {
      \int_eval:n { \l_tmpa_tl + 1 }
    }
  }
  \seq_gput_right:NV \g_measure_out_seq \l_measure_date_tl
}{}

% \StrGobbleLeft { string }{ n } removes the first n characters from 'string', so to remove the year it should be n = 5, but I think that since
% I \l_measure_date_tl is assigned as { { year } \today }, { year } counts as a single character 
\NewDocumentCommand{ \dates }{ m }{
  \StrGobbleLeft { \seq_item:Nn \g_measure_out_seq { #1 } }{ 1 } 
}

% Automatic dates

\ExplSyntaxOn
\cs_generate_variant:Nn \prop_get:NnNF { NfNF }
\cs_generate_variant:Nn \prop_gput:Nnn { Nff }
\seq_new:N \g_measure_seq
\seq_new:N \g_measure_out_seq
\iow_new:N \g_measure_stream
\tl_new:N \l_measure_date_tl
\prop_new:N \g_measure_years_prop

\cs_new:Npn \readdates{
  \ior_open:NnT \g_measure_stream { \c_sys_jobname_str dates.txt } {
    \ior_map_inline:Nn \g_measure_stream { 
      \seq_gput_right:Nn \g_measure_seq { ##1 }
      \prop_get:NfNF \g_measure_years_prop { \tl_head:n { ##1 } } \l_tmpa_tl {
        \tl_set:Nn \l_tmpa_tl { 0 }
      }
      \prop_gput:Nff \g_measure_years_prop { \tl_head:n { ##1 } } {
        \int_eval:n { \l_tmpa_tl + 1 }
      }
    }
    \ior_close:N \g_measure_stream
  }
}

\AtEndDocument{
  \iow_open:Nn \g_measure_stream { \c_sys_jobname_str dates.txt }
  \seq_map_inline:Nn \g_measure_out_seq {
    \iow_now:Nn \g_measure_stream { #1 }
  }
  \iow_close:N \g_measure_stream
}
\ExplSyntaxOff

\makeatletter
\readdates
\makeatother

\DTMnewdatestyle{mydatestyle}{
  \renewcommand*{\DTMdisplaydate}[4]{\DTMmonthname{##2} \DTMtwodigits{##3}}
  \renewcommand*{\DTMDisplaydate}{\DTMdisplaydate}
}

\AtBeginDocument{\DTMsetdatestyle{mydatestyle}}
\endinput