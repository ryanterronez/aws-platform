resource "github_repository" "areopagus" {
  name       = "areopagus"
  visibility = "private"
}

resource "github_branch_default" "areopagus" {
  repository = github_repository.areopagus.name
  branch     = "main"
  rename     = true
}
