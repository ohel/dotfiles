#!/usr/bin/env python3
# Parse RSS feed items with timestamp, link and title from given URL. Output HTML table rows.

from email.utils import parsedate_to_datetime
import gzip
import io
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

def strip_namespace(tree):
    """Remove namespaces in the parsed XML tree for easier tag access."""
    for elem in tree.iter():
        if '}' in elem.tag:
            elem.tag = elem.tag.split('}', 1)[1]
    return tree

def format_date(date_str):
    """Convert RFC822/Atom dates to 'YYYY-MM-DD HH:MM:SS' if possible."""
    if not date_str:
        return ""
    try:
        dt = parsedate_to_datetime(date_str)
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        pass

    parsed = re.sub(r'T', ' ', date_str)
    parsed = re.sub(r'[\+\-][0-9][0-9]:[0-9][0-9]$', '', parsed)
    return parsed.strip()

def fetch_url(url):
    """Fetch URL and transparently handle gzip encoding."""
    req = urllib.request.Request(url, headers={"User-Agent": "rss-parser", "Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req) as resp:
        data = resp.read()
        if resp.info().get("Content-Encoding") == "gzip":
            with gzip.GzipFile(fileobj=io.BytesIO(data)) as f:
                data = f.read()
        return data

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <url> [N]", file=sys.stderr)
        sys.exit(1)

    url = sys.argv[1]
    try:
        N = int(sys.argv[2])
    except IndexError:
        N = 5
    except ValueError:
        print("N must be an integer", file=sys.stderr)
        sys.exit(1)

    data = fetch_url(url)

    root = ET.fromstring(data)
    root = strip_namespace(root)

    channel = root.find("channel")
    if channel is None:
        # Atom feed
        channel_title = root.findtext("title", default="(no title)").strip()
        items = root.findall("entry")
        title_tag, link_tag, date_tag = "title", "link", "updated"
    else:
        # RSS feed
        channel_title = channel.findtext("title", default="(no title)").strip()
        items = channel.findall("item")
        title_tag, link_tag, date_tag = "title", "link", "pubDate"

    print(f'<tr><td colspan="2"><h2>{channel_title}</h2></td></tr>')

    for item in items[:N]:
        title = item.findtext(title_tag, default="(no title)").strip()
        link_elem = item.find(link_tag)
        if link_elem is not None:
            if link_elem.text:
                link = link_elem.text.strip()
            else:
                link = link_elem.attrib.get("href", "#")
        else:
            link = "#"

        date_raw = item.findtext(date_tag, default="")
        date = format_date(date_raw)

        print(f'<tr><td>{date}</td><td><a href="{link}">{title}</a></td></tr>')

if __name__ == "__main__":
    main()
