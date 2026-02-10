import zipfile
import shutil
import sys
import json
import hashlib
from pathlib import Path
from lxml import etree

PML = "http://schemas.openxmlformats.org/presentationml/2006/main"
A = "http://schemas.openxmlformats.org/drawingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

NS = {"p": PML, "a": A, "r": R}

META_FILE = "embed-video.json"


def log(msg):
    print(f"[embed-video] {msg}")


def hash_file(path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        h.update(f.read())
    return h.hexdigest()


def hash_bytes(data: bytes) -> str:
    """Compute SHA-256 hash of bytes."""
    return hashlib.sha256(data).hexdigest()


def embed_video(pptx: Path, project_root: Path):
    log(f"Opening PPTX: {pptx}")
    tmp = pptx.with_suffix(".tmp")
    shutil.copy(pptx, tmp)
    log(f"Working copy created: {tmp.name}")

    # Read the PPTX into memory, modify files, then rebuild to avoid duplicate entries
    RELS_PKG = "http://schemas.openxmlformats.org/package/2006/relationships"

    with zipfile.ZipFile(tmp, "r") as z:
        names = z.namelist()
        log(f"Checking for metadata file: {META_FILE} in {names}")
        original = {name: z.read(name) for name in names}

    if META_FILE in original:
        meta = json.loads(original[META_FILE])
    else:
        local_meta = project_root / META_FILE
        if local_meta.exists():
            log(f"Found external metadata file at: {local_meta}")
            meta = json.loads(local_meta.read_text())
        else:
            log("No embed-video metadata found, nothing to do")
            return

    log(f"Loaded metadata for {len(meta)} video(s)")

    # Build a mapping of image hashes to video paths
    # This works because the image content is the same even if Quarto renames it in the PPTX
    log("Building image hash mapping from metadata...")
    hash_to_video = {}
    for img_path_str, video_path_str in meta.items():
        img_path = project_root / img_path_str
        video_path = project_root / video_path_str
        if img_path.exists():
            h = hash_file(img_path)
            hash_to_video[h] = (img_path.name, str(video_path))
            log(f"  {img_path.name} → {video_path.name} (hash: {h[:8]}...)")
        else:
            log(f"  WARNING: Image not found: {img_path}")

    if not hash_to_video:
        log("No valid image-video mappings found, nothing to do")
        return

    slide_files = sorted([f for f in original.keys() if f.startswith("ppt/slides/slide") and f.endswith('.xml')])
    log(f"Found {len(slide_files)} slide(s)")

    for slide in slide_files:
        log(f"Processing {slide}")
        slide_xml = etree.fromstring(original[slide])

        rels_path = slide.replace("slides/", "slides/_rels/") + ".rels"
        rels_xml = etree.fromstring(original[rels_path])

        for pic in slide_xml.xpath(".//p:pic", namespaces=NS):
            blip = pic.xpath(".//a:blip", namespaces=NS)
            if not blip:
                continue

            rid = blip[0].get(f"{{{R}}}embed")
            rel = rels_xml.xpath(
                f"//rel:Relationship[@Id='{rid}']",
                namespaces={"rel": R},
            )
            if not rel:
                continue

            img_pptx_target = rel[0].get("Target")
            img_pptx_path = f"ppt/{img_pptx_target}"
            img_data = original.get(img_pptx_path)

            if not img_data:
                log(f"  Skipping image (not found in PPTX): {img_pptx_target}")
                continue

            # Compute hash of the image in the PPTX and look it up
            img_hash = hash_bytes(img_data)
            if img_hash not in hash_to_video:
                log(f"  Image {Path(img_pptx_target).name} (hash: {img_hash[:8]}...) → not in mapping")
                continue

            orig_name, video_path_str = hash_to_video[img_hash]
            video_path = Path(video_path_str)
            log(f"  Found image: {orig_name} in PPTX as {Path(img_pptx_target).name}")
            log(f"    → matched by content hash, mapped to video: {video_path}")

            if not video_path.exists():
                raise FileNotFoundError(f"Video file not found: {video_path}")

            video_name = video_path.name
            video_rid = f"rVideo{len(rels_xml) + 1}"

            log(f"    → embedding video as {video_name}")
            log(f"    → new relationship id: {video_rid}")

            # Add relationship using package relationships namespace
            rel_el = etree.Element(f"{{{RELS_PKG}}}Relationship")
            rel_el.set("Id", video_rid)
            rel_el.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/video")
            rel_el.set("Target", f"../media/{video_name}")
            rels_xml.append(rel_el)

            # Copy media into the archive entries in memory
            original[f"ppt/media/{video_name}"] = video_path.read_bytes()
            log(f"    → copied to ppt/media/{video_name}")

            # Replace picture with video
            video = etree.Element(f"{{{PML}}}video")
            video.attrib[f"{{{R}}}embed"] = video_rid
            pic.getparent().replace(pic, video)
            log("    → replaced picture with video element")

        # Update in-memory content
        original[slide] = etree.tostring(slide_xml)
        original[rels_path] = etree.tostring(rels_xml)
        log(f"Finished {slide}")

    # Write a new PPTX archive from the modified in-memory contents
    tmp2 = pptx.with_suffix(".tmp2")
    with zipfile.ZipFile(tmp2, "w", compression=zipfile.ZIP_DEFLATED) as out:
        for name, data in original.items():
            out.writestr(name, data)

    try:
        tmp.unlink()
    except Exception:
        pass

    shutil.move(tmp2, pptx)
    log(f"Updated PPTX written: {pptx}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python embed_video.py <slides.pptx> <project_root>")
        sys.exit(1)

    pptx = Path(sys.argv[1])
    root = Path(sys.argv[2])

    embed_video(pptx, root)