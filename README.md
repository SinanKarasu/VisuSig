# VisuSig

VisuSig is a payload-oriented visual workbench. A visual node carries durable,
serializable domain content; a live host object is an optional adapter, not the
meaning of the node.

The first payload workspace is an ATLAS authoring experiment:

| Statement # | Apply statement | Resource | Target |
| --- | --- | --- | --- |
| 100 | `APPLY, DC SIGNAL, VOLTAGE 5 V` | `DC-SUPPLY-3` | `HI R10-HI` |

The table is the authoring form. VisuSig derives two projections from it:

1. numbered ATLAS source;
2. a read-only execution-order graph.

The existing Apple Audio Unit host remains available as a second workspace. It
now uses the same payload boundary instead of defining the graph model.

## Hierarchical VisualMesh

The authoritative VisualMesh package is <https://github.com/SinanKarasu/VisualMesh>, consumed from its `main`
branch by VisuSig and AtlasConcept. VisuSig has no graph model of its own: the
Payload, Hierarchy, and Audio Units panels all use the package, and the 2D
editor is the package's `VisualMeshUI.MeshCanvas`. To edit the package
alongside VisuSig, drag a local clone into the Xcode workspace; Xcode then
uses it in place of the GitHub copy.

The Hierarchy workspace adds reusable subgraph definitions without putting a
second `Mesh` inside a node payload. A definition owns its internal graph,
declared interface ports, and boundary-to-interior net mappings. An instance is
a lightweight graph node with its own designator and port identities that
references the definition.

The working example reconstructs `RESSIP9` from the historical WITS `tc3.sf`:
the nine resistors are stored once, while U100 and U101 are independently
wired instances. Expanding either box renders the shared definition and the
original `CONNECT:` boundary map. Additional instances can be created from the
definition library and combined through their boundary ports.

This mirrors the useful distinctions in WITS PACKs, TEDL device models and
configured devices, and IEEE 1671 description/instance documents with ATML
interfaces and network lists. See [Docs/HIERARCHY.md](Docs/HIERARCHY.md) for
the complete mapping and invariants.

## Why this boundary matters

The old model stored an `AUManagedUnit` directly in every node. That made an
Apple runtime object the graph's content model and pulled AVFoundation into the
otherwise reusable visual layer.

The revised model separates three concerns:

```text
Authoring form                       Durable visual model
ATLAS statement rows  ----------->  Payload -> NodeBase -> Mesh
         |                                      |
         +----> ATLAS text                      +----> graph projection

Optional runtime adapter
Payload ID -> PayloadRuntimeStore -> AUManagedUnit -> AudioGraph/AVAudioEngine
```

- `Payload` is Codable and consists of an open kind, a title, and textual
  fields. New domains do not require another case in VisualMesh.
- `NodeBase` stores `Payload?` and has no AVFoundation dependency.
- `PayloadRuntimeStore` holds ephemeral, framework-specific host objects by
  payload identity. Runtime objects are never serialized.
- `AudioGraph` asks its `Mesh` for an `AUManagedUnit` only at the audio adapter
  boundary.

This keeps VisuSig usable for ATLAS, a future Resource Manager inspection
surface, and other payloads without pretending they are audio plugins.

## ATLAS first cut

`AtlasStatementRow` deliberately preserves the four proposed columns. The
emitter validates statement numbers, the `APPLY` verb, required resources and
targets, duplicate numbers, and produces source such as:

```atlas
 000001 BEGIN, ATLAS PROGRAM 'VISUSIG-PAYLOAD' $
 000010 COMMENCE, MAIN PROCEDURE $
 000100 APPLY, DC SIGNAL USING 'DC-SUPPLY-3', VOLTAGE 5 V, CNX HI R10-HI $
 999999 TERMINATE, ATLAS PROGRAM 'VISUSIG-PAYLOAD' $
```

This emitter is a proof of the authoring transformation, not a second ATLAS
compiler. It supports this narrow `APPLY` row shape. Grammar parsing, semantic
lowering to `TestIR`, resource matching, routing, and execution belong in
AtlasConcept and TPS WorkShop.

In particular, the graph shown beside the table is a projection. Moving or
editing its nodes must not silently create a second program representation.

## Audio Unit workspace

The original experiment remains intact as an adapter example:

- browse installed Audio Unit effects;
- connect typed source, effect, and output nodes;
- rebuild an `AVAudioEngine` route when wiring changes;
- open native plugin interfaces;
- load and loop common audio file formats.

Audio nodes carry a serializable descriptor payload. Their live
`AUManagedUnit` instances reside in the runtime store.

## Build and checks

Requirements: macOS 15 or later and Xcode.

```sh
xcodebuild -project VisuSig.xcodeproj \
  -scheme VisuSig \
  -configuration Debug \
  -destination 'platform=macOS' \
  build CODE_SIGNING_ALLOWED=NO

xcrun swiftc \
  VisuSig/Payload/Payload.swift \
  VisuSig/Payload/AtlasStatementPayload.swift \
  Tests/PayloadModelChecks.swift \
  -o /tmp/VisuSigPayloadChecks
/tmp/VisuSigPayloadChecks

swift test --package-path /Volumes/GitHubDeveloper/Packages/VisualMesh
```

## Next seam to build

The useful integration is not more ATLAS text generation. It is an interchange
boundary from the table row to AtlasConcept:

1. expand the authoring record beyond `APPLY` without storing opaque ATLAS
   fragments as the semantic model;
2. lower the record to the same typed intent used by AtlasConcept's `TestIR`;
3. ask the Resource Manager for candidate capabilities and preserve rejection
   reasons;
4. project selected resources, bound ports, proposed routes, ownership, and
   release into inspectable VisuSig payloads;
5. add JSON/CSV import and export only after that record has a stable schema.

That path makes VisuSig an explanatory surface for TPS WorkShop rather than a
competing implementation of the ATLAS or TEDL standards.

## License

MIT — see [LICENSE](LICENSE).
