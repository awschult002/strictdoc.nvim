Fixtures are copied unchanged from
[strictdoc-project/strictdoc](https://github.com/strictdoc-project/strictdoc)
at commit `b1cff12` (Apache-2.0):

| file | upstream path |
| --- | --- |
| `anchors.sdoc` | `tests/integration/features/sdoc/markup/02_referencing_anchor_with_LINK_internal/input.sdoc` |
| `from_file.sdoc` | `tests/integration/features/document_fragments/05_nested_fragments_relations/input.sdoc` |
| `legacy_sections.sdoc` | `tests/integration/features/deprecations/composite_node_migration/00_migration_warning_shown_when_no_project_config_option/input.sdoc` |
| `metadata.sdoc` | `tests/end2end/screens/table/view_table_edit/edit_table_document_custom_meta_add/expected_output/document.sdoc` |
| `nested_composite.sdoc` | `tests/end2end/screens/document/create_requirement/create_three_nested_requirements/expected_output/document.sdoc` |
| `relations.sdoc` | `tests/integration/features/document_fragments/05_nested_fragments_relations/subnested.sdoc` |
| `views.sdoc` | `tests/integration/features/views/01_view_references_default_grammar_field/input.sdoc` |
| `user_guide.sdoc` | `docs/strictdoc_01_user_guide.sdoc` |

`scrambled/` holds the same files with random leading whitespace on every
line outside `>>>`/`<<<` blocks. `expected/` is what `gg=G` must produce
from them with the default settings. With `g:strictdoc_indent = 0`, `gg=G`
on `scrambled/` must give back the upstream files byte for byte.
