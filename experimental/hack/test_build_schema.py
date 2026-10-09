#!/usr/bin/env python3
"""Unit tests for the build_schema transform functions.

Run: python3 hack/test_build_schema.py  (stdlib unittest, no deps).
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_schema as bs  # noqa: E402


class WalkTest(unittest.TestCase):
    def test_visits_every_node_post_order(self):
        seen = []

        def record(n):
            seen.append(n if not isinstance(n, (dict, list)) else type(n).__name__)
            return n

        bs.walk({"a": [1, 2], "b": "x"}, record)
        # leaves recorded before their containers (post-order)
        self.assertEqual(seen, [1, 2, "list", "x", "dict"])

    def test_function_can_mutate_and_replace(self):
        out = bs.walk({"keep": 1}, lambda n: ({"added": True} if isinstance(n, dict) else n))
        self.assertEqual(out, {"added": True})


class StripRequiredTest(unittest.TestCase):
    def test_removes_required_key_only(self):
        self.assertEqual(bs.strip_required({"required": ["a"], "type": "object"}), {"type": "object"})

    def test_non_dict_untouched(self):
        self.assertEqual(bs.strip_required("required"), "required")


class AdditionalPropsTest(unittest.TestCase):
    def test_added_when_properties_present_and_absent(self):
        self.assertEqual(
            bs.add_additional_props_false({"properties": {}}),
            {"properties": {}, "additionalProperties": False},
        )

    def test_not_overwritten_when_already_set(self):
        self.assertEqual(
            bs.add_additional_props_false({"properties": {}, "additionalProperties": True}),
            {"properties": {}, "additionalProperties": True},
        )

    def test_skipped_without_properties(self):
        self.assertEqual(bs.add_additional_props_false({"type": "string"}), {"type": "string"})


class PatchDirectiveTest(unittest.TestCase):
    def test_appends_patch_entry_to_properties(self):
        out = bs.add_patch_directive({"properties": {"name": {"type": "string"}}})
        self.assertEqual(list(out["properties"]), ["name", "$patch"])
        self.assertEqual(out["properties"]["$patch"], {"type": "string", "enum": ["replace"]})


class NullableTest(unittest.TestCase):
    def test_string_becomes_pair(self):
        self.assertEqual(bs.make_nullable({"type": "string"}), {"type": ["string", "null"]})

    def test_list_gets_null_appended(self):
        self.assertEqual(bs.make_nullable({"type": ["object"]}), {"type": ["object", "null"]})

    def test_already_nullable_untouched(self):
        self.assertEqual(bs.make_nullable({"type": ["string", "null"]}), {"type": ["string", "null"]})
        self.assertEqual(bs.make_nullable({"type": "null"}), {"type": "null"})


class RewriteRefTest(unittest.TestCase):
    def test_rewrites_components_to_definitions(self):
        self.assertEqual(
            bs.rewrite_ref({"$ref": "#/components/schemas/io.k8s.X"}),
            {"$ref": "#/definitions/io.k8s.X"},
        )


class TraefikOpenTest(unittest.TestCase):
    def test_opens_object_nodes(self):
        self.assertEqual(
            bs.traefik_open({"type": "object"}),
            {"type": "object", "additionalProperties": True},
        )
        self.assertEqual(
            bs.traefik_open({"type": ["object", "null"]}),
            {"type": ["object", "null"], "additionalProperties": True},
        )

    def test_leaves_scalars(self):
        self.assertEqual(bs.traefik_open({"type": "string"}), {"type": "string"})


class TransformPipelineTest(unittest.TestCase):
    """The five definition walks, in order, produce the documented shape."""

    def test_end_to_end_on_a_small_definition(self):
        node = {
            "properties": {"name": {"type": "string"}},
            "required": ["name"],
            "type": "object",
            "$ref-holder": {"$ref": "#/components/schemas/Foo"},
        }
        for fn in (
            bs.strip_required,
            bs.add_additional_props_false,
            bs.add_patch_directive,
            bs.make_nullable,
            bs.rewrite_ref,
        ):
            node = bs.walk(node, fn)
        self.assertNotIn("required", node)
        self.assertEqual(node["additionalProperties"], False)
        self.assertEqual(node["type"], ["object", "null"])
        self.assertEqual(node["properties"]["name"]["type"], ["string", "null"])
        # $patch added by walk 3, then made nullable by walk 4
        self.assertEqual(node["properties"]["$patch"], {"type": ["string", "null"], "enum": ["replace"]})
        self.assertEqual(node["$ref-holder"]["$ref"], "#/definitions/Foo")


if __name__ == "__main__":
    unittest.main(verbosity=2)
