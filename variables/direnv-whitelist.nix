# Per-user direnv whitelist — which .envrc files direnv may auto-allow without
# the "is blocked" prompt. Returns { prefix; exact; } for programs.direnv.config.
#
# Only the specific repos listed here are trusted — not your whole home, not a
# blanket parent folder, and nothing is inferred. This flake repo (flakedir) is
# always included. To trust more repos, list each one by bare name in
# `extraRepos`; each resolves relative to repoParent (this flake's parent dir).
# Then run: hm:switch
{ homedir, flakedir }:
let
  # Parent folder this flake repo lives in (e.g. ~/Code, ~/dev, ~/projects).
  repoParent = builtins.dirOf flakedir;

  # Other repos to trust, by bare name, assumed to sit alongside this repo
  # under repoParent. e.g. [ "some-repo" "another-repo" ]
  extraRepos = [
    "rgr-platform"
    "rgr-discussions"
    "rgr-infra"
    "rgr-claude"
  ];
in
{
  # Trusted as prefixes: the repo dir AND any git worktrees created on the fly
  # under it are covered.
  prefix = [ flakedir ] ++ map (repo: "${repoParent}/${repo}") extraRepos;

  # Trusted as exact paths: only this file itself, not anything in subdirs.
  # ~/.envrc is the home-level loader (dotenv $HOME/.env) set up at activation.
  exact = [ "${homedir}/.envrc" ];
}
