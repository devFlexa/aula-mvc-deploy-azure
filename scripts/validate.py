"""Validate the guide, links and downloadable source with the Python stdlib."""
from html.parser import HTMLParser
from pathlib import Path
from zipfile import ZipFile
import subprocess
import tempfile
import shutil

ROOT = Path(__file__).resolve().parents[1]


class Guide(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = []
        self.links = []
        self.blocks = []
        self.current = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.append(attrs['id'])
        for name in ('href', 'src'):
            if name in attrs:
                self.links.append(attrs[name])
        if tag == 'pre':
            self.current = [attrs.get('data-label', ''), '']

    def handle_data(self, data):
        if self.current is not None:
            self.current[1] += data

    def handle_endtag(self, tag):
        if tag == 'pre':
            self.blocks.append(self.current)
            self.current = None


def validate():
    parser = Guide()
    text = (ROOT / 'index.html').read_text(encoding='utf-8')
    parser.feed(text)
    assert '\ufffd' not in text, 'Invalid encoding'
    assert len(parser.ids) == len(set(parser.ids)), 'Duplicate IDs'
    for link in parser.links:
        if link.startswith('#'):
            assert link[1:] in parser.ids, f'Missing anchor: {link}'
        elif '://' not in link:
            assert (ROOT / link).is_file(), f'Missing file: {link}'
    for file in ('Dockerfile', 'compose.yaml', 'Program.cs'):
        blocks = [code for label, code in parser.blocks if label.endswith(file)]
        assert len(blocks) == 1, f'Missing or repeated source block: {file}'
        assert blocks[0].strip() == (ROOT / 'exemplo-mvc' / file).read_text(encoding='utf-8').strip(), f'Stale snippet: {file}'
    source = ROOT / 'exemplo-mvc'
    expected = {p.relative_to(source).as_posix(): p for p in source.rglob('*')
                if p.is_file() and not {'bin', 'obj', '.git'}.intersection(p.relative_to(source).parts)}
    assert '.env' not in expected, 'Do not publish environment files'
    with ZipFile(ROOT / 'downloads/exemplo-mvc.zip') as bundle:
        assert set(bundle.namelist()) == set(expected), 'ZIP contents differ from source'
        for name, path in expected.items():
            actual = bundle.read(name).decode('utf-8').replace('\r\n', '\n')
            assert actual == path.read_text(encoding='utf-8'), f'ZIP file differs: {name}'
    if shutil.which('bash'):
        for label, code in parser.blocks:
            if label.startswith('Bash'):
                subprocess.run(['bash', '-n'], input=code, text=True, check=True)
    print(f'PASS: {len(parser.ids)} anchors, {len(parser.blocks)} code blocks, source parity and ZIP.')
    return parser


if __name__ == '__main__':
    validate()
