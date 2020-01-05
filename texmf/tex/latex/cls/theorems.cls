\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{theorems}[2019/10/30, v3.2]
\LoadClass[chapterprefix=on, fontsize=12pt, twoside]{scrbook}

% Packages

\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}

\RequirePackage{adjustbox}

% I have to load this before hyperref or else
% \eqref links slightly above the equation
\RequirePackage{amsmath}

\RequirePackage{amsfonts}
\RequirePackage{amsthm}

\ifdefined\preamble@file
    \RequirePackage[backend=biber, hyperref=false]{biblatex}
\else
    \RequirePackage[backend=biber]{biblatex}
\fi

\RequirePackage{chngcntr}
\RequirePackage{etoolbox}

% I have to load this before geometry or else
% the page dimensions get fucked up
\RequirePackage{hyperref} 
\hypersetup{colorlinks, linkcolor=[RGB]{117, 17, 17}, citecolor=[RGB]{0, 0, 0}, urlcolor=[RGB]{0, 0, 132}}

\RequirePackage{geometry}
\RequirePackage{microtype}
\RequirePackage{refcount}
\RequirePackage{scrlayer-scrpage}
\RequirePackage{subfiles}
\RequirePackage{titletoc}
\RequirePackage{xcolor}
\RequirePackage{xparse}

% Geometry

\geometry{paperwidth=20.8cm, paperheight=28cm,
		top=2.8cm,
		bottom=3cm,
		left=2.6cm,
		right=2.6cm,
		headsep=0.8cm}

% Colors

\definecolor{chaptergrey}{rgb}{0.7, 0.7, 0.7}

% Title

\renewcommand{\maketitle}{
  \hypersetup{pageanchor=false}
  \begin{titlepage}
  \newgeometry{top=6.5cm, right=4.5cm}
  \raggedleft
  \scalebox{1.4}{\@author}
  \vspace{0.9cm} \\
  
  \scalebox{1.4}{\@title}
  \restoregeometry
  \end{titlepage}
  \hypersetup{pageanchor=true}
}

% ToC sectioning

\contentsmargin{0pt}
\titlecontents{chapter}[7.5pt]{\addvspace{2.7ex}\fontsize{14}{14}\selectfont}
					  {\contentslabel[\thecontentslabel]{7.5pt}\hspace{1pc}}
					  {}
					  {\nolinebreak\enspace$\diamond$\enspace\hfill\thecontentspage}

% Document sectioning

\let\raggedchapter\raggedleft
\addtokomafont{disposition}{\normalfont}
\setkomafont{chapter}{\LARGE}

\renewcommand*{\chapterformat}{
  \scalebox{6.5}{\color{chaptergrey}\thechapter}
}

% Headers and footers

\renewcommand*{\chaptermarkformat}{\thechapter.\enskip}

\clearpairofpagestyles
\lohead{\leftmark}
\rehead{\leftmark}
\lehead*{}
\rohead*{}
\lehead{\pagemark}
\rohead{\pagemark}

% AtBeginDocument hook

\ifdefined\preamble@file
    \AtBeginDocument{
      \addtocounter{page}{-1}
      \thispagestyle{empty}
      \null\clearpage
      \pagenumbering{arabic}
    }
\else
    \AtBeginDocument{
      \maketitle
      \newpage
      \pagenumbering{roman}
      \begingroup
      \newgeometry{top=2.8cm, bottom=3cm, left=3.3cm, right=3.3cm}
      \hypersetup{linkcolor=[RGB]{0, 0, 0}}
      \tableofcontents
      \restoregeometry
      \endgroup
      \cleardoublepage\pagenumbering{arabic}
    }
\fi

% Automatic theorem list

\ExplSyntaxOn

\prop_new:N \g_my_theorems_prop
\seq_new:N \g_my_theorems_seq
\tl_new:N \g__my_theorems_number_tl
\iow_new:N \g_my_theorems_stream
\seq_new:N \g_my_theorems_counters_seq

\NewDocumentCommand{\newtheoremx}{momo}{
  \IfNoValueTF { #2 }{
    \IfNoValueTF { #4 }{
      \newtheorem{#1@inner}{#3}
      \theoremstyle{linked}
      \newtheorem{#1@innerlinked}{#3}
    }{
      \newtheorem{#1@inner}{#3}[#4]
      \theoremstyle{linked}
      \newtheorem{#1@innerlinked}{#3}[#4]
    }
    \prop_gput:Nnn \g_my_theorems_prop { #1 } { #1 }
    \seq_gput_right:Nn \g_my_theorems_counters_seq { #1 }
  }{
    \newtheorem{#1@inner}[#2@inner]{#3}
    \theoremstyle{linked}
    \newtheorem{#1@innerlinked}[#2@innerlinked]{#3}
    \prop_gput:Nnn \g_my_theorems_prop { #1 } { #2 }
  } 
  \NewDocumentEnvironment{#1}{ o +b }{
    \IfNoValueTF{##1}
    { \begin{#1@inner} }
    { \begin{#1@inner}[##1] }
    \IfNoValueTF{ #2 }{ \label{#3\thechapter.\arabic{#1@inner}} }{ \label{#3\thechapter.\arabic{#2@inner}} }
    \tl_gset:Nx \g__my_theorems_number_tl { \use:c {@currentlabel} }
    ##2
    \end{#1@inner}
    \seq_gput_right:Nx \g_my_theorems_seq {
      { #1 }
      { \g__my_theorems_number_tl }
      \IfValueTF{##1}{{ \exp_not:n { ##1 } }}{{}}
      { \exp_not:n { ##2 } }
      { \thechapter }
    }
  }{}
  \IfNoValueT{ #2 }{ \counterwithin{equation}{#1@inner}\counterwithin{footnote}{#1@inner} }
  \AtBeginEnvironment{#1}{\ifnum\sumcounters=0 \begin{nihilist}\printtheorems\end{nihilist} \fi\clearpage}
  \theoremstyle{mytheorem}
}

\cs_new:Npn \my_plus_value:n #1 { + (\value{#1@inner}) }
 
\NewExpandableDocumentCommand{\sumcounters}{}{
  \int_eval:n { ( 0 \seq_map_function:NN \g_my_theorems_counters_seq \my_plus_value:n ) }
}

\NewDocumentCommand{\printtheorems}{}{
  \group_begin:
  \cs_set_eq:NN \label \use_none:n
  \cs_set_eq:cN { ltx@label } \use_none:n
  \cs_set_eq:NN \fnotetext \use_none:n
  \file_if_exist_input:n { \c_sys_jobname_str.thl }
  \group_end:
  \seq_map_inline:Nn \g_my_theorems_counters_seq { \setcounter{##1@inner}{0} }
}

\cs_new_protected:Nn \my_theorems_save: { \seq_map_function:NN \g_my_theorems_seq \__my_theorems_save:n }
\cs_new_protected:Nn \__my_theorems_save:n { \iow_now:Nn \g_my_theorems_stream { \savedtheorem #1 } }

\AtEndDocument{
  \iow_open:Nn \g_my_theorems_stream { \c_sys_jobname_str.thl }
  \my_theorems_save:
  \iow_close:N \g_my_theorems_stream
}

\NewDocumentCommand{\savedtheorem}{mmmmm}{
  \cs_set:cpn { the \prop_item:Nn \g_my_theorems_prop { #1 } @innerlinked }{ #2 }
  \int_compare:nT { \thechapter = #5 }{
    \IfNoValueTF{ #3 }{ \begin{#1@innerlinked} #4 \end{#1@innerlinked} }{ \begin{#1@innerlinked}[#3] #4 \end{#1@innerlinked} }
  }
} 
\ExplSyntaxOff

\newenvironment{nihilist}{
  \renewenvironment{equation}{\[}{\]}
  \renewcommand{\footnote}[1]{\hspace{-\the\fontdimen2\font\space}}
  \renewcommand{\fnotemark}[1]{##1}
}{}

% Theorems

\newtheoremstyle{linked}
{0pt}
{10pt}
{\itshape}
{}
{\bfseries}
{~~}
{0pt}
{%
  \hyperref[\thmname{#1}\thmnumber{#2}]{\thmname{#1}~\thmnumber{#2}}%
  \thmnote{\normalfont\scalebox{0.95}{~(#3)}}%
}

\newtheoremstyle{mytheorem}
{0pt}
{10pt}
{\itshape}
{}
{\bfseries}
{~~}
{0pt}
{%
  \thmname{#1}~\thmnumber{#2}%
  \thmnote{\normalfont\scalebox{0.95}{~(#3)}}%
}

\theoremstyle{mytheorem}

\newtheoremx{thm}{Teorema}[chapter]
\newtheoremx{lemma}[thm]{Lemma}
\newtheoremx{cor}[thm]{Corollario}

% Proofs

\renewenvironment{proof}{
  \pushQED{\qed}
  \trivlist\item[\hskip\labelsep\hspace{7pt}\textit{Proof.}]
  \mbox{}
  \vspace{2pt}\\
}{\popQED}

% References

\newcommand{\thm@innerautorefname}{Teorema}

\newcommand*{\thmref}[1]{%
  \begingroup
  \hypersetup{linkcolor=[RGB]{0, 0, 0}}%
  \hyperref[#1]{
    \textbf{\autoref{#1}}%
    \if\vcenter\getrefbykeydefault{#1}{name}{}\vcenter%
    \else%
    ~(\nameref{#1})%
    \fi
  }
  \endgroup
}

\let\oldeqref\eqref
\renewcommand{\eqref}[1]{%
  \begingroup
  \hypersetup{linkcolor=[RGB]{0, 0, 0}}%
  \oldeqref{#1}%
  \endgroup
}

\let\oldfootnote\footnote
\renewcommand{\footnote}[1]{%
  \begingroup
  \hypersetup{linkcolor=[RGB]{0, 0, 0}}%
  \oldfootnote{#1}%
  \endgroup
}

\let\oldfootnotemark\footnotemark
\renewcommand{\footnotemark}{%
  \begingroup
  \hypersetup{linkcolor=[RGB]{0, 0, 0}}%
  \oldfootnotemark%
  \endgroup
}

% Counters

\counterwithout{equation}{chapter}
\counterwithout{footnote}{section}

% Footnotes above symbols

\newcounter{stckrelfnotes}
\setcounter{stckrelfnotes}{-1}

\newcommand{\fnotemark}[1]{%
  \mathrel{\vbox{\offinterlineskip\ialign{\hfil##\hfil\cr$\scriptscriptstyle\footnotemark$\cr\noalign{\kern.05ex}$#1$\cr}}}%
  \addtocounter{stckrelfnotes}{1}
}

\newcommand{\fnotetext}[1]{%
  \ifnum\c@stckrelfnotes > -1
  \addtocounter{footnote}{\numexpr - \value{stckrelfnotes} -1}
  \addtocounter{Hfootnote}{\numexpr - \value{stckrelfnotes} -1}
  \fi
  \stepcounter{footnote}%
  \stepcounter{Hfootnote}%
  \hyper@makecurrent{Hfootnote}%
  \global\let\Hy@footnote@currentHref\@currentHref
  \footnotetext{#1}%
  \setcounter{stckrelfnotes}{-1}
}

\renewcommand{\thefootnote}{\normalfont\arabic{footnote}}

% Bibliography

\addbibresource{references.bib}

\renewbibmacro*{publisher+location+date}{
  \printlist{publisher}\iflistundef{location}{\setunit*{\addcomma~}}{\setunit*{\addcomma~}}
  \printlist{location}\setunit*{\addcomma~}\usebibmacro{date}\newunit
}
\let\cite\relax

\newcommand{\printbib}{
  \newgeometry{top = 2.8cm, bottom = 3cm, left = 3.3cm, right = 3.3cm}
  \printbibliography[heading=bibintoc]
  \restoregeometry
}

% Citations

\ExplSyntaxOn

\seq_new:N \l_parse_semicolon_seq
\seq_new:N \l_parse_comma_seq
\int_new:N \l_i_int
\int_new:N \l_j_int
\int_new:N \l_k_int

\NewDocumentCommand{ \cite }{ O{vedi}m }{
  \int_set:Nn \l_i_int {1}
  \unpenalty\unskip\unpenalty
  \scalebox{0.93}{
    (#1~
    \seq_set_split:Nnn \l_parse_semicolon_seq { ; } { #2 }
    \seq_map_inline:Nn \l_parse_semicolon_seq {
      \int_compare:nTF { \int_use:N \l_i_int = \seq_count:N \l_parse_semicolon_seq } {
        \split_the_commas:n { ##1 }
      }{
        \split_the_commas:n { ##1 } \int_incr:N \l_i_int ;~
      }
    }
    )
  } \\
}

\cs_new_protected:Nn \split_the_commas:n {
  \int_set:Nn \l_j_int { 1 }
  \seq_set_split:Nnn \l_parse_comma_seq { , } { #1 }
  \seq_map_inline:Nn \l_parse_comma_seq { 
    \int_compare:nTF { \int_use:N \l_j_int = 1 } {
      \str_if_in:nnTF{ ##1 }{ \url }{ \url{##1} }{ \parencite{##1} } 
    } { 
      \int_compare:nT { \int_use:N \l_j_int = 2 } {
        \int_compare:nTF { \seq_count:N \l_parse_comma_seq > 2 } { pp.~ } {
          \checkifdash{##1}
          \int_compare:nTF { \int_use:N \l_k_int = 0 } { p.~ } { pp.~ }
        }
      }
      \splitthedash{##1}
    }
    \int_compare:nF { \int_use:N \l_j_int = \seq_count:N \l_parse_comma_seq } {
      \int_compare:nTF { \int_use:N \l_j_int = 1 } { ~ } { ,~ }
      \int_incr:N \l_j_int
    }
  }
}

\RenewDocumentCommand{ \url }{ om }{ \IfValueTF{ #1 }{ \href{#2}{\texttt{#1}} }{ \href{#2}{\texttt{#2}} } }
\NewDocumentCommand{ \splitthedash }{ >{\SplitArgument{1}{-}}m }{ \auxsplit#1 }
\NewDocumentCommand{ \checkifdash }{ >{\SplitArgument{1}{-}}m }{ \auxcheck#1 }

\NewDocumentCommand{ \auxsplit }{ mm }{
  \IfValueTF{ #2 }{ \str_if_eq_x:nnTF{ #1 }{ #2 }{ #1 }{ #1\hspace{0.05cm}--\hspace{0.05cm}#2 } }{ #1 }
}

\NewDocumentCommand{ \auxcheck }{ mm }{
  \int_zero:N \l_k_int
  \IfValueT{ #2 }{ \str_if_eq_x:nnF{ #1 }{ #2 }{ \int_incr:N \l_k_int } }
}

\ExplSyntaxOff

% \me symbol

\DeclareRobustCommand{\me}{\reflectbox{{\fontfamily{cmr}\selectfont \clippedM$\mkern-6.45mu$\clippedR}}}

\newcommand{\clippedR}{
  \adjustbox{viewport=0pt {-.5pt} {0.65pt} {\dimexpr\height-.5pt}, clip, set depth=0pt}{R}
  \adjustbox{viewport=0.65pt {-.5pt} {\width} {\height}, clip, set depth=0pt}{R}
}

\newcommand{\clippedM}{
  \adjustbox{viewport=0pt {-.5pt} {0.8pt} {\dimexpr\height-.5pt}, clip, set depth=0pt}{M}
  \adjustbox{viewport=0.8pt {-.5pt} {\width} {\height}, clip, set depth=0pt}{M}
}

% Miscellaneous

\allowdisplaybreaks

\newcommand{\from}{\colon}

\let\C\relax
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\Q}{\mathbb{Q}}
\newcommand{\R}{\mathbb{R}}
\newcommand{\C}{\mathbb{C}}
\endinput