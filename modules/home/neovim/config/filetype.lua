vim.filetype.add({
  extension = {
    age = "age",
    pub = "pub",
  },
  pattern = {
    [".*/%.github/workflows/.*%.yaml"] = "yaml.ghaction",
    [".*/%.github/workflows/.*%.yml"] = "yaml.ghaction",
  },
})
