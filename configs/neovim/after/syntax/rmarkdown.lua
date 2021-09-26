local cmd = vim.cmd

cmd([[syntax region texAlign start=/\\begin{align}/ end=/\\end{align}/ keepend contains=@LATEX]])

-- cmd([[highlight link texAlign pandocLaTeXMathBlock]])
