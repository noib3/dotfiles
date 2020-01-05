\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{test}[]
\LoadClass[11pt]{book}

% Options

% Filter warnings

% Packages

\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}

\RequirePackage{amsmath}
\RequirePackage{amsthm}
\RequirePackage{enumitem}
\RequirePackage{floatrow}
% \RequirePackage{geometry}
\RequirePackage{graphicx}

\RequirePackage{hyperref}
\hypersetup{linktoc=all, linkcolor=black}

\RequirePackage[letterspace=200]{microtype}

\RequirePackage{pgfplots}
\pgfplotsset{compat=1.16, compat/show suggested version=false, ticks=none}

\RequirePackage{titlesec}
\RequirePackage{titletoc}
\RequirePackage{wrapfig}

% Geometry

\RequirePackage[letterpaper, left=1in, top=1in, headsep=2\baselineskip, textwidth=26pc, marginparsep=2pc, marginparwidth=12pc, textheight=44\baselineskip, headheight=\baselineskip]{geometry}
\setlength\marginparpush{10pt}

% Colors

\definecolor{bordeaux}{RGB}{155, 47, 53}
\definecolor{lightgray}{RGB}{130, 130, 130}
\definecolor{fillgray}{RGB}{240, 240, 240}

% Title

\RequirePackage{tgheros}

\newcommand{\@publisher}{}
\newcommand*{\publisher}[1]{\gdef\@publisher{#1}}
\newcommand{\allcaps}[1]{\textsf{\textls{\MakeUppercase{#1}}}}

\renewcommand{\maketitle}{
  \thispagestyle{empty}
  \begingroup
  \color{darkgray}
  \fontsize{17.28}{20}\selectfont\noindent\scalebox{0.90}{\allcaps{\@author}}
  \vspace{11.5pc}
  \fontsize{36}{45}\selectfont\par\noindent\scalebox{0.90}{\allcaps{\,Appunti di}}
  \fontsize{36}{45}\selectfont\par\noindent\scalebox{0.90}{\allcaps{\,metodi matematici}}
  \fontsize{36}{45}\selectfont\par\noindent\scalebox{0.90}{\allcaps{\,per la fisica}}
  \vfill
  \fontsize{14}{16}\selectfont\noindent\scalebox{0.90}{\allcaps{\@publisher}}
  \endgroup
}

% ToC sectioning


% Document sectioning


% Headers and footers

  
% Theorems


% Proofs


% References


% Counters


% Miscellaneous

\endinput