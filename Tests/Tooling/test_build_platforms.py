"""The build must not report a successful but incomplete Shortcut package."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('build_platforms', Path(__file__).resolve().parents[2] / 'Scripts/build_platforms.py')
builds = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builds)


class ShortcutBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.build = self.root / 'derived'
        self.build.mkdir()
        self.metadata = self.build / 'Build/Products/Debug-iphonesimulator/HomeViewReplica.app/Metadata.appintents'

    def package(self, training=True):
        self.metadata.mkdir(parents=True, exist_ok=True)
        (self.metadata / 'extract.actionsdata').write_text(json.dumps({'actions': {'OpenHomeViewAssistantIntent': {}}}))
        (self.metadata / 'version.json').write_text('{"version":"3.0"}')
        if training:
            (self.metadata / 'nlu').mkdir(exist_ok=True)
            (self.metadata / 'root.ssu.yaml').write_text('bundleIdentifier: org.example.HomeViewReplica\nname: OpenHomeViewAssistantIntent_0\n')
            (self.metadata / 'nlu/nlu.lzfse').write_bytes(b'synthetic-compressed-payload')
            (self.metadata / 'nlu/test.version').write_bytes(b'\0')

    def test_complete_build_needs_no_clean_and_records_artifact_hashes(self):
        self.package()
        with patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        self.assertEqual(row['exit_code'], 0)
        self.assertEqual(run.call_count, 1)
        self.assertEqual(len(row['attempts'][0]['shortcut_artifacts']['files']), 5)
        self.assertTrue(all(len(f['sha256']) == 64 for f in row['attempts'][0]['shortcut_artifacts']['files']))

    def test_incremental_omission_gets_one_standard_clean_build_and_keeps_first_failure(self):
        def run(command, **kwargs):
            self.package(training='clean' in command)
            return subprocess.CompletedProcess(command, 0)
        with patch.object(builds.subprocess, 'run', side_effect=run) as runner:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        self.assertEqual(row['exit_code'], 0)
        self.assertEqual(runner.call_count, 2)
        self.assertFalse(row['attempts'][0]['shortcut_artifacts']['valid'])
        self.assertTrue(row['attempts'][1]['shortcut_artifacts']['valid'])
        self.assertEqual(row['attempts'][0]['command'][:-1], row['attempts'][1]['command'][:-2])
        self.assertEqual(row['attempts'][1]['command'][-2:], ['clean', 'build'])
        self.assertNotEqual(row['attempts'][0]['log'], row['attempts'][1]['log'])

    def test_persistently_incomplete_success_fails_closed_after_one_recovery(self):
        self.package(training=False)
        with patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        self.assertEqual(run.call_count, 2)
        self.assertEqual(row['exit_code'], 1)
        self.assertFalse(row['ios_shortcut_artifacts_valid'])

    def test_compile_failure_is_not_retried_or_relabelled(self):
        with patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 65)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        self.assertEqual(run.call_count, 1)
        self.assertEqual(row['exit_code'], 65)
        self.assertNotIn('shortcut_artifacts', row['attempts'][0])

    def test_non_ios_success_does_not_require_ios_training(self):
        with patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[1])
        self.assertEqual(row['exit_code'], 0)
        self.assertEqual(run.call_count, 1)
        self.assertNotIn('shortcut_artifacts', row['attempts'][0])

    def test_present_but_wrong_or_empty_artifacts_are_not_a_pass(self):
        self.package()
        (self.metadata / 'extract.actionsdata').write_text('{"actions":{}}')
        (self.metadata / 'version.json').write_text('[]')
        (self.metadata / 'root.ssu.yaml').write_text('wrong app')
        (self.metadata / 'nlu/nlu.lzfse').write_bytes(b'')
        result = builds.ios_shortcut_artifacts(self.build)
        self.assertFalse(result['valid'])
        self.assertEqual(len(result['errors']), 4)


if __name__ == '__main__':
    unittest.main()
