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


if __name__ == "__main__":
    unittest.main()
