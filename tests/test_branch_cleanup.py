"""Safety regression tests for branch hygiene; no GitHub network calls."""
import importlib.util
import pathlib
import unittest

FILE = pathlib.Path(__file__).resolve().parents[1] / "tools" / "branch_cleanup.py"
spec = importlib.util.spec_from_file_location("branch_cleanup", FILE)
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


def branch(name, sha="111", protected=False):
    return {"name": name, "commit": {"sha": sha}, "protected": protected}


def pr(name, sha="111", merged=True, state="closed", base="main", repo="DoctorStrangeSH/Last-Ritual"):
    return {
        "number": 20,
        "state": state,
        "merged_at": "2026-11-03T12:00:00Z" if merged else None,
        "head": {"ref": name, "sha": sha, "repo": {"full_name": repo}},
        "base": {"ref": base},
    }


class BranchCleanupTests(unittest.TestCase):
    repo = "DoctorStrangeSH/Last-Ritual"

    def test_only_exact_merged_head_eligible(self):
        name = "feature/done"
        candidates, review, preserved = cleanup.analyze([branch(name)], [pr(name)], self.repo)
        self.assertEqual([x["branch"] for x in candidates], [name])
        self.assertFalse(review)
        self.assertFalse(preserved)

    def test_preserve_main_protected_and_checkpoints(self):
        branches = [branch("main"), branch("archive/old"), branch("checkpoint/v0.9"), branch("feature/protected", protected=True)]
        prs = [pr(item["name"]) for item in branches]
        candidates, review, preserved = cleanup.analyze(branches, prs, self.repo)
        self.assertFalse(candidates)
        self.assertFalse(review)
        self.assertEqual(len(preserved), 4)

    def test_closed_unmerged_and_open_are_not_deleted(self):
        branches = [branch("feature/abandoned"), branch("feature/open")]
        prs = [pr("feature/abandoned", merged=False), pr("feature/open", state="open")]
        candidates, review, _ = cleanup.analyze(branches, prs, self.repo)
        self.assertFalse(candidates)
        self.assertEqual(len(review), 2)

    def test_advanced_branch_or_cross_repo_cannot_be_deleted(self):
        branches = [branch("feature/advanced", sha="222"), branch("feature/fork")]
        prs = [pr("feature/advanced"), pr("feature/fork", repo="other/repo")]
        candidates, review, _ = cleanup.analyze(branches, prs, self.repo)
        self.assertFalse(candidates)
        self.assertEqual(len(review), 2)

    def test_unknown_or_unrelated_base_must_be_reviewed(self):
        branches = [branch("feature/no-pr"), branch("feature/wrong-base")]
        prs = [pr("feature/wrong-base", base="development")]
        candidates, review, _ = cleanup.analyze(branches, prs, self.repo)
        self.assertFalse(candidates)
        self.assertEqual(len(review), 2)


class ArchiveListTests(unittest.TestCase):
    def entry(self, name, sha="111", recovery="pull/7/head"):
        return {"branch": name, "sha": sha, "recovery": recovery, "note": ""}

    def test_pr_ref_and_main_history_are_valid_recovery(self):
        entries = [self.entry("feature/old"), self.entry("archive/classic", sha="abc", recovery="main")]
        approved, rejected = cleanup.verify_archive_entries(
            entries, [branch("feature/old"), branch("archive/classic", sha="abc")],
            {7: "111"}.get, lambda sha: sha == "abc")
        self.assertEqual([x["branch"] for x in approved], ["feature/old", "archive/classic"])
        self.assertFalse(rejected)

    def test_moved_branch_or_mismatched_pr_is_kept(self):
        entries = [self.entry("feature/moved"), self.entry("feature/other-pr")]
        approved, rejected = cleanup.verify_archive_entries(
            entries, [branch("feature/moved", sha="999"), branch("feature/other-pr")],
            {7: "222"}.get, lambda sha: False)
        self.assertFalse(approved)
        self.assertEqual({x["reason"] for x in rejected}, {"branch moved since review", "PR head does not preserve this SHA"})

    def test_main_protected_unknown_recovery_and_not_in_main_are_kept(self):
        entries = [self.entry("main"), self.entry("feature/protected"), self.entry("feature/x", recovery="bundle"),
                   self.entry("feature/y", recovery="main")]
        branches = [branch("main"), branch("feature/protected", protected=True), branch("feature/x"), branch("feature/y")]
        approved, rejected = cleanup.verify_archive_entries(entries, branches, {7: "111"}.get, lambda sha: False)
        self.assertFalse(approved)
        self.assertEqual(len(rejected), 4)

    def test_repository_archive_list_is_well_formed(self):
        path = FILE.parents[1] / "docs" / "branch_archive.tsv"
        entries = cleanup.load_archive_list(path)
        self.assertGreater(len(entries), 0)
        self.assertNotIn("main", [e["branch"] for e in entries])
        for e in entries:
            self.assertRegex(e["sha"], r"^[0-9a-f]{40}$", e["branch"])
            self.assertRegex(e["recovery"], r"^(main|pull/\d+/head)$", e["branch"])


if __name__ == "__main__":
    unittest.main()
