# Infection

This is a recreation of the classic infection gamemode, where one player gets randomly infected at the beginning of the round and has to infect all others. In order to win as a human, you need to survive for a given amount of time and then find and go to a designated extraction zone.

## Installation

You can find a pre-bundled version of this mod [here](https://community.veniceunleashed.net/t/infection-survive-and-extract-before-everyone-gets-infected/94). You will also need the [battlerecorder](https://github.com/OrfeasZ/battlerecorder) mod alongside it for this to work.

This mod currently only supports one map, so make sure you have this in your `MapList.txt`:

```
XP4_Quake TeamDeathMatchC0 2
```

## Configuration

You can configure various attributes of this mod by editing the `ext/Server/config.lua` file.

## Building

If you want to build this mod from source the only thing you'll need to do is package the UI. You can do this by running `vuicc.exe` and pointing it to the `ui` directory of this mod:

```
vuicc.exe C:\path\to\infection\ui ui.vuic`
```

Then place the produced `ui.vuic` file inside the mod folder and you're good to go.
