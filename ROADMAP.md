# Roadmap

What is likely to happen to this app next, what is being considered, and what is
deliberately not planned.

The guiding constraint is that this app does **one job**: centre and resize the active
window from a keyboard shortcut. Every item below is weighed against that. A feature that
would be genuinely useful in a different program is still a "no" here if it turns this one
into a window manager.

Nothing here is a commitment or a schedule.

## Next up

**Correct the executable's version metadata.** Right-click the `.exe`, open Properties →
Details, and it currently reports version **2.0.26** with no product or company name. That
is AutoHotkey's version, not this app's — a compiled AutoHotkey program inherits the
interpreter's resource block unless the script overrides it. It is cosmetic for anyone who
downloads from the releases page, but software directories that scrape binary metadata read
it, and they are how most people find this app.

**Verify the "a newer version is available" path.** The tray menu's *Check for updates* has
an untested branch: until 2.1.0 shipped there was no newer release for it to find, so the
upgrade-available case has never actually run. If it is broken, nobody on an older version
would ever be told there is a new one — and they would have no way to notice. Worth proving
before adding anything else.

**Add and remove size presets.** Today there are exactly three, and the number is fixed.
Some people want two, some want five. The cycling logic already handles any number — the
limit is the settings window and the settings file. Removing a preset has to clear the
orphaned entry from `settings.ini`, or the deleted row reappears the next time the app
starts.

## Under consideration

**Showing which preset is active.** The resize shortcut cycles silently, so with three
presets you learn the order by feel. With five or six that stops working. This only becomes
worth solving if the previous item ships, and any answer costs either a visible element on
every keypress or a new menu.

**Naming presets.** Related to the above, and only meaningful somewhere a name can be seen.
The settings window's `Preset 1` / `Preset 2` labels are the obvious place, though a name
that appears only while you are editing is a modest return for a new field in the settings
file.

**A higher-resolution screenshot** in the README and on the landing page. The current image
is displayed at its exact pixel size, so it looks soft on high-DPI displays, which is most
laptops now.

## Not planned

**Dark mode.** Not refused on principle — measured and set aside. Windows will theme the
title bar and the buttons of a window like this one, but **not** its text fields. The
settings window has eight of them, so a naive dark mode produces eight glaring white boxes,
which is worse than the light theme it replaced. A correct implementation needs custom
control painting. The groundwork exists (`src/gui/Theme.ahk` is written so a second palette
is a swap rather than a rewrite), but the painting route is unmeasured and the honest
estimate is "a real project", not "a quick toggle".

**Capturing Windows-key shortcuts in the hotkey field.** The field cannot record
combinations that include the Windows key, because the system claims those before an
ordinary application sees them. Reading them anyway requires a low-level keyboard hook —
an always-on system-wide hook — in a program that already registers global hotkeys. That is
a meaningful increase in what this app does to your machine, for one input field.
Windows-key shortcuts still work: set them by editing `settings.ini` directly, as described
in the README, and the app preserves them when you save from the settings window.

**Anything that makes this a window manager.** Snapping, tiling, layouts, per-application
rules, multi-window arrangement, saving and restoring window positions. These are good
features and this is the wrong program for them; several are already in Microsoft PowerToys.

## Help wanted

One code path cannot be exercised on the machine this is developed on. Its arithmetic is
covered by unit tests, but it has never been confirmed against real hardware:

- **Secondary monitors.** Version 2.0.0 fixed sizing and centring across monitors of
  different resolutions — percentages were computed from one monitor while the window was
  centred on another. That fix has never run on an actual multi-monitor setup.

If you run that and something looks wrong, an issue with a screenshot is genuinely useful.
