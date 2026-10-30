"""The build must not report a successful but incomplete Shortcut package."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
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


class StorageBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.build = self.root / 'new' / 'derived'

    @staticmethod
    def capacity(gib):
        return SimpleNamespace(total=512 * 1024 ** 3, free=int(gib * 1024 ** 3))

    def test_low_space_never_creates_derived_data_or_invokes_xcode(self):
        sentinel = self.root / 'keep.xcresult'
        sentinel.write_bytes(b'owned evidence remains intact')
        with patch.object(builds.shutil, 'disk_usage', return_value=self.capacity(15.99)), \
                patch.object(builds.subprocess, 'run') as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        run.assert_not_called()
        self.assertFalse(self.build.parent.exists())
        self.assertEqual(row['failure_code'], 'BUILD_STORAGE_LOW')
        self.assertFalse(row['attempts'][0]['executed'])
        self.assertEqual(sentinel.read_bytes(), b'owned evidence remains intact')

    def test_exact_reserve_is_sufficient_and_records_both_observations(self):
        with patch.object(builds.shutil, 'disk_usage', return_value=self.capacity(16)), \
                patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[1])
        self.assertEqual(row['exit_code'], 0)
        self.assertTrue(row['storage_headroom_ok'])
        self.assertEqual(run.call_count, 1)
        for key in ('storage_before', 'storage_after'):
            self.assertEqual(row['attempts'][0][key]['free_bytes'], 16 * 1024 ** 3)

    def test_unreadable_capacity_fails_closed_before_xcode(self):
        with patch.object(builds.shutil, 'disk_usage', side_effect=PermissionError), \
                patch.object(builds.subprocess, 'run') as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[1])
        run.assert_not_called()
        self.assertEqual(row['failure_code'], 'BUILD_STORAGE_UNAVAILABLE')
        self.assertFalse(self.build.exists())

    def test_destination_symlink_measures_the_resolved_target(self):
        target = self.root / 'real'
        target.mkdir()
        link = self.root / 'link'
        link.symlink_to(target, target_is_directory=True)
        with patch.object(builds.shutil, 'disk_usage', return_value=self.capacity(64)) as usage:
            result = builds.storage_preflight(link / 'not-created')
        usage.assert_called_once_with(target.resolve())
        self.assertEqual(result['destination'], str(target / 'not-created'))

    def test_absent_external_volume_is_not_created_on_the_boot_disk(self):
        with patch.object(Path, 'is_mount', return_value=False), \
                patch.object(builds.shutil, 'disk_usage') as usage, \
                patch.object(builds.subprocess, 'run') as run:
            row = builds.build_platform(self.root, Path('/Volumes/HomeViewMissingFixture/derived'), builds.CONFIGS[1])
        run.assert_not_called()
        usage.assert_not_called()
        self.assertEqual(row['attempts'][0]['storage_before']['error'], 'VolumeNotMounted')

    def test_recovery_clean_is_not_launched_after_headroom_is_lost(self):
        capacities = [self.capacity(64), self.capacity(15), self.capacity(15)]
        with patch.object(builds.shutil, 'disk_usage', side_effect=capacities), \
                patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            row = builds.build_platform(self.root, self.build, builds.CONFIGS[0])
        self.assertEqual(run.call_count, 1)
        self.assertFalse(row['attempts'][0]['shortcut_artifacts']['valid'])
        self.assertEqual(row['failure_code'], 'BUILD_STORAGE_LOW')
        self.assertFalse(row['attempts'][1]['executed'])
        self.assertTrue(row['attempts'][1]['clean_metadata_recovery'])

    def test_main_stops_before_the_next_sdk_when_a_build_consumes_the_reserve(self):
        with patch.object(builds, '__file__', str(self.root / 'Scripts/build_platforms.py')), \
                patch.dict(builds.os.environ, {'HOMEVIEW_BUILD_DIR': str(self.build), 'HOMEVIEW_MIN_FREE_GIB': '16'}), \
                patch.object(builds, 'CONFIGS', builds.CONFIGS[1:3]), \
                patch.object(builds.shutil, 'disk_usage', side_effect=[self.capacity(64), self.capacity(15)]), \
                patch.object(builds.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run, \
                patch('builtins.print'):
            exit_code = builds.main()
        self.assertEqual(exit_code, 1)
        self.assertEqual(run.call_count, 1)
        rows = json.loads((self.root / 'Evidence/builds.json').read_text())
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['exit_code'], 0)  # Compiler success is not relabelled.
        self.assertFalse(rows[0]['storage_headroom_ok'])

    def test_invalid_reserves_cannot_disable_the_guard(self):
        for value in ('0', '-1', 'NaN', 'Infinity', '-Infinity', 'typo', '0.00000000001'):
            with self.subTest(value=value), patch.dict(builds.os.environ, {'HOMEVIEW_MIN_FREE_GIB': value}):
                with self.assertRaises(ValueError):
                    builds.configured_min_free_bytes()
        with patch.dict(builds.os.environ, {'HOMEVIEW_MIN_FREE_GIB': '20.5'}):
            self.assertEqual(builds.configured_min_free_bytes(), int(20.5 * 1024 ** 3))

    def test_reusing_compiler_cache_does_not_overwrite_previous_build_logs(self):
        def write_log(command, **kwargs):
            kwargs['stdout'].write('attempt marker\n')
            return subprocess.CompletedProcess(command, 0)
        with patch.object(builds.shutil, 'disk_usage', return_value=self.capacity(64)), \
                patch.object(builds.subprocess, 'run', side_effect=write_log):
            first = builds.build_platform(self.root, self.build, builds.CONFIGS[1])
            original = Path(first['log']).read_bytes()
            second = builds.build_platform(self.root, self.build, builds.CONFIGS[1])
        self.assertNotEqual(first['log'], second['log'])
        self.assertEqual(Path(first['log']).read_bytes(), original)
        self.assertEqual(first['command'][first['command'].index('-derivedDataPath') + 1],
                         second['command'][second['command'].index('-derivedDataPath') + 1])


if __name__ == '__main__':
    unittest.main()
