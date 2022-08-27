vim.cmd([[
  " jenkinsfile
  augroup _jenkins
    autocmd!
    autocmd BufRead,BufNewFile *.jenkins set filetype=groovy
    autocmd BufRead,BufNewFile jenkinsfile set filetype=groovy
    autocmd BufRead,BufNewFile Jenkinsfile set filetype=groovy
  augroup end
]])
