#!/usr/bin/env python3
"""Audit and optionally prune remote branches whose exact heads belong to merged PRs.

Dry-run by default. Uses stdlib only and requires GITHUB_TOKEN with repo access.
Default mode never touches unmerged, unknown, protected, archived or checkpoint branches.
`--archive-list docs/branch_archive.tsv` removes only reviewed branches whose exact
SHA is preserved in main history or in a GitHub PR ref (refs/pull/N/head).
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter

API = "https://api.github.com"
PRESERVE_PREFIXES = ("archive/", "checkpoint/")
USER_AGENT = "last-ritual-branch-hygiene/1.0"


def api(method, path, token):
    req = urllib.request.Request(
        API + path,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": "Bearer " + token,
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": USER_AGENT,
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=35) as response:
            data = response.read()
            return json.loads(data) if data else {}
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {path}: HTTP {error.code}: {body[:250]}") from error


def paged(path, token):
    results = []
    for page in range(1, 100):
        join = "&" if "?" in path else "?"
        chunk = api("GET", f"{path}{join}per_page=100&page={page}", token)
        if not isinstance(chunk, list):
            raise RuntimeError("Expected list from " + path)
        results.extend(chunk)
        if len(chunk) < 100:
            return results
    raise RuntimeError("Pagination limit reached, refusing incomplete audit")


def analyze(branches, pull_requests, repo):
    prs_by_branch = {}
    for pr in pull_requests:
        head = pr.get("head") or {}
        if (head.get("repo") or {}).get("full_name") != repo:
            continue
        prs_by_branch.setdefault(head.get("ref"), []).append(pr)

    candidates, review, preserved = [], [], []
    for item in branches:
        name = item["name"]
        if name == "main" or item.get("protected") or name.startswith(PRESERVE_PREFIXES):
            preserved.append({"branch": name, "reason": "main/protected/archive/checkpoint"})
            continue
        prs = prs_by_branch.get(name, [])
        if len(prs) != 1:
            review.append({"branch": name, "reason": "no PR or multiple PRs"})
            continue
        pr = prs[0]
        if pr.get("state") == "open" or not pr.get("merged_at"):
            review.append({"branch": name, "reason": "not merged", "pr": pr["number"]})
            continue
        # A merged PR is insufficient: the branch might have new, unmerged commits.
        if pr.get("head", {}).get("sha") != item.get("commit", {}).get("sha"):
            review.append({"branch": name, "reason": "branch advanced since PR", "pr": pr["number"]})
            continue
        if (pr.get("base") or {}).get("ref") != "main":
            review.append({"branch": name, "reason": "PR did not target main", "pr": pr["number"]})
            continue
        candidates.append({"branch": name, "sha": item["commit"]["sha"], "pr": pr["number"]})
    return candidates, review, preserved


def load_archive_list(path):
    """Read the reviewed TSV of branches approved for removal (comments start with #)."""
    entries = []
    with open(path, encoding="utf-8") as fp:
        rows = [line.rstrip("\n") for line in fp if line.strip() and not line.startswith("#")]
    header = rows[0].split("\t") if rows else []
    if header[:3] != ["branch", "sha", "recovery"]:
        raise ValueError("archive list must start with header: branch, sha, recovery, note")
    for line in rows[1:]:
        cells = line.split("\t")
        if len(cells) < 3:
            raise ValueError("malformed archive row: " + line)
        entries.append({"branch": cells[0], "sha": cells[1], "recovery": cells[2], "note": cells[3] if len(cells) > 3 else ""})
    return entries


def verify_archive_entries(entries, branches, pr_head_sha, in_main):
    """Approve only branches whose commits stay recoverable after deletion.

    pr_head_sha(number) -> head SHA of that PR (or None); in_main(sha) -> bool.
    A branch is approved when its current SHA equals the reviewed SHA and either
    that SHA is an ancestor of main, or PR #N still points at exactly that SHA.
    """
    by_name = {item["name"]: item for item in branches}
    approved, rejected = [], []
    for entry in entries:
        name, sha, recovery = entry["branch"], entry["sha"], entry["recovery"]
        current = by_name.get(name)
        if name == "main":
            rejected.append({"branch": name, "reason": "main is never removed"})
        elif current is None:
            rejected.append({"branch": name, "reason": "already absent"})
        elif current.get("protected"):
            rejected.append({"branch": name, "reason": "protected"})
        elif current.get("commit", {}).get("sha") != sha:
            rejected.append({"branch": name, "reason": "branch moved since review"})
        elif recovery == "main":
            if in_main(sha):
                approved.append({"branch": name, "sha": sha, "recovery": recovery})
            else:
                rejected.append({"branch": name, "reason": "not contained in main"})
        elif recovery.startswith("pull/") and recovery.endswith("/head") and recovery[5:-5].isdigit():
            if pr_head_sha(int(recovery[5:-5])) == sha:
                approved.append({"branch": name, "sha": sha, "recovery": recovery})
            else:
                rejected.append({"branch": name, "reason": "PR head does not preserve this SHA"})
        else:
            rejected.append({"branch": name, "reason": "unknown recovery " + recovery})
    return approved, rejected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive-list", help="Reviewed TSV of branches to remove after verifying recovery refs")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "DoctorStrangeSH/Last-Ritual"))
    parser.add_argument("--execute", action="store_true", help="Actually delete verified branches")
    parser.add_argument("--limit", type=int, default=50, help="Max branches deleted per run (1-50)")
    parser.add_argument("--report", default="branch-cleanup-report.json")
    args = parser.parse_args()
    if args.limit < 1 or args.limit > 50:
        parser.error("--limit must be between 1 and 50")
    if args.execute and os.environ.get("ALLOW_BRANCH_DELETE") != "true":
        parser.error("Deletion requires ALLOW_BRANCH_DELETE=true")
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        parser.error("GITHUB_TOKEN or GH_TOKEN is required")
    repo = args.repo
    if repo.count("/") != 1:
        parser.error("Expected OWNER/REPO")
    prefix = "/repos/" + repo
    info = api("GET", prefix, token)
    default = info.get("default_branch")
    if default != "main":
        parser.error(f"Refusing repository with unexpected default branch {default}")

    branches = paged(prefix + "/branches", token)
    prs = paged(prefix + "/pulls?state=all", token)
    if args.archive_list:
        pr_heads = {pr["number"]: (pr.get("head") or {}).get("sha") for pr in prs}

        def in_main(sha):
            compare = api("GET", f"{prefix}/compare/{sha}...main", token)
            return compare.get("status") in ("ahead", "identical")

        candidates, review = verify_archive_entries(load_archive_list(args.archive_list), branches, pr_heads.get, in_main)
        preserved = []
    else:
        candidates, review, preserved = analyze(branches, prs, repo)
    removed, skipped, errors = [], [], []
    if args.execute:
        for candidate in candidates[:args.limit]:
            name, old_sha = candidate["branch"], candidate["sha"]
            quoted = urllib.parse.quote(name, safe="/")
            try:
                # Recheck immediately before deleting. GitHub's DELETE ref endpoint
                # has no atomic SHA lease, so don't run this during active development.
                current = api("GET", prefix + "/branches/" + urllib.parse.quote(name, safe=""), token)
                if current.get("protected") or current.get("commit", {}).get("sha") != old_sha:
                    skipped.append({"branch": name, "reason": "changed/protected since audit"})
                    continue
                api("DELETE", prefix + "/git/refs/heads/" + quoted, token)
                removed.append(name)
                time.sleep(0.12)
            except Exception as exc:
                errors.append({"branch": name, "error": str(exc)})
    report = {
        "repository": repo,
        "mode": "execute" if args.execute else "dry-run",
        "total_branches": len(branches),
        "total_pull_requests": len(prs),
        "eligible": len(candidates),
        "review_required": review,
        "preserved": preserved,
        "eligible_branches": candidates,
        "removed": removed,
        "skipped": skipped,
        "errors": errors,
    }
    with open(args.report, "w", encoding="utf-8") as fp:
        json.dump(report, fp, ensure_ascii=False, indent=2)
    summary = (
        f"## Safe branch cleanup ({report['mode']})\n\n"
        f"- Repository: `{repo}`\n"
        f"- Branches scanned: **{len(branches)}**\n"
        f"- Verified removal candidates: **{len(candidates)}**\n"
        f"- Requires manual review: **{len(review)}**\n"
        f"- Preserved: **{len(preserved)}**\n"
        f"- Deleted this run: **{len(removed)}**\n"
        f"- Skipped/failed: **{len(skipped)}/{len(errors)}**\n"
        f"- Full JSON: `{args.report}`\n"
    )
    print(summary)
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as fp:
            fp.write(summary)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
