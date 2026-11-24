# VisuSig project packages

## Decision

VisuSig documents use the .visusig extension and appear as packages in Finder.
Each package has a schema version and document kind. Version 1 implements the
musicSession kind for the Audio Units workspace's music graph.

ATLAS, Payload, Hierarchy, MIDI, and DAW panels remain in the application.
Their independent workspaces are outside the version 1 music document.
Additional document kinds can be introduced with their own schemas.

## Version 1 layout

```text
Experiment.visusig/
    Manifest.json
    Session.json
    Media/
        Audio/
            <unique filename>.<original extension>
    PluginStates/
        <node UUID>.plist
```

Media and PluginStates folders are created when needed.

Manifest.json contains schemaVersion, documentKind, and an asset inventory.
Each asset records its stable UUID, original display name, package-relative
path, and SHA-256 digest.

Session.json contains the music graph's node records and connections, node and
payload identities, ports and their audio/MIDI signal kinds, 2D positions,
mixer channel settings, master volume, bypass settings, MIDI source selections,
and the active audio asset identity. Runtime objects and absolute source media
paths are excluded.

The application uses VisualMesh graph objects. Document records describe the
versioned on-disk representation and contain no separate graph editing logic.

Connection identities survive save/open cycles through a mapping from the
current VisualMesh edge identity to its stored document identity.

## Automatic asset collection

Loading audio in the Audio Units workspace immediately copies it into an owned
working package. Playback and library preview use the collected copy.
An unsaved session therefore continues working after the original is moved
or deleted.

Saving writes the collected assets into the destination .visusig package.
Save As produces another self-contained package. Opening copies the package
into an independent working area before restoring the session.

Assets are identified by bytes, with streamed SHA-256 hashing. Importing the
same bytes again reuses the collected asset. Files with identical basenames
and different contents receive distinct asset paths. The original display name
is preserved in the manifest.

Collection follows a user-selected source symlink to copy the actual file.
Stored media and state references must stay inside the package and cannot
traverse symlinks. The existing package root is canonicalized once, and new
resource paths are constructed from it. This allows system directory aliases
such as /var and /private/var without rejecting files that have yet to be
created. Opening through a root alias copies the resolved directory into owned
storage. Opening verifies collected media against its saved digest.

Every successfully collected audio asset remains in the project, including
previously loaded files, so changing the active file does not discard media.

## Plug-in restoration

A plug-in record stores the Audio Component type, subtype, manufacturer code,
and component version. Opaque state comes from fullStateForDocument, falling
back to fullState, and is written as a binary property list. Bypass is also
saved in the node payload and reapplied after state restoration.

Opening restores installed plug-ins asynchronously. Missing or unloadable
plug-ins remain as nodes with their ports, connections, identity, and opaque
state retained. A visible warning lists the unresolved plug-ins. Saving again
preserves their state files. Routes through unavailable plug-ins cannot sound
until a usable runtime is available.

Plug-in binaries and vendor-managed sample libraries require separate
installation. A plug-in's opaque state may refer to vendor-managed resources;
copying media imported through VisuSig does not make every third-party
instrument self-contained across platforms.

## Saving and opening

Use Open Project, Save Project, or Save As in the Audio Units workspace, or
the corresponding music project commands in the File menu. Command-O opens,
Command-S saves, and Command-Shift-S saves under another name.
Opening a .visusig package through Finder routes it to the music workspace.

Saving first creates a complete staging package beside the destination, then
uses an atomic replacement. A failed save preserves the existing destination.
The current graph is replaced only after the incoming package has been decoded,
validated, and its available plug-ins restored. Opening starts with file
playback stopped. Connected instruments become available when the graph is activated.

Before replacing a populated or previously saved session, the UI offers to
save the current session, cancel, or open without saving. Saving is explicit;
automatic saving and application quit/window-close save prompts are future work.
Temporary working packages are implementation storage and are not a substitute
for saving a project.

Unsupported schema versions and document kinds are rejected. Invalid internal
paths, duplicate graph identities, invalid ports, invalid mixer settings, and
feedback cycles are rejected before activating the incoming graph.

## Compatibility direction

Logic compatibility will be an import/export boundary over the music session
model. Native packages retain a distinct versioned schema.

Future session features include tracks and regions, tempo and meter maps,
automation, multiple simultaneous audio sources, MIDI-file assets, recordings,
rendered audio, generator settings and seeds, experiment variants, and saved UI
state beyond node positions. Those features should use package-relative
resource identities and collect their media automatically.

The standalone MIDI panel and the DAW layout prototype are not yet serialized
by the music project commands. They need explicit integration with the shared
music session before their state can be included.

## Checks

The main Debug app build verifies integration and the document type declaration.

Run the persistence checks from the repository root:

```sh
Tests/run-music-project-checks.sh
```

The script builds an isolated copy with a test entry point and runs it without
changing the app's regular entry point. Checks cover media collection,
deduplication, package movement, source deletion, atomic overwrite, graph and
mixer restoration, stable connection identities, path validation, future schema
rejection, Apple Audio Unit parameter/bypass restoration, and missing plug-in
state preservation.


The user confirmed a physical-iPad round trip through iCloud Downloads:
Save Project succeeded, and opening the saved package with Open Without Saving
restored the session. This confirms that save/open workflow on the tested device.
