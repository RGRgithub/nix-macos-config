# .envrc files direnv may auto-allow. Only the repos listed here are trusted:
# never all of $HOME or a blanket parent folder. This repo is always included;
# add more by bare name to `extraRepos` (resolved next to this repo), then hm:switch.
{ homedir, flakedir }:
let
  repoParent = builtins.dirOf flakedir;

  extraRepos = [
    "rgr-platform"
    "rgr-discussions"
    "rgr-infra"
    "rgr-claude"
  ];
in
{
  # Prefix match, so worktrees under each repo are covered too.
  prefix = [ flakedir ] ++ map (repo: "${repoParent}/${repo}") extraRepos;

  # The home-level ~/.envrc loader only, not its subdirectories.
  exact = [ "${homedir}/.envrc" ];
}
