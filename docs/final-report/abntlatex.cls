\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{abntlatex}[2024-07-17 v1.0 .dtx ABNT Latex]
\PassOptionsToClass{
  a4paper, % Se impresso o documento deve estar no formato a4
  12pt}{article}%
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass{article}
\RequirePackage[a4paper, 
                top    = 3.0cm, 
                bottom = 2.0cm, 
                left   = 3.0cm, 
                right  = 2.0cm]{geometry}
\RequirePackage[brazilian]{babel}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{indentfirst}
\RequirePackage{microtype}
\RequirePackage{hyperref}
\RequirePackage[brazilian, hyperpageref]{backref}	
\newcommand{\splittext}[2][,]{%
\begingroup%
    \def\start{}%
    \def\itemseparate{#1}%
    \expandafter\splitaux#2\end%
\endgroup
}
\def\splitaux#1\end{%
    \@split \start#1,\end,%
}
\def\@split #1,{%
    \ifx\end#1%
        \unskip\char46% char 46 = .
    \else%
        \ifx\start#1%
        \else%
            \unskip\itemseparate\space\ignorespaces#1%
        \fi%
        \expandafter\@split%
    \fi%
}

\newif\if@changetoonecolumn
\@changetoonecolumnfalse

\@ifpackageloaded{setspace}{
    \relax
}{
  \def\setstretch#1{
    \def\baselinestretch{#1}\@currsize\vskip\baselineskip
  }
}
\newcommand\pretext{%
  \if@twocolumn%
    \onecolumn%
    \@changetoonecolumntrue
  \fi
  \frenchspacing%
  \pagenumbering{arabic}%
  \pagestyle{empty}%
  \setstretch{1.5}%
}
\newcommand*{\university}[1]{\gdef\@university{#1}}
\newcommand*{\subtitle}[1]{\gdef\@subtitle{#1}}
\newcommand*{\predate}[1]{\gdef\@predate{#1}}
\newcommand*{\documenttype}[1]{\gdef\@documenttype{#1}}
\newcommand*{\preamble}[1]{\gdef\@preamble{#1}}
\newcommand*{\supervisor}[1]{\gdef\@supervisor{#1}}
\newcommand*{\cosupervisor}[1]{\gdef\@cosupervisor{#1}}
\newcommand*{\keywords}[1]{\gdef\@keywords{#1}
\renewcommand{\@maketitle}{%
  \newpage%
  \null%
  \vskip 2em%
  \begin{center}%
    \begin{minipage}[t][0.5\textheight]{\textwidth}%
      \centering
      {\ifdefined\@university% Opcional
          \setstretch{1}%
          \large\@university\par
        \fi
      }%
      \vspace*{2cm}%
      \let\footnote\thanks%
      {\large\begin{tabular}[t]{c}%
        \@author% Obrigatorio
      \end{tabular}\par}%
        
      \vspace*{\fill}%
      {\LARGE\@title}% Obrigatorio
      {\ifdefined\@subtitle%
        {\LARGE:\par}{\Large\@subtitle\par}% Opcional
        \fi
      }%
    \end{minipage}%

    \vspace*{\fill}%
    {\ifdefined\@predate
        \normalsize\@predate\par%
      \else
        \ClassWarning{abntlatex}{\string\@predate\space Required element in ABNT standards for academic papers.}
      \fi
    }% Obrigatorio
    {\normalsize\@date}% Obrigatorio
  \end{center}%
  \par\vskip 1.5em%
}

\let\mymaketitle\maketitle
\renewcommand{\maketitle}{
  \let\save@author\@author%
  \let\save@title\@title%
  \renewcommand{\thepage}{Cover}%
  \mymaketitle%
  \thispagestyle{empty}%
  \cleardoublepage%
  \pagenumbering{arabic}%
  \let\@title\save@title%
  \let\@author\save@author%
}

\let\cover\maketitle
\newcommand{\@backcover}{%
  \newpage%
  \null%
  \vskip 2em%
  \begin{center}%
    \begin{minipage}[t][0.33\textheight]{\textwidth}%
      \centering%
      {\normalsize\begin{tabular}[t]{c}%
        \@author%
      \end{tabular}\par}%
      \vspace*{\fill}%

      {\LARGE\@title}%
      {\ifdefined\@subtitle%
          {\LARGE:\par}\Large\@subtitle\par
        \fi
      }%
    \end{minipage}
    \vspace*{\fill}%
      
    {\raggedleft
    \begin{minipage}[c]{0.5\textwidth}%
      \setstretch{1}%
      {\ifdefined\@documenttype
          \small\@documenttype\par
        \fi
      }%
      {\ifdefined\@preamble
          \small\@preamble\par
        \fi
      }%
      {\ifdefined\@university
          \small\@university\par
        \fi
      }%
    \vspace*{\fill}%
    \end{minipage}\par}%
    \vspace*{\fill}%

    {\ifdefined\@supervisor%
        \normalsize Orientador: \@supervisor \par
      \fi
    }%
    {\ifdefined\@cosupervisor%
        \normalsize Coorientador: \@cosupervisor \par
      \fi
    }%
    \vspace*{\fill}%

    {\ifdefined\@predate%
        \normalsize\@predate\par
      \fi
    }%
    {\normalsize\@date}%
  \end{center}%
  \par\vskip 1.5em%
}

\newcommand{\backcover}{%
  %\renewcommand{\thepage}{Back Cover}%
  \if@twocolumn
    \ifnum\col@number=\@ne 
      \@backcover 
    \else 
      \twocolumn [ \@backcover ]
    \fi 
  \else 
    \newpage\@backcover 
  \fi
  \thispagestyle{empty}%
  \newpage%
}
\newcommand{\@intercatalog}{%
  \newpage%
  \null%
  \vskip 2em%
  \vspace*{\fill}%
  \begin{center}
  \begin{minipage}{0.8\linewidth}
  \begin{center}
    \textbf{\large Dados Internacionais de Catalogação na Publicação (CIP)}\par
    \textbf{\large (Câmera Brasileira do Livro, SP - Brasil)}
    \vskip 1em%
    \framebox{\begin{minipage}{0.8\linewidth}\vskip 0.25em%
      \begin{center}\begin{minipage}{0.8\linewidth}
        \@title, \@author\par
        \setlength\parindent{24pt}
        Nononononononono: nonononononnonon / nononononononon. -- 1. ed. -- Nononononononon: Nonononononononononon, 2022.\par\setlength{\parskip}{12pt}
        ISBN: 000-00-00000-00-0\par
        1. Nononononononono
      \end{minipage}\end{center}
      00-00000\hfill CDD-000.0
    \end{minipage}}
    \vskip 1em%
    \textbf{Índices para catálogo sistemático:}
  \end{center}
  XXXXXXX XXXXXXXX XXX\hfill CRB-XXXXXXXXXXXXX
  \end{minipage}
  \end{center}
  \par\vskip 1.5em%
}

\newcommand{\intercatalog}{%
  \if@twocolumn
    \ifnum\col@number=\@ne 
      \@intercatalog 
    \else 
      \twocolumn [ \@intercatalog ]
    \fi 
  \else 
    \newpage\@intercatalog 
  \fi
  \let\actualpagenumering\thepage
  \pagenumbering{gobble}%
  \thispagestyle{empty}%
  \newpage%
  \pagenumbering{arabic}
  \setcounter{page}{\numexpr\actualpagenumering+1\relax}
}
\addto\captionsbrazilian{
  \renewcommand{\abstractname}{Resumo}
}
\addto\captionsenglish{
  \renewcommand{\abstractname}{Abstract}
}

\newcommand{\keywordname}{}
\addto\captionsbrazilian{
  \renewcommand{\keywordname}{Palavras-chave}
}
\addto\captionsenglish{
  \renewcommand{\keywordname}{Keyword}
}

\renewenvironment{abstract}[1][brazilian]{%
\begin{otherlanguage}{#1}
\if@twocolumn%
  \section*{\abstractname}
\else%
  \small\begin{center}
    {\section*{\abstractname}\vspace{-.5em}\vspace{\z@}}
  \end{center}
  \quotation
\fi
}{%
  {\par\null\par\noindent\textbf{\keywordname: }}%
  \splittext[;]{\@keywords}
\end{otherlanguage}
\newpage%
}
\newenvironment{page}[1][Página]{%
  \begin{center}%
    \section*{#1}
  \end{center}%
}{%
\newpage%
}
\addto\captionsbrazilian{%
  \renewcommand{\listfigurename}{{Lista de Ilustrações}}%
}%

\def\caption@mynumberline#1{
  \hb@xt@ \@tempdima {\figurename~#1\hfil---\hfil}
}

\renewcommand{\listoffigures}{%
  {\centering\section*{\listfigurename}}
  \@mkboth 
    {\MakeUppercase \listfigurename }
    {\MakeUppercase \listfigurename }
  \begingroup
    \let\numberline\caption@mynumberline
    \@starttoc{lof}%
  \endgroup
  \newpage
}

\renewcommand*\l@figure[2]{\@dottedtocline{1}{\z@}{5.5em}{#1}{#2}}%
\def\table@mynumberline#1{
  \hb@xt@ \@tempdima {\listtablename~#1\hfil---\hfil}
}

\renewcommand\listoftables{%
  {\centering\section*{\listtablename}}
  \@mkboth 
    {\MakeUppercase \listtablename }
    {\MakeUppercase \listtablename }
  \begingroup
    \let\numberline\table@mynumberline
    \@starttoc{lof}%
  \endgroup
  \newpage
}
\renewcommand*\l@table[2]{\@dottedtocline{1}{\z@}{5.5em}{#1}{#2}}%
\renewcommand\@tocrmarg{2.0cm}

\renewcommand\tableofcontents{%
  {\centering\section*{\contentsname}}%

  \@starttoc{toc}%
  \newpage
}
\newlength{\@sizecontentnumber}%
\settowidth{\@sizecontentnumber}{0.0.0\quad}%
\renewcommand*\l@section[2]{\@dottedtocline{1}{\z@}%
  {\@sizecontentnumber}{\@section@style#1}{#2}%
}%
\renewcommand*\l@subsection[2]{\@dottedtocline{1}{\z@}%
  {\@sizecontentnumber}{\@subsection@style#1}{#2}%
}%
\renewcommand*\l@subsubsection[2]{\@dottedtocline{1}{\z@}%
  {\@sizecontentnumber}{\@subsubsection@style#1}{#2}%
}%
\newcommand\maintext{%
  \if@changetoonecolumn
    \twocolumn
  \fi
  \frenchspacing%
  \pagestyle{myheadings}%
  \setstretch{1.5}
}
\let\oldcite\cite
\renewcommand*\@cite[1]{#1}
\renewcommand*\cite[2][\@empty]{(\oldcite{#2}\ifx#1\@empty\relax\else, #1\fi)}
\gdef\@section@style{\slshape\bfseries}
\newcommand*{\sectionsty}[1]{\gdef\@section@style{#1}}%

\gdef\@subsection@style{\bfseries}
\newcommand*{\subsectionsty}[1]{\gdef\@subsection@style{#1}}%

\gdef\@subsubsection@style{}
\newcommand*{\subsubsectionsty}[1]{\gdef\@subsubsection@style{#1}}%

\renewcommand\section{%
  \if@twoside%
    \cleardoublepage%
  \fi% 
  \@startsection{section}{1}{\z@}%
  {\z@}%
  {12pt}%
  {\normalfont\Large\@section@style}%
}
\renewcommand\subsection{%
  \@startsection{subsection}{2}{\z@}%
  {-12pt}%
  {12pt}%
  {\normalfont\large\@subsection@style}%
}
\renewcommand\subsubsection{%
  \@startsection{subsubsection}{3}{\z@}%
  {-12pt}%
  {12pt}%
  {\normalfont\large\@subsubsection@style}%
}
\let\save@figure\figure
\def\figure{\setstretch{1.0}\centering\@ifnextchar[\figure@i \figure@ii}
\def\figure@i[#1]{\save@figure[#1]\centering}
\def\figure@ii{\save@figure\centering}

\newcommand\descrfigure[2][\@empty]{%
\caption*{\small \ifx#1\@empty\relax\else#1:~\fi#2}}

\newcommand\backtext{%
  \if@twocolumn%
  \onecolumn
  \fi
  \frenchspacing%
  \bibliographystyle{abnt}%
  % \bibliographystyle{unsrt}%
  \pagestyle{myheadings}%
  \setstretch{1}
}
\renewcommand*{\@biblabel}[1]{\footnotemark[#1]}
\def\thebibliography#1{%
  \newpage%
  \phantomsection%
  \addcontentsline{toc}{section}{\protect\numberline{}\refname}%

  {\centering\section*{\refname}}%
  \list{\@biblabel{\arabic{enumi}}}%
    {\settowidth\labelwidth{(#1)}%
      \leftmargin\labelwidth\advance\leftmargin\labelsep%
        \usecounter{enumi}%
    }%
  \def\newblock{\hskip .11em plus .33em minus .07em}%
  \sloppy\clubpenalty4000\widowpenalty4000\sfcode`\.=1000\relax%
}
\renewcommand{\backref}{}
\renewcommand*{\backrefalt}[4]{
  \ifcase #1
    Nenhuma citação no texto.
  \or
    Citado na página #2.
  \else
    Citado #1 vezes nas páginas #2.
  \fi
}
\addto\captionsbrazilian{
  \renewcommand{\appendixname}{Apêndice}
}
\addto\captionsenglish{
  \renewcommand{\appendixname}{Appendix}
}

\newenvironment{appendixenv}[1][default]{%
  \pagestyle{plain}
  \begingroup
  \appendix
  \cleardoublepage
  \def\arg{#1}%
  \def\default{default}%
  \ifx\arg\default
    \thispagestyle{empty}
    \vspace*{\fill}
    {%
        \centering\part*{\centering\scshape\Huge\appendixname}%
        \phantomsection%
        \addcontentsline{toc}{chapter}{\protect\numberline{}\appendixname}%
    }
    \vspace*{\fill}
  \fi
  \pagenumbering{Roman}\newpage
}{%
  \endgroup
  \newpage
}
\endinput
