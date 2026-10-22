"""Validate original decoration geometry and its standalone Blender/FBX delivery.

Run after exporting geometry.json. This does not open Blender, Studio, a place or
any script from the reference maps. Vertices use Roblox local studs (Y up), and
triangle indices are one based. No physics/manifold assumption is made for leaves.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import sys


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def vector(value: object, where: str) -> list[float]:
    require(isinstance(value, list) and len(value) == 3, f"{where}: expected three numbers")
    require(all(number(component) for component in value), f"{where}: non-finite/non-numeric value")
    require(all(abs(component) <= 10000 for component in value), f"{where}: unreasonable local extent")
    return value


def bounds(vertices: list[list[float]]) -> dict[str, list[float]]:
    minimum = [min(v[axis] for v in vertices) for axis in range(3)]
    maximum = [max(v[axis] for v in vertices) for axis in range(3)]
    return {"Min": minimum, "Max": maximum, "Size": [b-a for a, b in zip(minimum, maximum)]}


def triangle_area_squared(a: list[float], b: list[float], c: list[float]) -> float:
    u = [b[i]-a[i] for i in range(3)]
    v = [c[i]-a[i] for i in range(3)]
    cross = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
    return sum(component*component for component in cross)


def artifact(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    return {"Path": path.as_posix(), "Bytes": len(data), "SHA256": hashlib.sha256(data).hexdigest()}


def verify(args: argparse.Namespace) -> dict[str, object]:
    source = args.geometry.resolve()
    require(source.is_file(), f"Geometry does not exist: {source}")
    data = json.loads(source.read_text(encoding="utf-8-sig"))
    require(isinstance(data, dict), "Geometry root must be an object")
    require(isinstance(data.get("Revision"), str) and data["Revision"].strip(), "Revision is missing")
    models = data.get("Models")
    require(isinstance(models, list) and models, "Models must be a nonempty array")
    ids: set[str] = set()
    records = []
    fbx_records = []
    total_vertices = total_triangles = total_parts = 0
    for mi, model in enumerate(models):
        where = f"Models[{mi}]"
        require(isinstance(model, dict), f"{where}: expected object")
        for field in ("Id", "Name", "Biome", "Category"):
            require(isinstance(model.get(field), str) and model[field].strip(), f"{where}.{field}: missing string")
        identifier = model["Id"]
        require(re.fullmatch(r"[A-Za-z0-9_-]+", identifier) is not None, f"{where}.Id: unsafe filename")
        require(identifier not in ids, f"Duplicate model Id: {identifier}")
        ids.add(identifier)
        parts = model.get("Parts")
        require(isinstance(parts, list) and parts, f"{identifier}: missing Parts")
        require(len(parts) <= args.max_parts, f"{identifier}: exceeds {args.max_parts} parts")
        model_vertices = []
        triangle_count = 0
        for pi, part in enumerate(parts):
            label = f"{identifier}.Parts[{pi}]"
            require(isinstance(part, dict), f"{label}: expected object")
            require(isinstance(part.get("Name"), str) and part["Name"].strip(), f"{label}: missing Name")
            vertices = part.get("Vertices")
            triangles = part.get("Triangles")
            require(isinstance(vertices, list) and len(vertices) >= 3, f"{label}: fewer than three vertices")
            require(isinstance(triangles, list) and triangles, f"{label}: no triangles")
            for vi, point in enumerate(vertices):
                vector(point, f"{label}.Vertices[{vi}]")
            color = vector(part.get("Color"), f"{label}.Color")
            require(all(0 <= component <= 1 for component in color), f"{label}: Color outside 0..1")
            require(type(part.get("Glow")) is bool, f"{label}: Glow must be boolean")
            require(type(part.get("Collision")) is bool, f"{label}: Collision must be boolean")
            seen = set()
            for ti, triangle in enumerate(triangles):
                tl = f"{label}.Triangles[{ti}]"
                require(isinstance(triangle, list) and len(triangle) == 3, f"{tl}: expected three indices")
                require(all(type(index) is int and 1 <= index <= len(vertices) for index in triangle), f"{tl}: invalid one-based index")
                require(len(set(triangle)) == 3, f"{tl}: repeated index")
                key = tuple(sorted(triangle))
                require(key not in seen, f"{tl}: duplicate/coincident triangle")
                seen.add(key)
                a, b, c = [vertices[index-1] for index in triangle]
                require(triangle_area_squared(a, b, c) > 1e-16, f"{tl}: degenerate triangle")
            model_vertices.extend(vertices)
            triangle_count += len(triangles)
        box = bounds(model_vertices)
        require(abs(box["Min"][1]) <= args.ground_tolerance, f"{identifier}: lowest vertex Y={box['Min'][1]:.6g}; pivot must sit on ground")
        require(box["Size"][1] > 0.05, f"{identifier}: model has no usable height")
        require(triangle_count <= args.max_triangles, f"{identifier}: exceeds {args.max_triangles} triangles")
        records.append({"Id": identifier, "Name": model["Name"], "Parts": len(parts),
                        "Vertices": len(model_vertices), "Triangles": triangle_count, "Bounds": box})
        total_vertices += len(model_vertices)
        total_triangles += triangle_count
        total_parts += len(parts)
        if not args.skip_artifacts:
            search_dirs = [args.fbx_dir.resolve()] if args.fbx_dir else [source.parent, source.parent/"Exportacoes", source.parent/"FBX", source.parent/"exports"]
            candidates = [directory/f"{identifier}.fbx" for directory in search_dirs]
            existing = [path for path in candidates if path.is_file()]
            require(existing, f"{identifier}: FBX missing; expected Id.fbx in {search_dirs}")
            fbx = existing[0]
            raw = fbx.read_bytes()
            require(len(raw) > 100, f"{identifier}: FBX empty or truncated")
            require(raw.startswith(b"Kaydara FBX Binary") or b"FBX" in raw[:100], f"{identifier}: not an FBX header")
            fbx_records.append(artifact(fbx))
    blend_records = []
    if not args.skip_artifacts:
        blends = [args.blend.resolve()] if args.blend else list(source.parent.glob("*.blend"))
        require(blends, "Blender creation file is missing")
        for blend in blends:
            require(blend.is_file(), f"Blend missing: {blend}")
            raw = blend.read_bytes()
            require(len(raw) > 1000, f"Blend empty or truncated: {blend}")
            # Blender can save uncompressed, gzip or Zstandard files.
            require(raw.startswith((b"BLENDER", b"\x1f\x8b", b"\x28\xb5\x2f\xfd")), f"Unrecognized Blender file header: {blend}")
            blend_records.append(artifact(blend))
    return {"Revision": data["Revision"], "Geometry": artifact(source), "Models": records,
            "Totals": {"Models": len(models), "Parts": total_parts, "Vertices": total_vertices, "Triangles": total_triangles},
            "FBX": fbx_records, "Blender": blend_records, "ArtifactsChecked": not args.skip_artifacts,
            "GroundToleranceStuds": args.ground_tolerance,
            "Limits": {"PartsPerModel": args.max_parts, "TrianglesPerModel": args.max_triangles},
            "Limitations": ["No Studio/Blender execution, rendering, client replication or runtime performance test.",
                            "Artifact headers/hashes do not prove that Blender/Studio can import them.",
                            "Reference-map ownership/licensing is not inferred from local filenames."]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("geometry", nargs="?", type=Path, default=Path(__file__).with_name("geometry.json"))
    parser.add_argument("--fbx-dir", type=Path)
    parser.add_argument("--blend", type=Path)
    parser.add_argument("--max-parts", type=int, default=64)
    parser.add_argument("--max-triangles", type=int, default=10000)
    parser.add_argument("--ground-tolerance", type=float, default=0.05)
    parser.add_argument("--skip-artifacts", action="store_true", help="Validate geometry before FBX/BLEND export")
    parser.add_argument("--report", type=Path, help="Write JSON only to this explicit report path")
    args = parser.parse_args()
    try:
        require(args.max_parts > 0 and args.max_triangles > 0, "Budgets must be positive")
        require(math.isfinite(args.ground_tolerance) and args.ground_tolerance >= 0, "Invalid ground tolerance")
        result = verify(args)
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(f"Decoration validation failed: {error}", file=sys.stderr)
        return 1
    encoded = json.dumps(result, ensure_ascii=False, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(encoded+"\n", encoding="utf-8")
    print(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
