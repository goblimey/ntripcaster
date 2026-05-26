# NtripCaster configuration reference

This directory holds the two configuration files required to run NtripCaster. Copy the `.dist` templates to active config files before editing:

```bash
cp ntripcaster.conf.dist ntripcaster.conf
cp sourcetable.dat.dist sourcetable.dat
```

| File | Purpose |
|------|---------|
| `ntripcaster.conf` | Server settings, limits, logging, and access control — **parsed and enforced** by the caster |
| `sourcetable.dat` | NTRIP sourcetable catalog — **sent verbatim** to clients; not parsed field-by-field |

Both files must stay in sync for mountpoint names: every stream you operate should appear as an `STR` record in `sourcetable.dat` and (when access control applies) as a mountpoint line in `ntripcaster.conf`.

---

## File locations

The caster searches for configuration files in this order:

**`ntripcaster.conf`** — resolved via `etcdir` (relative to the working directory at startup, typically `../conf/` or `./conf/`):

1. `{etcdir}/ntripcaster.conf`
2. `./conf/ntripcaster.conf`
3. `../conf/ntripcaster.conf`

**`sourcetable.dat`** — hardcoded path relative to the process working directory:

```
../conf/sourcetable.dat
```

The sourcetable path does **not** follow `etcdir`. Run the caster from a directory where `../conf/sourcetable.dat` resolves correctly (usually the `ntripcaster/` build directory).

**Log files** — resolved via `logdir`:

1. `{logdir}/{logfile}`
2. `./logs/{logfile}`
3. `../logs/{logfile}`

---

## ntripcaster.conf

### Syntax rules

- One setting per line: `keyword value`
- Lines starting with `#` or a space are ignored
- Blank lines are ignored
- Lines starting with `/` are mountpoint access-control entries (see below)
- Unknown keywords are logged as warnings and ignored
- Maximum line length: **1000 characters** (`BUFSIZE`); longer lines may be truncated or rejected
- Send **SIGHUP** to reload settings and reopen log files without a full restart (see [Reload behavior](#reload-behavior))

### Server metadata

These fields are stored at startup but are **not used** by any runtime logic in this codebase. They exist for documentation and operator reference only.

| Keyword | Description | Default | Constraints |
|---------|-------------|---------|-------------|
| `location` | Geographic or organisational location of the caster | `BKG Geodetic Department` | Free text |
| `rp_email` | Email of the responsible person | `euref-ip@bkg.bund.de` | Free text |
| `server_url` | Public URL for this caster | `http://igs.ifag.de/` | Free text |

### Connection limits

| Keyword | Description | Default | Constraints |
|---------|-------------|---------|-------------|
| `max_clients` | Maximum simultaneous rover (client) connections | `100` | Positive integer. Enforced at login; excess clients are rejected |
| `max_clients_per_source` | Maximum clients per mountpoint / source | `100` | Positive integer. Enforced per active encoder stream |
| `max_sources` | Maximum simultaneous encoder (base station) connections | `40` | Positive integer. Enforced when an encoder connects |

On Unix, the caster also tries to raise the process file-descriptor limit to `max_clients + max_sources + 20`.

### Encoder authentication

| Keyword | Description | Default | Constraints |
|---------|-------------|---------|-------------|
| `encoder_password` | Shared password for all base stations connecting as sources | `sesam01` | Free text. Compared in plain text |

Base stations (encoders) must connect using the NTRIP `SOURCE` command:

```
SOURCE <encoder_password> <mountpoint>
Source-Agent: NTRIP ...
```

Additional encoder requirements enforced by the caster:

- `Source-Agent` header must start with `ntrip` (case-insensitive)
- Mountpoint must not already be in use by another connected encoder
- Mountpoint name is normalised to start with `/` internally
- Encoder **user names are not validated** — only the shared password matters

### Network binding

| Keyword | Description | Default | Constraints |
|---------|-------------|---------|-------------|
| `server_name` | Hostname identity for this caster | `localhost` | See [How `server_name` works](#how-server_name-works) below |
| `port` | TCP port to listen on | `8000` | Integer. Up to **5** `port` lines allowed (`MAXLISTEN`); each opens an additional listening socket |

The caster listens on **all network interfaces** (`INADDR_ANY`) on each configured port. It does not bind to the address returned by resolving `server_name`.

**Note:** The `Host:` header in client HTTP requests is **ignored** when matching mountpoints (since v0.1.4), so the caster can run behind a reverse proxy.

#### How `server_name` works

`server_name` is **not** the address that rovers or base stations must dial. It is an internal hostname the caster resolves once at startup and uses as a default label when parsing HTTP requests. What clients and encoders actually need is a **routable IP address or hostname plus port** that reaches this machine — which can be completely different from `server_name`.

**Startup resolution** (in `setup_listeners()`):

1. If `server_name` is `dynamic`, it is replaced with the local outbound IP address (via a UDP socket trick on Linux; on Windows this falls back to the literal string `dynamic`).
2. Otherwise the caster calls `forward()`, which uses the OS resolver (`gethostbyname` / `gethostbyname_r`) to look up `server_name`.
3. If lookup succeeds, both the configured name and the resolved dotted-decimal IP are stored in an internal `my_hostnames` list.
4. If lookup fails, a **warning** is logged (`Resolving the server name [...] does not work!`). The server **still starts** and accepts connections; only the internal hostname list is left empty.

**What resolver is used?** Whatever the **caster machine's OS** is configured to use: `/etc/hosts`, a local DNS server, mDNS/Avahi, corporate DNS, or public DNS. There is **no requirement for public internet DNS** — a hostname that resolves only on your LAN (for example `ntrip.local` via a Pi-hole or router DNS) works fine, as long as the caster host itself can resolve it at startup.

**Does `server_name` need to match what rovers and base stations use to connect?**

**No.** In this codebase, stream routing depends only on the **mountpoint path** in the HTTP request (for example `GET /BUCU0 HTTP/1.0`), not on the hostname the client connected to or sent in a `Host:` header. The old hostname-matching logic (`hostname_local()`) exists in the source but is **commented out** in `find_mount_with_req()`.

Typical deployment patterns:

- **Local network:** set `server_name` to a LAN hostname (for example `ntrip-caster.home.arpa`) that resolves via your local DNS or `/etc/hosts` on the caster machine. Rovers can use the same hostname, a different alias, or the raw IP — all work.
- **No DNS at all:** use `server_name dynamic` to skip DNS lookup, or use `localhost` if the resolver handles it. Rovers/base stations still connect via IP address.
- **Public internet:** set `server_name` to your public hostname. Rovers use that same hostname or any CNAME/IP that routes to the caster. `server_name` matching is still not required for connections to succeed.

**Practical recommendation:** Set `server_name` to the canonical hostname **as resolved by the caster machine itself** (local or public DNS). This satisfies BKG's original guidance and avoids startup warnings, but it does not restrict how clients connect. Ensure rovers and base stations are configured with whatever address actually reaches the host — IP, LAN name, or public FQDN.

### Logging

| Keyword | Description | Default | Constraints |
|---------|-------------|---------|-------------|
| `logdir` | Directory for log files | `.` (relative to run path) | Must exist and be readable. Use an absolute path in production |
| `logfile` | Log file name | `ntripcaster.log` | Written inside `logdir`. Appended on open |

### Mountpoint access control

Mountpoint lines define which rovers require authentication. They are **not** keyword/value pairs — each line starts with `/`.

**Syntax:**

```
/<MOUNTPOINT>:<USER1>:<PASSWORD1>,<USER2>:<PASSWORD2>,...
```

| Part | Description | Constraints |
|------|-------------|-------------|
| `/<MOUNTPOINT>` | Mountpoint path | Must start with `/`. Case-sensitive. Must match the encoder mountpoint and the STR record in `sourcetable.dat` (without the leading `/` in the sourcetable) |
| `<USER>:<PASSWORD>` | Credentials for Basic auth | One or more pairs, comma-separated. User names and passwords are plain text |

**Examples:**

```
/BUCU0:user1:password1,user2:password2    # two users on a protected mountpoint
/uk_leatherhead:rover:secret              # single user
```

**Public mountpoints** — omit the mountpoint from `ntripcaster.conf` entirely. Any client with a valid NTRIP User-Agent can connect without credentials.

**Important:** A line like `/PADO0` with no colon is **invalid** and is silently ignored by the parser. To declare a public mountpoint, do not add a config line for it.

**Authentication behavior:**

- Only **HTTP Basic** authentication is implemented (not Digest)
- If a mountpoint appears in the config with one or more users, clients must supply matching credentials
- If a mountpoint is **not** listed, authentication is skipped for that mountpoint
- Rover clients must send `User-Agent` starting with `ntrip` (case-insensitive) to receive a stream
- User names are logged on connect/disconnect (since v0.1.3)

Duplicate mountpoint lines in the config: the **last** entry wins (a warning is logged).

---

## sourcetable.dat

### How the caster uses it

The caster does **not** parse individual sourcetable fields. It reads the file and sends the contents verbatim to NTRIP clients when:

- A client requests the root path (`/` or empty mountpoint), or
- A client requests a mountpoint that does not exist (fallback: client receives the sourcetable instead of a stream)

The sourcetable is a **catalog for clients** (rovers, BNC, etc.). Actual stream availability depends on a connected encoder publishing on that mountpoint.

What the caster enforces separately in `ntripcaster.conf`:

- Which mountpoints require authentication
- User names and passwords per mountpoint
- The encoder password for base stations

| sourcetable.dat | ntripcaster.conf |
|-----------------|------------------|
| `STR;BUCU0;...` | `/BUCU0:user1:password1,...` |

The caster does not validate that these names match automatically.

### File format

- One record per line
- Fields separated by semicolons (`;`)
- Three record types: `CAS`, `NET`, and `STR`
- If a field value contains a semicolon, quote it per the NTRIP spec: `";"`
- The last field in every record is always **misc** (miscellaneous information)

The example `sourcetable.dat.dist` contains:

- 2 × `CAS` — other NTRIP casters (registry entries)
- 2 × `NET` — GNSS networks
- 1 × `STR` — an example data stream (mountpoint)

### CAS records (caster description)

Describes an NTRIP caster. The example file uses the **10-field** format (field 10 = misc URL). Newer NTRIP documentation also defines optional fallback host/port fields before misc.

**Example:**

```
CAS;www.euref-ip.net;2101;EUREF-IP;BKG;0;DEU;50.12;8.69;http://www.euref-ip.net/home
```

| # | Field | Description | Constraints |
|---|-------|-------------|-------------|
| 1 | type | Record type | Must be `CAS` |
| 2 | host | Caster hostname or IP | Hostname or IP, max 128 characters |
| 3 | port | Caster TCP port | Integer (e.g. `2101`) |
| 4 | identifier | Caster or provider name | Free text |
| 5 | operator | Operating institution | Free text (e.g. `BKG`) |
| 6 | nmea | Caster accepts client NMEA GGA for position-based mount selection | `0` = no, `1` = yes |
| 7 | country | ISO 3166-1 alpha-3 country code | Exactly 3 characters (e.g. `DEU`) |
| 8 | latitude | Approximate caster latitude (°N) | Decimal degrees; spec recommends 2 decimal places |
| 9 | longitude | Approximate caster longitude (°E) | Decimal degrees; spec recommends 2 decimal places |
| 10 | misc | Miscellaneous information (often a URL) | Free text; use `none` if empty |

**Extended format (newer NTRIP spec):** fields 10–11 may be fallback host and fallback port (`0.0.0.0` / `0` = no fallback), with misc as the final field.

The CAS lines in the example file describe **other** NTRIP casters (EUREF-IP, rtcm-ntrip.org). BKG recommends keeping at least the rtcm-ntrip.org line so clients can discover the global registry.

### NET records (network description)

Describes a network of GNSS reference stations. Purely informational for clients browsing the sourcetable.

**Example:**

```
NET;EUREF;EUREF;B;N;http://www.epncb.oma.be/euref_IP;http://www.epncb.oma.be/euref_IP;http://igs.ifag.de/index_ntrip_reg.htm;none
```

| # | Field | Description | Constraints |
|---|-------|-------------|-------------|
| 1 | type | Record type | Must be `NET` |
| 2 | identifier | Network name | Free text; referenced by STR field 8 (e.g. `EUREF`, `IGS`) |
| 3 | operator | Operating institution | Free text |
| 4 | authentication | Auth type for streams in this network | `N` (none), `B` (basic), `D` (digest), or comma-separated list |
| 5 | fee | Whether streams in this network charge a fee | `Y` or `N` |
| 6 | web-net | URL for network information | URL or `none` |
| 7 | web-str | URL for stream information | URL or `none` |
| 8 | web-reg | Registration URL or email | URL, email, or `none` |
| 9 | misc | Miscellaneous information | Free text; use `none` if empty |

### STR records (stream / mountpoint description)

Describes a data stream (mountpoint). Add one STR line for **each mountpoint** you operate.

**Example:**

```
STR;BUCU0;Bucharest;RTCM 2.0;1(1),3(60),16(60);0;GPS;EUREF;ROU;44.46;26.12;0;0;Ashtech Z-XII3;none;B;N;520;TU Bucharest
```

| # | Field | Description | Constraints |
|---|-------|-------------|-------------|
| 1 | type | Record type | Must be `STR` |
| 2 | mountpoint | Stream name clients connect to | Max 100 chars: `A–Z`, `a–z`, `0–9`, `-`, `_`, `.` only. No leading `/`. Must match `ntripcaster.conf` and the encoder mountpoint. Case-sensitive |
| 3 | identifier | Human-readable label (often nearest city) | Free text |
| 4 | format | Data format | e.g. `RTCM 2.0`, `RTCM 3.0`, `RAW`, `CMR`, `NMEA`, `BINEX` |
| 5 | format-details | Message types and update rates | Comma-separated; rates in parentheses in seconds, e.g. `1(1),3(60),16(60)` |
| 6 | carrier | Carrier-phase content | `0` = none, `1` = L1, `2` = L1+L2 |
| 7 | nav-system | GNSS system(s) | e.g. `GPS`, `GPS+GLO`; multiple joined with `+` |
| 8 | network | Network this stream belongs to | Should match a NET identifier (field 2), e.g. `EUREF` |
| 9 | country | ISO 3166-1 alpha-3 country code | 3 characters (e.g. `ROU`, `GBR`) |
| 10 | latitude | Station latitude (°N) | Decimal degrees; use approximate position if field 12 = `1` |
| 11 | longitude | Station longitude (°E) | Decimal degrees; `0.00` acceptable if unknown |
| 12 | nmea | Client must send NMEA GGA before streaming | `0` = not required, `1` = required |
| 13 | solution | Single-base vs network solution | `0` = single base, `1` = network (VRS) |
| 14 | generator | Hardware/software producing the stream | Free text (e.g. receiver model) |
| 15 | compression | Compression algorithm | Usually `none` |
| 16 | authentication | Advertised auth for this stream | `N`, `B`, `D`, or comma-separated. **Informational only** — actual auth is in `ntripcaster.conf`. This caster implements Basic (`B`) only |
| 17 | fee | Whether access is charged | `Y` or `N` |
| 18 | bitrate | Approximate data rate | Integer, bits per second (e.g. `520`) |
| 19 | misc | Miscellaneous information | Free text; institution, notes, or `none` |

#### Common format values (field 4)

| Format | Typical use |
|--------|-------------|
| `RTCM 2.0`, `RTCM 2.1`, `RTCM 2.2`, `RTCM 2.3` | Legacy RTCM v2 streams |
| `RTCM 3.0`, `RTCM 3.1`, `RTCM 3.2`, `RTCM 3.3` | Modern RTCM v3 streams |
| `RAW` | Raw receiver data |
| `CMR`, `CMR+` | Trimble compact formats |
| `NMEA` | NMEA 0183 sentences |

See the [STR wiki page](https://software.rtcm-ntrip.org/wiki/STR) for a full list of format and format-details combinations.

---

## Complete setup example

### sourcetable.dat

```
CAS;rtcm-ntrip.org;2101;NtripInfoCaster;BKG;0;DEU;50.12;8.69;http://www.rtcm-ntrip.org/home
STR;uk_leatherhead;Leatherhead;RTCM 3.0;;;;;GBR;51.29;-0.32;0;0;sNTRIP;none;N;N;0;;
```

### ntripcaster.conf (relevant excerpts)

```
location Leatherhead, UK
rp_email admin@example.com
server_url http://caster.example.com

max_clients 100
max_clients_per_source 100
max_sources 40

encoder_password choose-a-strong-password

server_name caster.example.com
port 2101

logdir /var/log/ntripcaster
logfile ntripcaster.log

/uk_leatherhead:rover:secret
```

For a **public** mountpoint, omit the last line and set STR field 16 to `N`.

An encoder must connect and publish on `/uk_leatherhead` — neither config file alone creates the stream.

---

## Operational checklist

1. Copy both `.dist` templates to their active filenames.
2. Set `server_name` to a hostname the caster machine can resolve (local DNS, `/etc/hosts`, or public DNS — see [How `server_name` works](#how-server_name-works)).
3. Set `encoder_password` to a strong secret; configure your base station with the same value.
4. Add one `STR` line per mountpoint in `sourcetable.dat`.
5. Add matching access-control lines in `ntripcaster.conf` for protected mountpoints (or omit for public access).
6. Keep the rtcm-ntrip.org `CAS` line unless you have a reason to remove it.
7. Set STR field 16 (`authentication`) to match reality: `N` for public, `B` when credentials are required.
8. Ensure mountpoint names match exactly across encoder, `ntripcaster.conf`, and `sourcetable.dat` (case-sensitive).
9. Run the caster from a working directory where `../conf/` resolves to this directory.

---

## Reload behavior

Sending **SIGHUP** to the caster process:

- Re-parses `ntripcaster.conf` (limits, passwords, metadata, ports, log settings)
- Reopens log files
- Re-adds mountpoint access-control entries from the config

**Limitations:**

- Mountpoint entries **removed** from the config are **not** cleared on SIGHUP — a full restart is required to drop old access-control entries
- `sourcetable.dat` is read fresh on each client request; no reload signal is needed for sourcetable changes
- There is no config-file keyword validation beyond type parsing (integers via `atoi`, strings stored as-is)

---

## Known limitations

| Area | Limitation |
|------|------------|
| Authentication | HTTP Basic only; Digest (`D`) is not implemented despite being valid in sourcetable metadata |
| Encoder auth | Single shared password for all base stations; no per-encoder credentials |
| Sourcetable path | Hardcoded to `../conf/sourcetable.dat`; not configurable via `ntripcaster.conf` |
| Metadata fields | `location`, `rp_email`, and `server_url` are stored but unused at runtime |
| Config keywords | Only the keywords listed in this document are recognised; all others are ignored |
| Sourcetable enforcement | Stream format, coordinates, bitrate, etc. are not validated — they are client-facing metadata only |
| NMEA / VRS | Sourcetable `nmea` and `solution` fields are informational; no NMEA-based mount selection is implemented in this codebase |

---

## External references

### NTRIP sourcetable specification

- [NTRIP Sourcetable overview](https://software.rtcm-ntrip.org/wiki/Sourcetable)
- [CAS record format](https://software.rtcm-ntrip.org/wiki/CAS)
- [NET record format](https://software.rtcm-ntrip.org/wiki/NET)
- [STR record format](https://software.rtcm-ntrip.org/wiki/STR) — data formats, carrier codes, navigation systems
- [BKG Ntrip Documentation (PDF)](https://igs.bkg.bund.de/root_ftp/NTRIP/documentation/NtripDocumentation.pdf) — official protocol specification (Tables 1–3, Appendix A)

### Other

- [ISO 3166-1 country codes](https://www.iban.com/country-codes) — for 3-letter country code fields in sourcetable records
