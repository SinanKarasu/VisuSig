# Hierarchical VisualMesh

The authoritative package is `/Volumes/GitHubDeveloper/Packages/VisualMesh`.
VisuSig is a consumer of that package, as is AtlasConcept's TPS WorkShop.

VisualMesh hierarchy is a definition/instance system with declared boundaries.
It is not implemented by copying a `Mesh` into the payload of another node.

The first working example comes from the `RESSIP9` pattern in WITS `tc3.sf`:

```text
U100:PACK:RESISTOR PACK:RESSIP9
  TERMINALS:1-10;
  ... R1 through R9 ...
  CONNECT: (PACK-1 R1-2 R2-2 ... R9-2)
           (PACK-2 R1-1) ... (PACK-10 R9-1);
```

`RESSIP9` is the reusable definition. `U100`, `U101`, and the other
designators are instances. `PACK-1` through `PACK-10` form the declared
interface. `CONNECT:` maps that boundary to the internal network.

## VisualMesh model

| VisualMesh | WITS | TEDL / AtlasConcept | IEEE 1671 / ATML |
| --- | --- | --- | --- |
| `MeshDefinition` | PACK type (`RESSIP9`) | device model | description document / hardware item description |
| `GraphSubgraphInstance` | designator (`U100`) | configured `DEVICE` | instance document or configuration item reference |
| `interfacePorts` | `TERMINALS` / `PACK-n` | device ports | `Interface` / `Ports` |
| `GraphBoundaryBinding` | `CONNECT:` | model connections | `NetworkList` / network nodes |
| parent `Mesh` edges | board wiring | `.cf` and adapter wiring | test configuration and hardware networks |

IEEE 1671.5 makes the definition/instance distinction particularly explicit:
`TestAdapterDescription` documents a family of adapters, while
`TestAdapterInstance` documents one particular serial-numbered adapter and
references its description document. The ATML hardware common model gives a
description an interface, components, and a network list. VisualMesh uses the
same division without making its in-memory vocabulary depend on XML names.

## Invariants

1. A definition owns one internal mesh and one declared interface.
2. An instance references a definition by stable `MeshDefinitionID`.
3. Every instance receives distinct node and port identities.
4. An instance port retains a mapping to the corresponding definition port.
5. Every definition boundary port maps to one or more internal endpoints.
6. Definitions may contain instances of definitions already in the library.
7. Recursive definition cycles and missing child definitions are rejected.
8. Parent edges connect instance ports; they do not reach into an internal
   mesh by bypassing the declared boundary.

The plural endpoint rule is important. `PACK-1` maps to nine internal resistor
terminals, so a one-boundary-port-to-one-internal-port model would already be
too weak for the recovered corpus.

## Projection, not duplication

Collapsed and expanded boxes are two projections of the same objects:

```text
collapsed                         expanded

+------------------+             +-----------------------------+
| U100 : RESSIP9    |             | U100 : RESSIP9              |
| 1 2 3 4 5 ... 10 |             | boundary 1 ... 10           |
+------------------+             | shared RESSIP9 definition:  |
                                 | R1 R2 R3 ... R9              |
                                 | PACK-1 -> R1-2 ... R9-2     |
                                 +-----------------------------+
```

Expansion does not clone R1 through R9 into U100. It resolves U100's
definition reference and renders the shared definition in the instance's
context. U101 resolves the same definition while preserving its own identity,
ports, selection state, and parent wiring.

## Current first cut

The Hierarchy workspace in VisuSig provides:

- a reusable definition library;
- the recovered RESSIP9 definition with its ten-port boundary;
- independently identified U100 and U101 instances;
- expand/collapse of the shared internal graph;
- assembly edges between instance boundary ports;
- creation of additional RESSIP9 instances;
- validation tests for boundaries, instances, composition, and physical
  bidirectional terminals.

Persistence and a general definition editor are deliberately next steps. The
types carrying definition references and boundary maps are already `Codable`,
but the whole generic mesh does not yet claim a stable interchange format.

## Software instruments later

Software instruments are orthogonal to hierarchy. They observe an edge or a
resolved boundary net; they are not children of a PACK merely because the PACK
is expanded on screen. The existing `SignalEdgePayload` remains the intended
attachment point. A later instrument layer can choose whether an attachment
belongs to a definition edge (shared instrumentation policy) or to an instance
edge (one deployed observation) without changing containment.

## Source material used

- `/Volumes/GitHubDeveloper/Projects/Wits/Wits/GNU_WITS/wits/sf/tc3.sf`
- IEEE 1671.5-2015 `TestAdapterDescription.xsd` and
  `TestAdapterInstance.xsd`
- IEEE 1671 hardware-common `Interface`, `Components`, and `NetworkList`
  schema structures under the local ATLAS document collection
- AtlasConcept's existing TEDL model/configuration split
