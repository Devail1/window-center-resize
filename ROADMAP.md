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

**Named positions.** Today the app knows one position — the middle — and three sizes. The
next version knows a list: each entry has a name, a hotkey, and a rectangle given as
percentages of the work area. You set the rectangle by dragging a window inside a picture of
your screen, in the settings window, instead of typing four numbers.

This replaces the three preset rows rather than joining them, and it absorbs two items that
used to sit here on their own — adding and removing presets, and naming them. Both were the
same problem: the settings file holds a fixed three of everything, and the settings window
has a row per thing. A list solves it once.

Three constraints it is committed to:

- **The resize shortcut survives unchanged, in its own section.** It still sizes and centres.
  Cycling sizes is a different gesture from jumping to a named position — "a bit bigger"
  versus "over there" — and the two do not need to compose, because a position already stores
  its own width and height: "left half, but bigger" is a second position, not a second
  keypress. Nobody's existing shortcut changes behaviour.
- **The screen picture is drawn at the current monitor's real aspect ratio, portrait
  included.** A 16:9 preview shown to someone on a vertical monitor is a preview that lies.
  Because a 9:16 screen drawn at the dialog's width would be some 750 px tall, the picture
  letterboxes into a fixed height and gives up width instead — the window never changes size.
- **It replaces the preset rows. It never joins them.** This is the line, and it is not
  rhetorical: see *Not planned*, below.

## Under consideration

**Showing which size is active.** The resize shortcut cycles silently, so with three sizes
you learn the order by feel. With five or six that stops working. Named positions do not fix
this — they are a different gesture, each with its own key — so it stays a live question for
the sizes alone, and any answer still costs either a visible element on every keypress or a
new menu.

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

**Anything that makes this a window manager.** Tiling, per-application rules, multi-window
arrangement, saving and restoring a whole desktop. These are good features and this is the
wrong program for them; several are already in Microsoft PowerToys.

The sharp edge of that line is **drag-to-zone** — drag a window, an overlay appears, drop it
into a region. It is not ruled out for being hard. It is buildable in a couple of hundred
lines of AutoHotkey, and it would cost the thing that makes this app worth keeping: the app
would have to subscribe to every window move on the system, permanently, to know when to show
the overlay. Today it is asleep between keypresses and that is the pitch. *Named positions*,
above, deliberately keeps the dragging inside a settings screen you open twice a year, where
it costs nothing at rest.

The other half of the same line is surface. A previous rebuild grew a screen preview with
drag-resize, then tabs behind it, reached 81 files, and shipped to nobody. The widget was not
the mistake; adding it on top of what was already there was. Any editor that arrives as an
*extra* screen rather than *the* screen has crossed back over.

## Help wanted

One code path cannot be exercised on the machine this is developed on. Its arithmetic is
covered by unit tests, but it has never been confirmed against real hardware:

- **Secondary monitors.** Version 2.0.0 fixed sizing and centring across monitors of
  different resolutions — percentages were computed from one monitor while the window was
  centred on another. That fix has never run on an actual multi-monitor setup.

If you run that and something looks wrong, an issue with a screenshot is genuinely useful.
