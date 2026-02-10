import argparse
import json
import os
import sys


PLACEHOLDER_PREFIX = "VIDEO::"
PICTURE_TYPES = {11, 13, 14}
GROUP_TYPE = 6
FILL_PICTURE = 6


def truthy(value):
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def load_mapping(path):
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError("Mapping file must contain a list of video entries.")
    return data


def resolve_path(base_dir, path_value):
    if not path_value:
        return ""
    if os.path.isabs(path_value):
        return path_value
    return os.path.abspath(os.path.join(base_dir, path_value))


def collect_mapping(entries, base_dir):
    mapping = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        video_id = entry.get("id")
        if not video_id:
            continue
        mapping[video_id] = {
            "video": resolve_path(base_dir, entry.get("video", "")),
            "poster": resolve_path(base_dir, entry.get("poster", "")),
        }
    return mapping


def iter_shapes(slide):
    count = slide.Shapes.Count
    for index in range(count, 0, -1):
        yield slide.Shapes(index)


def is_picture(shape):
    try:
        return shape.Type in PICTURE_TYPES
    except Exception:
        return False


def is_group(shape):
    try:
        return shape.Type == GROUP_TYPE
    except Exception:
        return False


def has_text(shape):
    try:
        if shape.HasTextFrame and shape.TextFrame.HasText:
            return bool((shape.TextFrame.TextRange.Text or "").strip())
    except Exception:
        return False
    return False


def is_picture_fill(shape):
    try:
        return shape.Fill.Type == FILL_PICTURE
    except Exception:
        return False


def shape_bounds(shape):
    return (shape.Left, shape.Top, shape.Width, shape.Height)


def shape_alt_text(shape):
    try:
        return shape.AlternativeText or ""
    except Exception:
        return ""


def shape_text(shape):
    try:
        if shape.HasTextFrame and shape.TextFrame.HasText:
            return shape.TextFrame.TextRange.Text or ""
    except Exception:
        return ""
    return ""


def find_nearest_picture(slide, marker_shape):
    try:
        marker_cx = marker_shape.Left + (marker_shape.Width / 2)
        marker_cy = marker_shape.Top + (marker_shape.Height / 2)
    except Exception:
        return None

    candidates = []
    count = slide.Shapes.Count
    for index in range(1, count + 1):
        candidate = slide.Shapes(index)
        candidates.extend(picture_candidates(candidate))

    if not candidates:
        return None

    best = None
    best_dist = None
    for candidate in candidates:
        try:
            cx = candidate.Left + (candidate.Width / 2)
            cy = candidate.Top + (candidate.Height / 2)
        except Exception:
            continue
        dist = (cx - marker_cx) ** 2 + (cy - marker_cy) ** 2
        if best is None or dist < best_dist:
            best = candidate
            best_dist = dist
    return best


def horizontal_overlap_ratio(a_bounds, b_bounds):
    a_left, _, a_width, _ = a_bounds
    b_left, _, b_width, _ = b_bounds
    a_right = a_left + a_width
    b_right = b_left + b_width
    overlap = max(0.0, min(a_right, b_right) - max(a_left, b_left))
    denom = min(a_width, b_width)
    if denom <= 0:
        return 0.0
    return overlap / denom


def find_best_shape(slide, marker_shape, debug=None):
    marker_bounds = shape_bounds(marker_shape)
    marker_left, marker_top, marker_width, marker_height = marker_bounds
    marker_bottom = marker_top + marker_height

    best = None
    best_score = None

    count = slide.Shapes.Count
    for index in range(1, count + 1):
        candidate = slide.Shapes(index)
        if candidate is marker_shape:
            continue

        bounds = shape_bounds(candidate)
        left, top, width, height = bounds
        if width <= 0 or height <= 0:
            continue

        if has_text(candidate):
            continue

        overlap_ratio = horizontal_overlap_ratio(bounds, marker_bounds)
        above = (top + height) <= (marker_top + (marker_height * 0.5))
        if overlap_ratio < 0.25 and not above:
            continue

        area = width * height
        score = area * (1.0 + overlap_ratio)
        if above:
            score += area * 0.25
        if is_picture(candidate):
            score += area
        if is_picture_fill(candidate):
            score += area * 0.5

        if best is None or score > best_score:
            best = candidate
            best_score = score

    if best is not None and debug is not None:
        debug("best placeholder by heuristic found")

    return best


def picture_candidates(shape):
    if is_picture(shape):
        return [shape]

    if is_group(shape):
        candidates = []
        try:
            count = shape.GroupItems.Count
        except Exception:
            return candidates
        for index in range(1, count + 1):
            try:
                item = shape.GroupItems(index)
            except Exception:
                continue
            candidates.extend(picture_candidates(item))
        return candidates

    return []


def add_video(slide, video_path, bounds):
    left, top, width, height = bounds
    try:
        return slide.Shapes.AddMediaObject2(video_path, False, True, left, top, width, height)
    except Exception:
        return slide.Shapes.AddMovie(video_path, False, True, left, top, width, height)


def apply_bounds(shape, bounds):
    left, top, width, height = bounds
    try:
        shape.LockAspectRatio = 0
    except Exception:
        pass
    try:
        shape.Left = left
        shape.Top = top
        shape.Width = width
        shape.Height = height
    except Exception:
        pass


def apply_rotation(shape, rotation):
    try:
        shape.Rotation = rotation
    except Exception:
        pass


def main():
    parser = argparse.ArgumentParser(description="Embed videos into a PPTX using placeholders.")
    parser.add_argument("--input", required=True, help="Path to the PPTX to post-process.")
    parser.add_argument("--mapping", default="embed-video.json", help="Path to JSON mapping file.")
    parser.add_argument("--output", default="", help="Optional output PPTX path.")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging.")
    parser.add_argument("--keep-mapping", action="store_true", help="Do not delete mapping file.")
    args = parser.parse_args()

    debug_enabled = args.debug or truthy(os.getenv("EMBED_VIDEO_DEBUG", ""))

    def debug(msg):
        if debug_enabled:
            print(f"[embed-video] {msg}", file=sys.stderr)

    input_path = os.path.abspath(args.input)
    mapping_path = os.path.abspath(args.mapping)

    if not os.path.exists(input_path):
        raise FileNotFoundError(f"PPTX not found: {input_path}")
    if not os.path.exists(mapping_path):
        print(f"[embed-video] Mapping file not found: {mapping_path}")
        print("[embed-video] This likely means the Lua filter didn't find any embed-video blocks.")
        print("[embed-video] No videos to embed. Exiting gracefully.")
        return 0

    entries = load_mapping(mapping_path)
    mapping = collect_mapping(entries, os.path.dirname(mapping_path))
    if not mapping:
        print("No video placeholders found in mapping file.")
        return 0

    debug(f"mapping file: {mapping_path}")
    debug(f"mapping entries: {len(mapping)}")
    for key, value in mapping.items():
        debug(f"  id={key} video={value.get('video', '')} poster={value.get('poster', '')}")

    try:
        import win32com.client  # type: ignore
    except ImportError as exc:
        print("pywin32 is required to embed videos. Install it with: pip install pywin32")
        raise exc

    app = win32com.client.Dispatch("PowerPoint.Application")
    app.DisplayAlerts = 0
    presentation = None
    replaced = 0
    missing = []

    try:
        presentation = app.Presentations.Open(input_path, WithWindow=False, ReadOnly=False)
        debug(f"slides: {presentation.Slides.Count}")

        for slide in presentation.Slides:
            debug(f"slide {slide.SlideIndex}: shapes={slide.Shapes.Count}")
            for shape in iter_shapes(slide):
                alt_text = shape_alt_text(shape)
                text_value = shape_text(shape)
                marker = alt_text
                if not marker and PLACEHOLDER_PREFIX in text_value:
                    marker = text_value

                if not marker.startswith(PLACEHOLDER_PREFIX):
                    continue

                debug(
                    f"found placeholder shape on slide {slide.SlideIndex}: "
                    f"alt_text='{alt_text}' text='{text_value}'"
                )

                video_id = marker[len(PLACEHOLDER_PREFIX) :].strip()
                item = mapping.get(video_id)
                if not item:
                    missing.append(video_id)
                    debug(f"missing mapping for id={video_id}")
                    continue

                video_path = item.get("video", "")
                if not video_path or not os.path.exists(video_path):
                    missing.append(video_id)
                    debug(f"missing video file for id={video_id} path={video_path}")
                    continue

                target_shape = shape
                extra_delete = None
                if not is_picture(shape):
                    best = find_best_shape(slide, shape, debug=debug)
                    if best is None:
                        best = find_nearest_picture(slide, shape)
                    if best is not None:
                        target_shape = best
                        extra_delete = shape
                        debug("marker is text; using heuristic placeholder bounds")

                bounds = shape_bounds(target_shape)
                try:
                    rotation = target_shape.Rotation
                except Exception:
                    rotation = 0.0
                debug(
                    f"embedding id={video_id} video={video_path} "
                    f"bounds={bounds}"
                )

                target_shape.Delete()
                if extra_delete is not None:
                    extra_delete.Delete()

                new_shape = add_video(slide, video_path, bounds)
                apply_bounds(new_shape, bounds)
                apply_rotation(new_shape, rotation)
                try:
                    new_shape.AlternativeText = marker
                except Exception:
                    pass
                replaced += 1

        output_path = os.path.abspath(args.output) if args.output else input_path
        if output_path != input_path:
            presentation.SaveAs(output_path)
        else:
            presentation.Save()
    finally:
        if presentation is not None:
            presentation.Close()
        app.Quit()

    if not args.keep_mapping:
        try:
            os.remove(mapping_path)
            debug(f"deleted mapping file: {mapping_path}")
        except FileNotFoundError:
            pass
        except OSError as exc:
            debug(f"failed to delete mapping file: {exc}")

    if missing:
        unique_missing = sorted(set(missing))
        print("Warning: missing videos for placeholders:", ", ".join(unique_missing))

    print(f"Embedded {replaced} video(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
