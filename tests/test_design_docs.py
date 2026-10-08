"""Documentation integrity checks, not historical gameplay verification."""

from pathlib import Path
import re
import unittest
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
CHAPTERS = (
    'SYSTEM_DESIGN.md',
    'SPATIAL_RULES.md',
    'LIFECYCLE_AND_SCALE.md',
    'AUTHORING_WORKFLOW.md',
)
DIAGRAMS = ('spatial-slots-and-wall.svg', 'occupancy-granularity.svg')
DOCUMENTS = [ROOT / 'README.md', *sorted((ROOT / 'docs').glob('*.md')),
             ROOT / 'media/README.md']


def read(path):
    return path.read_text(encoding='utf-8')


def anchors(source):
    """Heading/explicit-id anchors used by this repository's Markdown."""
    source = re.sub(r'^```.*?^```[^\n]*', '', source, flags=re.M | re.S)
    result = set(re.findall(r'<a\s+id="([^"]+)"', source))
    seen = {}
    for heading in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', source, re.M):
        label = re.sub(r'!?\[([^\]]+)\]\([^)]+\)', r'\1', heading)
        label = re.sub(r'<[^>]+>', '', label)
        base = re.sub(r'[^\w\- ]', '', label.lower()).replace(' ', '-')
        index = seen.get(base, 0)
        result.add(base if index == 0 else f'{base}-{index}')
        seen[base] = index + 1
    return result


class DesignDocumentation(unittest.TestCase):
    def test_both_homepages_link_all_design_chapters(self):
        for path in (ROOT / 'README.md', ROOT / 'docs/README.zh-CN.md'):
            for chapter in CHAPTERS:
                with self.subTest(page=path.name, chapter=chapter):
                    self.assertIn(chapter, read(path))

    def test_homepage_preserves_three_gameplay_views(self):
        for path in (ROOT / 'README.md', ROOT / 'docs/README.zh-CN.md'):
            for image in ('Building_Catalogue.png', 'Equipment_Workbench.png',
                          'Storage_Box.png'):
                with self.subTest(page=path.name, image=image):
                    self.assertRegex(read(path), r'!\[[^\]]+\]\([^)]*' + re.escape(image) + r'\)')

    def test_markdown_destinations_and_fragments(self):
        for path in DOCUMENTS:
            for target in re.findall(r'\]\(([^)]+)\)', read(path)):
                parsed = urlsplit(target)
                if parsed.scheme or parsed.netloc:
                    continue
                destination = ((path.parent / unquote(parsed.path)).resolve()
                               if parsed.path else path)
                with self.subTest(page=path.name, target=target):
                    self.assertTrue(destination.is_relative_to(ROOT))
                    self.assertTrue(destination.is_file())
                    if parsed.fragment and destination.suffix == '.md':
                        self.assertIn(unquote(parsed.fragment), anchors(read(destination)))

    def test_svg_files_are_self_contained_accessible_diagrams(self):
        ns = '{http://www.w3.org/2000/svg}'
        for name in DIAGRAMS:
            path = ROOT / 'media/diagrams' / name
            with self.subTest(diagram=name):
                root = ET.fromstring(read(path))
                self.assertEqual(root.tag, ns + 'svg')
                self.assertIsNotNone(root.find(ns + 'title'))
                self.assertIsNotNone(root.find(ns + 'desc'))
                self.assertEqual(root.get('role'), 'img')
                self.assertEqual(len(root.get('viewBox').split()), 4)
                self.assertGreater(float(root.get('width')), 0)
                self.assertGreater(float(root.get('height')), 0)
                for element in root.iter():
                    self.assertNotIn(element.tag, {ns + 'script', ns + 'image',
                                                   ns + 'foreignObject'})
                    for attribute, value in element.attrib.items():
                        if attribute.endswith('href'):
                            self.assertTrue(value.startswith('#'))

    def test_historical_diagrams_are_linked_and_labelled(self):
        gallery = read(ROOT / 'media/README.md')
        spatial = read(ROOT / 'docs/SPATIAL_RULES.md')
        for diagram in DIAGRAMS:
            self.assertIn(diagram, gallery)
            self.assertIn(diagram, spatial)
        self.assertIn('Early implemented version, 2021', spatial)
        self.assertIn('not engine captures', spatial)
        self.assertIn('later free-form version', gallery)
        self.assertIn('## Historical system design', read(ROOT / 'docs/EVIDENCE.md'))

    def test_added_explanations_have_no_private_source_pointers(self):
        paths = [ROOT / 'docs' / name for name in CHAPTERS]
        paths += [ROOT / 'media/diagrams' / name for name in DIAGRAMS]
        forbidden = (r'(?i)\b[A-Z]:[\\/]|'
                     r'https://github\.com/[^/\s]+/(?:[\w-]+-)?story-library|'
                     r'(?:BLD|UI-[TB])-\d+|'
                     r'\b[0-9a-f]{40}\b')
        for path in paths:
            with self.subTest(path=path.name):
                self.assertNotRegex(read(path), forbidden)

    def test_gallery_has_only_public_stills_and_explanatory_svgs(self):
        files = [path for path in (ROOT / 'media').rglob('*') if path.is_file()]
        self.assertEqual(sum(path.suffix == '.png' for path in files), 5)
        self.assertEqual({path.name for path in files if path.suffix == '.svg'},
                         set(DIAGRAMS))
        self.assertFalse(any(path.suffix.lower() in {'.pptx', '.ppt', '.gif', '.mp4'}
                             for path in files))


if __name__ == '__main__':
    unittest.main()
