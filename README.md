# OGN Simulator

The main purpose of this tool is to simulate an APRS server that generates Open Glider Network packets.
Generated traffic could composed of:
- APRS packets with simulated object data,
- APRS packets replayed from OGN log files.

## Purpose
Main purpose of the tool is GAT Core server performance testing, but it could be used for testing selected OGN components.

## Compiling
Erlang and Elixir must be installed, in ogn_sim repository following commands should be executed:

```
$ mix deps.get
$ mix escript.build
```
Compiled binary name is ogn_sim.

## Options

CLI options:

```
$ ./ogn_sim -h
ogn_sim args:
--help, -h: print help,
--port, -p: APRS server listen TCP port, default: 10152,
--name, -n: APRS server name, default: OGNSIM,
--objs, -o: number of simulated OGN objects, default: 0,
--file, -f: simulate traffic from selected APRS log file.
```

