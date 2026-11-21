# sxHeat

A witness and police report system for **ESX or standalone** FiveM servers. When a player commits a crime, the NPCs who saw it call the police and describe the suspect: outfit, accessories, weapon, vehicle and part of the plate. The police get a report and a search zone drawn on the map that grows while the suspect hides and shrinks on them when an officer spots them. Changing outfit or vehicle makes the description outdated and the heat drop faster.

## Features

- **Crimes detected in game**: shots fired, homicide, assault, armed threat on a NPC, carjacking and vehicle theft, each with its own heat and cooldown. Other resources can report their own crimes with an export.
- **Witnesses**: NPCs with a clear line of sight call the police after a few seconds, with a phone animation. Killing them or aiming at them before the call ends stops the report, and they put their hands up. Shots are reported even without a witness when they are heard.
- **Description**: sex, outfit code, mask, hat, glasses, bag, weapon type, vehicle model and color. The plate is partial and depends on the distance of the witness, and the reports of several witnesses complete each other.
- **Heat**: from 0 to 100 per suspect, it rises with every crime and every sighting and cools down over time, three times faster when the description no longer matches the suspect.
- **Search zone**: a circle drawn on the minimap and the pause map with a custom scaleform overlay (`.gfx`). It grows while the suspect is not seen, shrinks on them when an officer gets close and the description still matches, and turns yellow when the description is outdated.
- **Police**: report cards with the description, a reports panel with every active case, GPS to the zone and case closing, and a card when aiming at a player who matches a report.
- **Suspect**: a card with the heat, whether the description still matches and whether the vehicle was reported.
- **sxHelpMenu** (optional): the report, suspect and match cards are drawn with [sxHelpMenu](https://github.com/0xS4cha/sxHelpMenu), native notifications are used without it.
- **Translations**: English and French.

## Dependencies

| Resource | Purpose |
| --- | --- |
| [es_extended](https://github.com/esx-framework/esx_core) | Optional. Police jobs and names |
| [sxHelpMenu](https://github.com/0xS4cha/sxHelpMenu) | Optional. Report, suspect and match cards |

Without ESX, the police is given with the `sxheat.police` ACE permission. The server should run OneSync, the sightings use the server side player positions.

## Installation

1. Clone the repository into your `resources` folder.
2. Build the interface.

   ```bash
   cd sxHeat/web
   npm install
   npm run build
   ```

3. Add the resource to your `server.cfg`.

   ```cfg
   ensure sxHelpMenu
   ensure sxHeat
   ```

   In standalone, give the police access with an ACE permission:

   ```cfg
   add_ace group.police sxheat.police allow
   ```

## Usage

| Command / key | Description |
| --- | --- |
| `/reports` / `F10` | Opens the reports panel, police only |

The key can be changed in *Settings > Key Bindings > FiveM*.

## Configuration

All values live in `shared/config.lua`.

| Key | Description |
| --- | --- |
| `Config.Police` | ESX jobs with their minimum grade, ACE permission, command and key |
| `Config.Crimes.<crime>` | `heat` added, `cooldown` in seconds, `audible` radius for crimes reported without a witness |
| `Config.Witness.radius` / `maxWitnesses` / `chance` | Who can witness a crime and how many call |
| `Config.Witness.callDelay` | Seconds the call takes, the window to intimidate the witness |
| `Config.Witness.plateDistance` | Distance under which the witness reads most of the plate, up to twice this distance they read 3 characters |
| `Config.Witness.intimidation` | Aiming at a witness stops the call |
| `Config.Heat.max` / `decayPerTick` / `staleMultiplier` / `sightingHeat` | Heat limits and cooling |
| `Config.Search.tick` | Seconds between two updates of the zones |
| `Config.Search.startRadius` / `minRadius` / `maxRadius` / `growPerTick` | Size of the search zone |
| `Config.Search.sightDistance` | Distance under which an officer spots a matching suspect |
| `Config.Search.points` | Points of the circle drawn on the map |
| `Config.HelpMenu` | sxHelpMenu cards (`report`, `suspect`, `match`), anchor and duration of the report card |

## How it works

The client of the suspect detects the crime, picks the witnesses around it and runs their calls, then sends what each witness saw to the server. The server keeps one case per suspect: it merges the descriptions (a plate seen partially by two witnesses gets more characters), places the zone around the crime with a random offset and sends the report to every officer. Every tick it compares the current outfit and plate of the suspect with the case, grows or shrinks the zone, cools the heat and sends the zones to the police, who draw them on the minimap overlay.

## Exports

### Server

| Export | Description |
| --- | --- |
| `ReportCrime(source, crime, coords?, description?, street?)` | Reports a crime from another resource, `crime` is a key of `Config.Crimes` |
| `GetHeat(source)` | Heat of a player, `0` when not wanted |
| `IsWanted(source)` | Whether the player has an active case |
| `ClearHeat(source)` | Closes the case of a player |
| `GetCases()` | Every active case |

### Client

| Export | Description |
| --- | --- |
| `CommitCrime(crime)` | Commits a crime for the local player, witnesses included |
| `IsPolice()` | Whether the local player gets the reports |

### Server events

| Event | Arguments |
| --- | --- |
| `sxHeat:reported` | `caseId`, `source`, `crime` |
| `sxHeat:cleared` | `caseId`, `source`, `reason` (`cooled`, `closed`, `dropped`, `export`) |

## License

MIT
