"""Validate the distributed layout, not just the development checkout."""
import json
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from tools.package import build


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = build(Path(self.temp.name) / 'tanker.zip')

    def test_archive_layout_is_standalone(self):
        with ZipFile(self.output) as archive:
            names = set(archive.namelist())
            for name in ('scripts/tanker/modScript.lua', 'lua/ge/extensions/tanker/core.lua',
                         'lua/ge/extensions/tanker/wrist.lua', 'ui/modules/apps/Tanker/app.json',
                         'ui/modules/apps/Tanker/app.js', 'ui/modules/apps/Tanker/app.html',
                         'ui/modules/apps/Tanker/app.png', 'README.md', 'CHANGELOG.md', 'docs/DESIGN.md', 'config.example.json'):
                self.assertIn(name, names)
            self.assertFalse(any(n.startswith(('settings/', 'tests/', 'tools/', 'tanker/')) for n in names))
            self.assertFalse(any(n.endswith(('.pyc', 'save-a.json', 'save-b.json')) for n in names))
            self.assertIsNone(archive.testzip())

    def test_manifest_and_wiring_agree(self):
        prefix = 'ui/modules/apps/Tanker/'
        with ZipFile(self.output) as archive:
            manifest = json.loads(archive.read(prefix + 'app.json'))
            config = json.loads(archive.read('config.example.json'))
            self.assertEqual(manifest['appName'], 'Tanker')
            self.assertEqual(manifest['directive'], 'tankerHud')
            self.assertIn('tanker-hud', manifest['domElement'])
            self.assertIn(b"'tankerHud'", archive.read(prefix + 'app.js'))
            self.assertIn(b'/ui/modules/apps/Tanker/app.html', archive.read(prefix + 'app.js'))
            self.assertIn(b'tanker_core', archive.read('scripts/tanker/modScript.lua'))
            self.assertIn('start', config)
            self.assertTrue(archive.read(prefix + 'app.png').startswith(b'\x89PNG'))

    def test_build_is_deterministic(self):
        again = build(Path(self.temp.name) / 'again.zip')
        self.assertEqual(self.output.read_bytes(), again.read_bytes())


if __name__ == '__main__':
    unittest.main()
